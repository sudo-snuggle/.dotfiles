#!/usr/bin/env python3
"""
Stage 2: Enrich ~/Music/<user>/<Artist>/<Album>/ folders with:
  - Single primary artist tag, clean genres, and release year
  - Animated HLS/video cover via artwork.m8tec.top (with static fallback), 600..1024px WebP
  - Word/syllable-synced lyrics saved as .lrc next to tracks + junk lyric cleanup
  - 'script .txt' marker file per processed album folder

Organized into modular sections so individual pieces can be replaced cleanly later.
"""

from __future__ import annotations

import io
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any
from urllib.parse import urljoin

import requests
from mutagen import File as MutagenFile
from mutagen.flac import FLAC
from mutagen.mp3 import MP3
from mutagen.mp4 import MP4
from mutagen.oggopus import OggOpus
from PIL import Image

try:
    import syncedlyrics  # type: ignore
except ImportError:
    syncedlyrics = None


# ==============================================================================
# SECTION 1: CONFIGURATION & CREDENTIALS
# ==============================================================================

LASTFM_API_KEY = "956a19b94112e184f4dca4a0dd015980"
LASTFM_API_SECRET = "6bfc4969f1942cb838e45c68feef40ca"

SCRIPT_DIR = Path(__file__).resolve().parent  # ~/.dotfiles/Music
HOME = Path.home()
MUSIC_ROOT = HOME / "Music"
DOWNLOADS_DIR = HOME / "Downloads"

ARTWORK_API_BASE = "https://artwork.m8tec.top"
ARTWORK_SEARCH_URL = f"{ARTWORK_API_BASE}/api/v1/artwork/search"
DONE_MARKER_NAME = "script .txt"

AUDIO_EXTS = {".opus", ".m4a", ".mp3", ".flac", ".ogg", ".wav", ".aac"}
LYRIC_EXTS = {".lrc", ".elrc", ".ttml"}

USER_AGENT = "HermesMusicOrganizer/4.0 (local-homelab@example.invalid)"
MB_HEADERS = {"User-Agent": USER_AGENT, "Accept": "application/json"}
M8TEC_HEADERS = {
    "User-Agent": USER_AGENT,
    "Accept": "application/json, text/plain, */*",
    "Referer": f"{ARTWORK_API_BASE}/",
}
ITUNES_HEADERS = {"User-Agent": USER_AGENT}

JUNK_GENRES = {
    "music",
    "bonus track",
    "bonus tracks",
    "seen live",
    "favorites",
    "favourite",
    "favourites",
    "albums i own",
    "under 2000 listeners",
    "spotify",
    "youtube",
    "apple music",
    "remastered",
    "explicit",
    "clean",
    "album",
    "single",
    "ep",
    "soundtrack",
    "live",
    "instrumental",
    "acoustic",
    "karaoke",
    "all",
    "other",
    "pop/rock",
}


# ==============================================================================
# SECTION 2: SHARED TEXT & TAG HELPERS
# ==============================================================================

def primary_artist_only(raw_artist: str | None) -> str:
    if not raw_artist:
        return "Unknown Artist"
    first = raw_artist.split(",", 1)[0].strip()
    return first if first else "Unknown Artist"


def clean_lyric_title(raw_title: str) -> str:
    cleaned = re.sub(
        r"\s*[\(\[](?:official\s+)?(?:audio|video|lyric[s]?|visualizer|remaster(?:ed)?(?:\s+\d{4})?)[\)\]]",
        "",
        raw_title,
        flags=re.IGNORECASE,
    )
    return re.sub(r"\s+", " ", cleaned).strip()


def clean_genre_list(raw_genres: list[str], artist: str, album: str) -> list[str]:
    blocked = {
        artist.lower().strip(),
        primary_artist_only(artist).lower().strip(),
        album.lower().strip(),
        *JUNK_GENRES,
    }
    cleaned: list[str] = []
    seen: set[str] = set()

    for g in raw_genres:
        for part in re.split(r"[,;/|]+", str(g)):
            item = re.sub(r"\s+", " ", part).strip()
            low = item.lower()
            if not item or len(item) < 2 or len(item) > 35:
                continue
            if low in blocked or low in seen or item.isdigit():
                continue
            if any(word in low for word in ("2000 listeners", "seen live", "favorites", "remaster")):
                continue
            seen.add(low)
            cleaned.append(item.title() if item.islower() else item)
            if len(cleaned) >= 3:
                return cleaned
    return cleaned


