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
# SECTION 5: ALBUM COVER ART (ANIMATED M8TEC + STATIC ITUNES -> cover.webp)
# ==============================================================================

MIN_COVER_PX = 600
TARGET_COVER_PX = 1024


def fetch_m8tec_animated_urls(artist: str, album: str, title: str = "") -> list[str]:
    query_artist = artist.strip()
    query_album = album.strip()
    if not query_artist and not query_album:
        return []

    params = {"artist": query_artist, "album": query_album}
    if title.strip():
        params["title"] = title.strip()

    try:
        resp = requests.get(
            "https://artwork.m8tec.top/api/v1/artwork/search",
            params=params,
            headers={"User-Agent": USER_AGENT},
            timeout=15,
        )
        if resp.status_code != 200:
            return []
        data = resp.json() or {}
        urls: list[str] = []
        for key in ("url", "url_tall"):
            val = str(data.get(key) or "").strip()
            if val and val not in urls:
                urls.append(val)
        return urls
    except Exception:
        return []


def fetch_itunes_cover_urls(
    artist: str,
    album: str,
    size_px: int = TARGET_COVER_PX,
    limit: int = 5,
) -> list[str]:
    query = f"{artist} {album}".strip()
    if not query:
        return []
    try:
        resp = requests.get(
            "https://itunes.apple.com/search",
            params={"term": query, "media": "music", "entity": "album", "limit": limit},
            headers={"User-Agent": USER_AGENT},
            timeout=12,
        )
        if resp.status_code != 200:
            return []
        urls: list[str] = []
        seen: set[str] = set()
        for item in (resp.json() or {}).get("results", []):
            art = str(item.get("artworkUrl100") or "").strip()
            if not art:
                continue
            hi_url = re.sub(r"/\d+x\d+bb\.", f"/{size_px}x{size_px}bb.", art)
            if hi_url not in seen:
                seen.add(hi_url)
                urls.append(hi_url)
        return urls
    except Exception:
        return []


def _probe_image_dimensions(img_path: Path) -> tuple[int, int] | None:
    try:
        from PIL import Image

        with Image.open(img_path) as im:
            return im.size
    except Exception:
        pass

    if shutil.which("ffprobe"):
        try:
            proc = subprocess.run(
                [
                    "ffprobe",
                    "-v",
                    "error",
                    "-select_streams",
                    "v:0",
                    "-show_entries",
                    "stream=width,height",
                    "-of",
                    "csv=p=0:s=x",
                    str(img_path),
                ],
                capture_output=True,
                text=True,
                check=True,
            )
            parts = proc.stdout.strip().split("x")
            if len(parts) == 2:
                return int(parts[0]), int(parts[1])
        except Exception:
            pass
    return None


def _is_animated_webp(data: bytes) -> bool:
    if len(data) < 22 or data[:4] != b"RIFF" or data[8:12] != b"WEBP":
        return False
    return data[12:16] == b"VP8X" and bool(data[20] & 0x02)


def _encode_hls_to_animated_webp(hls_url: str, webp_target: Path) -> bool:
    if not shutil.which("ffmpeg"):
        return False

    tmp_out = webp_target.parent / ".cover_anim_tmp.webp"
    try:
        vf = (
            f"fps=24,"
            f"scale='if(gt(iw,ih),min({TARGET_COVER_PX},iw),-2)':"
            f"'if(gt(ih,iw),min({TARGET_COVER_PX},ih),-2)'"
        )
        cmd = [
            "ffmpeg",
            "-y",
            "-loglevel",
            "error",
            "-i",
            hls_url,
            "-vf",
            vf,
            "-c:v",
            "libwebp",
            "-loop",
            "0",
            "-quality",
            "80",
            "-an",
            str(tmp_out),
        ]
        subprocess.run(cmd, check=True, timeout=60)
        dims = _probe_image_dimensions(tmp_out)
        if not dims or min(dims) < MIN_COVER_PX:
            tmp_out.unlink(missing_ok=True)
            return False
        tmp_out.replace(webp_target)
        return webp_target.exists() and webp_target.stat().st_size > 0
    except Exception:
        tmp_out.unlink(missing_ok=True)
        return False


def _save_static_as_webp(raw_path: Path, data: bytes, webp_target: Path) -> bool:
    dims = _probe_image_dimensions(raw_path)
    if not dims:
        return False

    w, h = dims
    if min(w, h) < MIN_COVER_PX:
        return False

    needs_downscale = max(w, h) > TARGET_COVER_PX
    animated = _is_animated_webp(data)

    if animated and not needs_downscale:
        raw_path.replace(webp_target)
        return webp_target.exists() and webp_target.stat().st_size > 0

    if not shutil.which("ffmpeg"):
        return False

    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-i", str(raw_path)]
    if needs_downscale:
        cmd += [
            "-vf",
            f"scale='min({TARGET_COVER_PX},iw)':'min({TARGET_COVER_PX},ih)':force_original_aspect_ratio=decrease",
        ]
    if animated:
        cmd += ["-c:v", "libwebp", "-loop", "0", "-quality", "85"]
    else:
        cmd += ["-c:v", "libwebp", "-quality", "88"]
    cmd.append(str(webp_target))
    subprocess.run(cmd, check=True)
    return webp_target.exists() and webp_target.stat().st_size > 0