# ==============================================================================
# SECTION 3: METADATA LOOKUP (YEAR, GENRES & STATIC FALLBACK COVERS)
# ==============================================================================

def lookup_album_metadata(artist: str, album: str) -> tuple[list[str], str | None, list[str]]:
    clean_artist = primary_artist_only(artist)
    raw_genres: list[str] = []
    candidate_years: list[int] = []
    static_covers: list[str] = []

    # 3a. MusicBrainz release-group (earliest release date first)
    try:
        resp = requests.get(
            "https://musicbrainz.org/ws/2/release-group/",
            params={
                "query": f'releasegroup:"{album}" AND artist:"{clean_artist}"',
                "fmt": "json",
                "limit": 5,
            },
            headers=MB_HEADERS,
            timeout=15,
        )
        time.sleep(1.1)
        if resp.status_code == 200:
            groups = (resp.json() or {}).get("release-groups") or []
            for grp in groups:
                first_date = (grp.get("first-release-date") or "").strip()
                if len(first_date) >= 4 and first_date[:4].isdigit():
                    candidate_years.append(int(first_date[:4]))
            if groups:
                top = groups[0]
                for g in top.get("genres") or []:
                    if isinstance(g, dict) and g.get("name"):
                        raw_genres.append(str(g["name"]))
                tags = sorted(
                    top.get("tags") or [],
                    key=lambda x: x.get("count", 0),
                    reverse=True,
                )
                for t in tags[:6]:
                    if isinstance(t, dict) and t.get("name"):
                        raw_genres.append(str(t["name"]))
    except Exception:
        pass

    # 3b. iTunes catalog lookup
    try:
        it_resp = requests.get(
            "https://itunes.apple.com/search",
            params={"term": f"{clean_artist} {album}".strip(), "media": "music", "entity": "album", "limit": 5},
            headers=ITUNES_HEADERS,
            timeout=15,
        )
        if it_resp.status_code == 200:
            for item in (it_resp.json() or {}).get("results") or []:
                it_artist = str(item.get("artistName") or "")
                if clean_artist.lower() not in it_artist.lower() and it_artist.lower() not in clean_artist.lower():
                    continue
                if item.get("releaseDate"):
                    y_str = str(item["releaseDate"])[:4]
                    if y_str.isdigit():
                        candidate_years.append(int(y_str))
                if item.get("primaryGenreName"):
                    raw_genres.append(str(item["primaryGenreName"]))
                art = str(item.get("artworkUrl100") or "")
                if art:
                    for sz in ("1000x1000bb", "800x800bb", "600x600bb"):
                        static_covers.append(re.sub(r"/\d+x\d+bb\.", f"/{sz}.", art))
                break
    except Exception:
        pass

    # 3c. Deezer catalog lookup
    try:
        dz_resp = requests.get(
            "https://api.deezer.com/search/album",
            params={"q": f'artist:"{clean_artist}" album:"{album}"', "limit": 3},
            headers={"User-Agent": USER_AGENT},
            timeout=15,
        )
        if dz_resp.status_code == 200:
            for item in (dz_resp.json() or {}).get("data") or []:
                aid = item.get("id")
                if aid:
                    adet = requests.get(
                        f"https://api.deezer.com/album/{aid}",
                        headers={"User-Agent": USER_AGENT},
                        timeout=15,
                    )
                    if adet.status_code == 200:
                        aj = adet.json() or {}
                        if aj.get("release_date"):
                            y_str = str(aj["release_date"])[:4]
                            if y_str.isdigit():
                                candidate_years.append(int(y_str))
                        for g in ((aj.get("genres") or {}).get("data") or []):
                            if isinstance(g, dict) and g.get("name"):
                                raw_genres.append(str(g["name"]))
                        for ckey in ("cover_xl", "cover_big", "cover_medium"):
                            if aj.get(ckey):
                                static_covers.append(str(aj[ckey]))
                break
    except Exception:
        pass

    # 3d. Last.fm tags & images (when LASTFM_API_KEY is configured)
    if LASTFM_API_KEY.strip():
        try:
            lfm_info = requests.get(
                "https://ws.audioscrobbler.com/2.0/",
                params={
                    "method": "album.getinfo",
                    "api_key": LASTFM_API_KEY.strip(),
                    "artist": clean_artist,
                    "album": album,
                    "format": "json",
                },
                headers={"User-Agent": USER_AGENT},
                timeout=15,
            )
            if lfm_info.status_code == 200:
                alb_obj = (lfm_info.json() or {}).get("album") or {}
                tags = ((alb_obj.get("tags") or {}).get("tag")) or []
                if isinstance(tags, dict):
                    tags = [tags]
                for t in tags:
                    if isinstance(t, dict) and t.get("name"):
                        raw_genres.append(str(t["name"]))
                for img in alb_obj.get("image") or []:
                    if isinstance(img, dict) and img.get("#text"):
                        u = str(img["#text"]).strip()
                        if u.startswith("http"):
                            static_covers.append(u)
        except Exception:
            pass

    valid_years = [y for y in candidate_years if 1900 <= y <= 2026]
    year = str(min(valid_years)) if valid_years else None
    genres = clean_genre_list(raw_genres, clean_artist, album)
    return genres, year, static_covers


# ==============================================================================
# SECTION 4: AUDIO TAG EMBEDDING
# ==============================================================================

def embed_tags(
    audio_path: Path,
    artist: str,
    album: str,
    title: str,
    genres: list[str],
    year: str | None,
) -> None:
    clean_artist = primary_artist_only(artist)
    try:
        loaded = MutagenFile(audio_path)

        if isinstance(loaded, OggOpus):
            audio = OggOpus(audio_path)
            if audio.tags is None:
                audio.add_tags()
            audio.tags["artist"] = [clean_artist]
            audio.tags["album"] = [album]
            audio.tags["title"] = [title]
            if genres:
                audio.tags["genre"] = list(genres)
            if year:
                audio.tags["date"] = [year]
            audio.save()
            return

        if isinstance(loaded, FLAC):
            audio = FLAC(audio_path)
            if audio.tags is None:
                audio.add_tags()
            audio.tags["artist"] = [clean_artist]
            audio.tags["album"] = [album]
            audio.tags["title"] = [title]
            if genres:
                audio.tags["genre"] = list(genres)
            if year:
                audio.tags["date"] = [year]
            audio.save()
            return

        if isinstance(loaded, MP3):
            audio = MP3(audio_path)
            if audio.tags is None:
                audio.add_tags()
            from mutagen.id3 import TALB, TCON, TDRC, TIT2, TPE1  # type: ignore

            audio.tags.delall("TPE1")
            audio.tags.delall("TALB")
            audio.tags.delall("TIT2")
            audio.tags.add(TPE1(encoding=3, text=[clean_artist]))
            audio.tags.add(TALB(encoding=3, text=[album]))
            audio.tags.add(TIT2(encoding=3, text=[title]))
            if genres:
                audio.tags.delall("TCON")
                audio.tags.add(TCON(encoding=3, text=list(genres)))
            if year:
                audio.tags.delall("TDRC")
                audio.tags.add(TDRC(encoding=3, text=[year]))
            audio.save()
            return

        if isinstance(loaded, MP4):
            audio = MP4(audio_path)
            if audio.tags is None:
                audio.add_tags()
            audio.tags["\xa9ART"] = [clean_artist]
            audio.tags["\xa9alb"] = [album]
            audio.tags["\xa9nam"] = [title]
            if genres:
                audio.tags["\xa9gen"] = [", ".join(genres)]
            if year:
                audio.tags["\xa9day"] = [year]
            audio.save()
            return

        easy = MutagenFile(audio_path, easy=True)
        if easy is not None:
            if easy.tags is None:
                easy.add_tags()
            easy.tags["artist"] = [clean_artist]
            easy.tags["album"] = [album]
            easy.tags["title"] = [title]
            if genres:
                easy.tags["genre"] = list(genres)
            if year:
                easy.tags["date"] = [year]
            easy.save()
    except Exception as exc:
        print(f"    [WARN] Tag embed failed for {audio_path.name}: {exc}")