def ensure_cover_webp(
    cover_urls: list[str] | None = None,
    album_dir: Path | None = None,
    artist: str = "",
    album: str = "",
    title: str = "",
    dry_run: bool = False,
) -> Path | None:
    if album_dir is None:
        return None

    webp_target = album_dir / "cover.webp"
    if webp_target.exists() and webp_target.stat().st_size > 0:
        return webp_target

    if dry_run:
        print(f"  [DRY-RUN] Fetch cover art -> {webp_target}")
        return None

    album_dir.mkdir(parents=True, exist_ok=True)

    # 1. Animated HLS artwork via artwork.m8tec.top first
    for m3u8_url in fetch_m8tec_animated_urls(artist, album, title):
        if _encode_hls_to_animated_webp(m3u8_url, webp_target):
            print(f"    [COVER] Saved animated {webp_target.name} (m8tec)")
            return webp_target

    # 2. Static iTunes 1024x1024bb + any caller-provided cover_urls
    ordered_urls: list[str] = []
    seen_urls: set[str] = set()
    for u in [*fetch_itunes_cover_urls(artist, album), *(cover_urls or [])]:
        if u and u not in seen_urls:
            seen_urls.add(u)
            ordered_urls.append(u)

    if not ordered_urls:
        return None

    tmp_raw = album_dir / ".cover_raw_tmp"
    try:
        for url in ordered_urls:
            try:
                resp = requests.get(url, headers={"User-Agent": USER_AGENT}, timeout=15)
                if resp.status_code != 200 or not resp.content:
                    continue
                data = resp.content
            except Exception:
                continue

            tmp_raw.write_bytes(data)
            try:
                if _save_static_as_webp(tmp_raw, data, webp_target):
                    kind = "animated" if _is_animated_webp(data) else "static"
                    print(f"    [COVER] Saved {kind} {webp_target.name} (iTunes/fallback)")
                    return webp_target
            except Exception:
                pass
    finally:
        tmp_raw.unlink(missing_ok=True)

    return None


ensure_album_cover = ensure_cover_webp

# ==============================================================================
# SECTION 6: LYRICS FETCHING & CLEANUP (NEXT TO TRACKS)
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
        if not p.is_file() or p.suffix.lower() not in {".lrc", ".ttml"}:
            continue
        p_stem = p.stem.lower().strip()
        if p_stem in titles_only and any(s.startswith(p_stem + " - ") for s in stems):
            p.unlink(missing_ok=True)


def collect_local_lyrics(
    track_stem: str,
    title: str,
    album_dir: Path,
) -> Path | None:
    for ext in (".ttml", ".lrc", ".elrc"):
        existing = album_dir / f"{track_stem}{ext}"
        if existing.exists() and existing.stat().st_size > 0:
            return existing

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
                            out_ext = ".ttml" if ("<tt" in raw or fl.endswith(".ttml")) else ".lrc"
                            target = album_dir / f"{track_stem}{out_ext}"
                            target.write_text(raw + "\n", encoding="utf-8")
                            if src.parent != album_dir.resolve() and DOWNLOADS_DIR.resolve() in src.resolve().parents:
                                src.unlink(missing_ok=True)
                            return target
                    except Exception:
                        pass
    return None


def fetch_unison_raw(artist: str, title: str) -> tuple[str, str] | None:
    """Returns (content, ext) where ext is '.ttml' or '.lrc'."""
    try:
        r = requests.get(
            "https://unison.betterlyrics.org/lyrics",
            params={"song": title, "artist": artist},
            headers={"User-Agent": USER_AGENT},
            timeout=15,
        )
        if r.status_code != 200:
            return None
        payload = r.json() or {}
        if not payload.get("success"):
            return None
        data = payload.get("data") or {}
        raw = (data.get("lyrics") or "").strip()
        if not raw:
            return None
        ext = ".ttml" if "<tt" in raw else ".lrc"
        return raw, ext
    except Exception:
        return None


def fetch_lyrics_lrc(
    artist: str,
    album: str,
    title: str,
    track_stem: str,
    album_dir: Path,
) -> Path | None:
    local_found = collect_local_lyrics(track_stem, title, album_dir)
    if local_found:
        return local_found

    clean_artist = primary_artist_only(artist)
    clean_title = clean_lyric_title(title) or title

    # 1. Unison (saves raw format as-is: .ttml or .lrc)
    unison_res = fetch_unison_raw(clean_artist, clean_title)
    if unison_res:
        raw_text, ext = unison_res
        dest_file = album_dir / f"{track_stem}{ext}"
        dest_file.write_text(raw_text + "\n", encoding="utf-8")
        print(f"    [LYRICS] Saved {dest_file.name} (unison)")
        return dest_file

    # 2. syncedlyrics fallback (.lrc)
    if syncedlyrics is None:
        return None

    query = f"{clean_artist} {clean_title}".strip()
    lyrics_text: str | None = None
    try:
        lyrics_text = syncedlyrics.search(query, enhanced=True)
        if not lyrics_text or not lyrics_text.strip():
            lyrics_text = syncedlyrics.search(query, enhanced=False)
    except Exception as exc:
        print(f"    [WARN] syncedlyrics error for '{query}': {exc}", file=sys.stderr)
        return None

    if not lyrics_text or not lyrics_text.strip():
        return None

    dest_lrc = album_dir / f"{track_stem}.lrc"
    dest_lrc.write_text(lyrics_text.strip() + "\n", encoding="utf-8")
    sync_kind = "syllable/enhanced-synced" if has_syllable_sync(lyrics_text) else "line-synced"
    print(f"    [LYRICS] Saved {dest_lrc.name} ({sync_kind}, syncedlyrics)")
    return dest_lrc

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