# ==============================================================================
# SECTION 5: ALBUM COVER ARTWORK (ANIMATED m8tec + STATIC FALLBACK)
# ==============================================================================

def clamp_to_600_1024(w: int, h: int) -> tuple[int, int]:
    if w <= 0 or h <= 0:
        return (600, 600)
    min_d = min(w, h)
    max_d = max(w, h)
    if min_d < 600:
        scale = 600.0 / min_d
        return (max(600, min(1024, round(w * scale))), max(600, min(1024, round(h * scale))))
    if max_d > 1024:
        scale = 1024.0 / max_d
        return (max(600, min(1024, round(w * scale))), max(600, min(1024, round(h * scale))))
    return (w, h)


def probe_video_dimensions(media_input: str) -> tuple[int, int]:
    if shutil.which("ffprobe") is None:
        return (600, 600)
    try:
        res = subprocess.run(
            [
                "ffprobe",
                "-v",
                "error",
                "-select_streams",
                "v:0",
                "-show_entries",
                "stream=width,height",
                "-of",
                "json",
                media_input,
            ],
            capture_output=True,
            text=True,
            timeout=20,
        )
        if res.returncode == 0 and res.stdout:
            data = json.loads(res.stdout)
            streams = data.get("streams") or []
            if streams:
                w = int(streams[0].get("width") or 0)
                h = int(streams[0].get("height") or 0)
                if w > 0 and h > 0:
                    return (w, h)
    except Exception:
        pass
    return (600, 600)


def pick_best_hls_variant_url(master_m3u8_url: str, playlist_text: str) -> str:
    best_url = master_m3u8_url
    best_pixels = -1
    lines = [ln.strip() for ln in playlist_text.splitlines() if ln.strip()]
    for idx, line in enumerate(lines):
        if line.startswith("#EXT-X-STREAM-INF") and idx + 1 < len(lines):
            next_uri = lines[idx + 1]
            if next_uri.startswith("#"):
                continue
            m_res = re.search(r"RESOLUTION=(\d+)x(\d+)", line)
            pixels = int(m_res.group(1)) * int(m_res.group(2)) if m_res else 0
            if pixels > best_pixels:
                best_pixels = pixels
                best_url = urljoin(master_m3u8_url, next_uri)
    return best_url


def download_hls_segments_to_temp_mp4(m3u8_url: str, out_mp4: Path) -> bool:
    try:
        r = requests.get(m3u8_url, headers=M8TEC_HEADERS, timeout=20)
        if r.status_code != 200 or "#EXTM3U" not in r.text:
            return False

        variant_url = pick_best_hls_variant_url(m3u8_url, r.text)
        vr = requests.get(variant_url, headers=M8TEC_HEADERS, timeout=20)
        if vr.status_code != 200 or "#EXTM3U" not in vr.text:
            return False

        segment_urls: list[str] = []
        for raw_line in vr.text.splitlines():
            line = raw_line.strip()
            if not line:
                continue
            if line.startswith("#EXT-X-MAP:"):
                m_uri = re.search(r'URI="([^"]+)"', line)
                if m_uri:
                    segment_urls.append(urljoin(variant_url, m_uri.group(1)))
            elif not line.startswith("#"):
                segment_urls.append(urljoin(variant_url, line))

        if not segment_urls:
            return False

        buf = bytearray()
        for seg_url in segment_urls:
            for _attempt in range(3):
                try:
                    sr = requests.get(seg_url, headers=M8TEC_HEADERS, timeout=20)
                    if sr.status_code == 200 and sr.content:
                        buf.extend(sr.content)
                        break
                except Exception:
                    time.sleep(0.5)

        if not buf:
            return False

        out_mp4.write_bytes(bytes(buf))
        return True
    except Exception:
        return False


def convert_hls_or_video_to_webp(stream_url: str, dest_webp: Path) -> bool:
    if shutil.which("ffmpeg") is None:
        return False

    tmp_webp = dest_webp.with_suffix(".tmp.webp")

    with tempfile.TemporaryDirectory() as tmpdir:
        input_target = stream_url
        if ".m3u8" in stream_url.lower():
            local_stream = Path(tmpdir) / "stream.mp4"
            if download_hls_segments_to_temp_mp4(stream_url, local_stream):
                input_target = str(local_stream)
        elif stream_url.lower().endswith((".mp4", ".m4v", ".mov")):
            try:
                resp = requests.get(stream_url, headers=M8TEC_HEADERS, timeout=30)
                if resp.status_code == 200 and resp.content:
                    local_vid = Path(tmpdir) / "cover.mp4"
                    local_vid.write_bytes(resp.content)
                    input_target = str(local_vid)
            except Exception:
                pass

        src_w, src_h = probe_video_dimensions(input_target)
        out_w, out_h = clamp_to_600_1024(src_w, src_h)

        cmd = [
            "ffmpeg",
            "-y",
            "-loglevel",
            "error",
            "-reconnect",
            "1",
            "-reconnect_streamed",
            "1",
            "-reconnect_delay_max",
            "5",
            "-i",
            input_target,
            "-vf",
            f"scale={out_w}:{out_h}:flags=lanczos",
            "-loop",
            "0",
            "-an",
            "-q:v",
            "80",
            str(tmp_webp),
        ]
        try:
            res = subprocess.run(cmd, timeout=60)
            if res.returncode == 0 and tmp_webp.exists() and tmp_webp.stat().st_size > 0:
                tmp_webp.replace(dest_webp)
                return True
        except Exception:
            pass
        finally:
            tmp_webp.unlink(missing_ok=True)

    return False


def extract_m3u8_urls_from_payload(obj: Any, found: list[str]) -> None:
    if isinstance(obj, str):
        s = obj.strip()
        if s.startswith(("http://", "https://")) and any(
            k in s.lower() for k in (".m3u8", ".mp4", ".m4v", ".mov", "animated", "motion")
        ):
            found.append(s)
    elif isinstance(obj, dict):
        for v in obj.values():
            extract_m3u8_urls_from_payload(v, found)
    elif isinstance(obj, list):
        for v in obj:
            extract_m3u8_urls_from_payload(v, found)


def fetch_m8tec_animated_webp(artist: str, album: str, title: str, dest_webp: Path) -> bool:
    clean_artist = primary_artist_only(artist)
    params_list = [
        {"artist": clean_artist, "album": album, "title": title},
        {"artist": clean_artist, "album": album},
    ]

    stream_candidates: list[str] = []
    for params in params_list:
        q_params = {k: v for k, v in params.items() if v}
        try:
            resp = requests.get(
                ARTWORK_SEARCH_URL,
                params=q_params,
                headers=M8TEC_HEADERS,
                timeout=20,
            )
            if resp.status_code != 200:
                continue
            ctype = resp.headers.get("Content-Type", "").lower()
            if "json" in ctype or resp.text.strip().startswith(("{", "[")):
                extract_m3u8_urls_from_payload(resp.json(), stream_candidates)
            elif "#EXTM3U" in resp.text:
                stream_candidates.append(resp.url)
        except Exception:
            continue

    seen: set[str] = set()
    for s_url in stream_candidates:
        if s_url in seen:
            continue
        seen.add(s_url)
        if convert_hls_or_video_to_webp(s_url, dest_webp):
            print("    [ART] Saved animated cover.webp via artwork.m8tec.top")
            return True

    return False


def save_static_cover_webp(cover_urls: list[str], dest_webp: Path) -> bool:
    for url in cover_urls:
        try:
            r = requests.get(url, headers=ITUNES_HEADERS, timeout=15)
            if r.status_code != 200 or not r.content:
                continue
            with Image.open(io.BytesIO(r.content)) as im:
                rgb = im.convert("RGB")
                out_w, out_h = clamp_to_600_1024(*rgb.size)
                if (out_w, out_h) != rgb.size:
                    rgb = rgb.resize((out_w, out_h), Image.Resampling.LANCZOS)
                rgb.save(dest_webp, format="WEBP", quality=90, method=6)
                print(f"    [ART] Saved {out_w}x{out_h} static cover.webp")
                return True
        except Exception:
            continue
    return False


def ensure_cover_webp(
    artist: str,
    album: str,
    title: str,
    static_covers: list[str],
    dest_webp: Path,
) -> None:
    if dest_webp.exists() and dest_webp.stat().st_size > 0:
        return
    if fetch_m8tec_animated_webp(artist, album, title, dest_webp):
        return
    save_static_cover_webp(static_covers, dest_webp)


# ==============================================================================
# SECTION 6: LYRICS FETCHING & CLEANUP (.LRC NEXT TO TRACKS)
# ==============================================================================

def has_syllable_sync(lyrics_text: str) -> bool:
    return bool(re.search(r"<\d{1,2}:\d{2}(?:\.\d{1,3})?>", lyrics_text))


def cleanup_junk_lyrics_in_album(album_dir: Path, audio_files: list[Path]) -> None:
    for p in list(album_dir.iterdir()):
        if not p.is_file():
            continue
        if p.name.lower().endswith(".lrc.txt"):
            p.unlink(missing_ok=True)

    stems = {a.stem.lower().strip() for a in audio_files}
    titles_only = {
        a.stem.split(" - ", 1)[1].lower().strip()
        for a in audio_files
        if " - " in a.stem
    }

    for p in list(album_dir.iterdir()):
        if not p.is_file() or p.suffix.lower() != ".lrc":
            continue
        p_stem = p.stem.lower().strip()
        if p_stem in titles_only and any(s.startswith(p_stem + " - ") for s in stems):
            p.unlink(missing_ok=True)


def collect_local_lyrics(
    track_stem: str,
    title: str,
    album_dir: Path,
) -> Path | None:
    target_lrc = album_dir / f"{track_stem}.lrc"
    if target_lrc.exists() and target_lrc.stat().st_size > 0:
        return target_lrc

    candidates = {track_stem.lower().strip(), title.lower().strip()}
    candidates.discard("")
    if not candidates:
        return None

    search_roots = [album_dir]
    if DOWNLOADS_DIR.exists():
        search_roots.append(DOWNLOADS_DIR)

    for sdir in search_roots:
        for root, _, files in os.walk(sdir):
            for fname in files:
                fl = fname.lower()
                if not (fl.endswith(".lrc.txt") or Path(fl).suffix in LYRIC_EXTS):
                    continue
                base = re.sub(r"\.(elrc|lrc(\.txt)?|ttml)$", "", fname, flags=re.IGNORECASE).lower()
                if any(c in base or base in c for c in candidates):
                    src = Path(root) / fname
                    try:
                        raw = src.read_text(encoding="utf-8", errors="ignore").strip()
                        if raw:
                            target_lrc.write_text(raw + "\n", encoding="utf-8")
                            if src.parent != album_dir.resolve() and DOWNLOADS_DIR.resolve() in src.resolve().parents:
                                src.unlink(missing_ok=True)
                            return target_lrc
                    except Exception:
                        pass
    return None


def fetch_lyrics_lrc(
    artist: str,
    album: str,
    title: str,
    track_stem: str,
    album_dir: Path,
) -> Path | None:
    dest_lrc = album_dir / f"{track_stem}.lrc"
    if dest_lrc.exists() and dest_lrc.stat().st_size > 0:
        return dest_lrc

    local_found = collect_local_lyrics(track_stem, title, album_dir)
    if local_found:
        return local_found

    if syncedlyrics is None:
        return None

    clean_artist = primary_artist_only(artist)
    clean_title = clean_lyric_title(title) or title
    queries = [
        f"{clean_artist} {clean_title}".strip(),
        f"{clean_title} {clean_artist}".strip(),
    ]

    for query in queries:
        for enhanced_flag in (True, False):
            try:
                lyrics_text = syncedlyrics.search(query, enhanced=enhanced_flag)
                if lyrics_text and lyrics_text.strip():
                    dest_lrc.write_text(lyrics_text.strip() + "\n", encoding="utf-8")
                    sync_kind = "syllable/word-synced" if has_syllable_sync(lyrics_text) else "line-synced"
                    print(f"    [LYRICS] Saved {dest_lrc.name} ({sync_kind})")
                    return dest_lrc
            except Exception as exc:
                print(f"    [WARN] syncedlyrics error ({query}, enhanced={enhanced_flag}): {exc}", file=sys.stderr)

    return None


# ==============================================================================
# SECTION 7: ALBUM & USER ORCHESTRATION + ENTRYPOINT
# ==============================================================================

def process_album_folder(album_dir: Path) -> None:
    marker_path = album_dir / DONE_MARKER_NAME
    if marker_path.exists():
        return

    audio_files = sorted(
        [p for p in album_dir.iterdir() if p.is_file() and p.suffix.lower() in AUDIO_EXTS],
        key=lambda p: p.name.lower(),
    )
    if not audio_files:
        return

    cleanup_junk_lyrics_in_album(album_dir, audio_files)

    manifest_path = album_dir / ".enrich_manifest.json"
    manifest_tracks: dict[str, dict[str, Any]] = {}
    if manifest_path.exists():
        try:
            mdata = json.loads(manifest_path.read_text(encoding="utf-8"))
            for item in mdata.get("tracks", []):
                manifest_tracks[item.get("file", "")] = item
        except Exception:
            pass

    inferred_album = album_dir.name
    inferred_artist = primary_artist_only(
        album_dir.parent.name if album_dir.parent != MUSIC_ROOT else "Unknown Artist"
    )
    first_title = audio_files[0].stem

    if manifest_tracks:
        first_item = next(iter(manifest_tracks.values()))
        inferred_artist = primary_artist_only(first_item.get("artist") or inferred_artist)
        inferred_album = first_item.get("album") or inferred_album
        first_title = first_item.get("title") or first_title

    print(f"  Album: {inferred_artist} - {inferred_album} ({len(audio_files)} track(s))")

    genres, year, static_covers = lookup_album_metadata(inferred_artist, inferred_album)
    print(f"    [META] Genres={genres or ['N/A']} | Year={year or 'N/A'}")

    cover_webp = album_dir / "cover.webp"
    ensure_cover_webp(
        artist=inferred_artist,
        album=inferred_album,
        title=first_title,
        static_covers=static_covers,
        dest_webp=cover_webp,
    )

    for audio_path in audio_files:
        m_entry = manifest_tracks.get(audio_path.name, {})
        track_artist = primary_artist_only(m_entry.get("artist") or inferred_artist)
        track_album = m_entry.get("album") or inferred_album
        track_title = m_entry.get("title") or audio_path.stem

        embed_tags(
            audio_path=audio_path,
            artist=track_artist,
            album=track_album,
            title=track_title,
            genres=genres,
            year=year,
        )

        fetch_lyrics_lrc(
            artist=track_artist,
            album=track_album,
            title=track_title,
            track_stem=audio_path.stem,
            album_dir=album_dir,
        )

    marker_path.write_text("processed\n", encoding="utf-8")


def process_user_music_dir(user_music_dir: Path) -> None:
    print(f"\n=== [Stage 2] Music User: {user_music_dir.name} ===")
    for artist_dir in sorted(
        [p for p in user_music_dir.iterdir() if p.is_dir() and not p.name.startswith(".")]
    ):
        for album_dir in sorted(
            [p for p in artist_dir.iterdir() if p.is_dir() and not p.name.startswith(".")]
        ):
            process_album_folder(album_dir)


def main() -> None:
    if not MUSIC_ROOT.exists():
        print(f"Music directory not found: {MUSIC_ROOT}")
        return

    user_dirs = sorted(
        [p for p in MUSIC_ROOT.iterdir() if p.is_dir() and not p.name.startswith(".")],
        key=lambda p: p.name.lower(),
    )

    if not user_dirs:
        print(f"No user folders found in {MUSIC_ROOT}")
        return

    for udir in user_dirs:
        process_user_music_dir(udir)

    print("\nStage 2 complete.")


if __name__ == "__main__":
    main()
