#!/usr/bin/env python3
"""
Stage 2: Enrich ~/Music/<user>/<Artist>/<Album>/ folders with:
  1. Single primary artist tag, genre, and album release year via MusicBrainz.
  2. Apple Music animated/high-res artwork resized to 600x600 cover.webp.
  3. Lyrics saved as .lrc next to tracks (local search + syncedlyrics word-synced priority).
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

SCRIPT_DIR = Path(__file__).resolve().parent  # ~/.dotfiles/Music
HOME = Path.home()
MUSIC_ROOT = HOME / "Music"
DOWNLOADS_DIR = HOME / "Downloads"

AUDIO_EXTS = {".opus", ".m4a", ".mp3", ".flac", ".ogg", ".wav", ".aac"}
LYRIC_EXTS = {".lrc", ".elrc", ".ttml"}

USER_AGENT = "HermesMusicOrganizer/1.0 (local-homelab@example.invalid)"
MB_HEADERS = {"User-Agent": USER_AGENT, "Accept": "application/json"}
ITUNES_HEADERS = {"User-Agent": USER_AGENT}
AMP_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
        "AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
    ),
    "Origin": "https://music.apple.com",
    "Referer": "https://music.apple.com/",
}


def primary_artist_only(raw_artist: str | None) -> str:
    if not raw_artist:
        return "Unknown Artist"
    first = raw_artist.split(",", 1)[0].strip()
    return first if first else "Unknown Artist"


def normalize_lyric_dest_name(fname: str) -> str:
    """Converts .lrc.txt -> .lrc while keeping .elrc, .lrc, and .ttml extensions."""
    if re.search(r"\.lrc\.txt$", fname, flags=re.IGNORECASE):
        return re.sub(r"\.lrc\.txt$", ".lrc", fname, flags=re.IGNORECASE)
    return fname


def embed_tags(
    audio_path: Path,
    artist: str,
    album: str,
    title: str,
    genre: str | None,
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
            if genre:
                audio.tags["genre"] = [genre]
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
            if genre:
                audio.tags["genre"] = [genre]
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
            if genre:
                audio.tags.delall("TCON")
                audio.tags.add(TCON(encoding=3, text=[genre]))
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
            if genre:
                audio.tags["\xa9gen"] = [genre]
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
            if genre:
                easy.tags["genre"] = [genre]
            if year:
                easy.tags["date"] = [year]
            easy.save()
    except Exception as exc:
        print(f"    [WARN] Tag embed failed for {audio_path.name}: {exc}")


def lookup_musicbrainz_album(artist: str, album: str) -> tuple[str | None, str | None]:
    clean_artist = primary_artist_only(artist)
    query = f'releasegroup:"{album}" AND artist:"{clean_artist}"'
    try:
        resp = requests.get(
            "https://musicbrainz.org/ws/2/release-group/",
            params={"query": query, "fmt": "json", "limit": 5},
            headers=MB_HEADERS,
            timeout=15,
        )
        time.sleep(1.1)
        if resp.status_code != 200:
            return None, None
        data = resp.json()
        groups = data.get("release-groups") or []
        if not groups:
            return None, None

        top = groups[0]
        year: str | None = None
        first_date = (top.get("first-release-date") or "").strip()
        if len(first_date) >= 4 and first_date[:4].isdigit():
            year = first_date[:4]

        genres: list[str] = []
        for g in top.get("genres") or []:
            name = (g.get("name") or "").strip()
            if name:
                genres.append(name)

        if not genres:
            tags = top.get("tags") or []
            tags_sorted = sorted(tags, key=lambda x: x.get("count", 0), reverse=True)
            for t in tags_sorted[:2]:
                name = (t.get("name") or "").strip()
                if name:
                    genres.append(name.title())

        genre = genres[0].title() if genres else None
        return genre, year
    except Exception as exc:
        print(f"    [WARN] MusicBrainz lookup error for '{clean_artist} - {album}': {exc}")
        return None, None


def save_600x600_webp_from_bytes(img_bytes: bytes, dest_webp: Path) -> bool:
    try:
        with Image.open(io.BytesIO(img_bytes)) as im:
            rgb = im.convert("RGB")
            resized = rgb.resize((600, 600), Image.Resampling.LANCZOS)
            resized.save(dest_webp, format="WEBP", quality=90, method=6)
        return True
    except Exception as exc:
        print(f"    [WARN] Failed converting image to 600x600 webp: {exc}")
        return False


def extract_first_frame_webp_from_video(video_bytes: bytes, dest_webp: Path) -> bool:
    if shutil.which("ffmpeg") is None:
        return False
    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            vid_path = Path(tmpdir) / "motion.mp4"
            frame_png = Path(tmpdir) / "frame.png"
            vid_path.write_bytes(video_bytes)

            cmd = [
                "ffmpeg",
                "-y",
                "-i",
                str(vid_path),
                "-vframes",
                "1",
                str(frame_png),
            ]
            res = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=20)
            if res.returncode != 0 or not frame_png.exists():
                return False
            return save_600x600_webp_from_bytes(frame_png.read_bytes(), dest_webp)
    except Exception:
        return False


def fetch_apple_music_cover_webp(artist: str, album: str, dest_webp: Path) -> bool:
    if dest_webp.exists():
        return True

    clean_artist = primary_artist_only(artist)
    term = f"{clean_artist} {album}".strip()

    try:
        resp = requests.get(
            "https://itunes.apple.com/search",
            params={"term": term, "media": "music", "entity": "album", "limit": 5},
            headers=ITUNES_HEADERS,
            timeout=15,
        )
        if resp.status_code != 200:
            return False
        results = (resp.json() or {}).get("results") or []
        if not results:
            return False

        item = results[0]

        for motion_key in ("motionArtworkUrl", "animatedArtworkUrl", "previewUrl"):
            m_url = item.get(motion_key)
            if isinstance(m_url, str) and (".mp4" in m_url or ".m4v" in m_url or ".mov" in m_url):
                try:
                    m_resp = requests.get(m_url, headers=AMP_HEADERS, timeout=20)
                    if m_resp.status_code == 200 and m_resp.content:
                        if extract_first_frame_webp_from_video(m_resp.content, dest_webp):
                            print("    [ART] Saved 600x600 cover.webp (from motion cover)")
                            return True
                except Exception:
                    pass

        art_url = item.get("artworkUrl100") or item.get("artworkUrl60")
        if not art_url:
            return False

        hi_res_url = re.sub(r"/\d+x\d+bb\.", "/1200x1200bb.", art_url)
        img_resp = requests.get(hi_res_url, headers=ITUNES_HEADERS, timeout=15)
        if img_resp.status_code != 200 or not img_resp.content:
            img_resp = requests.get(art_url, headers=ITUNES_HEADERS, timeout=15)

        if img_resp.status_code == 200 and img_resp.content:
            if save_600x600_webp_from_bytes(img_resp.content, dest_webp):
                print("    [ART] Saved 600x600 cover.webp")
                return True
    except Exception as exc:
        print(f"    [WARN] Apple Music cover lookup failed for '{term}': {exc}")

    return False


def collect_local_lyrics_for_track(
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
                        content = src.read_text(encoding="utf-8", errors="ignore").strip()
                        if content:
                            target_lrc.write_text(content + "\n", encoding="utf-8")
                            if src.parent != album_dir.resolve() and DOWNLOADS_DIR.resolve() in src.resolve().parents:
                                src.unlink()
                            return target_lrc
                    except Exception:
                        pass
    return None


def fetch_lyrics_as_lrc(
    artist: str,
    album: str,
    title: str,
    track_stem: str,
    album_dir: Path,
) -> Path | None:
    dest_lrc = album_dir / f"{track_stem}.lrc"
    if dest_lrc.exists() and dest_lrc.stat().st_size > 0:
        return dest_lrc

    local_found = collect_local_lyrics_for_track(track_stem, title, album_dir)
    if local_found:
        return local_found

    if syncedlyrics is None:
        return None

    clean_artist = primary_artist_only(artist)
    queries = [
        f"{clean_artist} {title} {album}".strip(),
        f"{clean_artist} {title}".strip(),
    ]

    for query in queries:
        for enhanced_flag in (True, False):
            try:
                lyrics_text = syncedlyrics.search(query, enhanced=enhanced_flag)
                if lyrics_text and lyrics_text.strip():
                    dest_lrc.write_text(lyrics_text.strip() + "\n", encoding="utf-8")
                    mode = "word-synced/enhanced" if enhanced_flag else "synced"
                    print(f"    [LYRICS] Saved {dest_lrc.name} ({mode})")
                    return dest_lrc
            except Exception as exc:
                print(f"    [WARN] syncedlyrics error ({query}, enhanced={enhanced_flag}): {exc}", file=sys.stderr)

    return None


def process_album_folder(album_dir: Path) -> None:
    audio_files = sorted(
        [p for p in album_dir.iterdir() if p.is_file() and p.suffix.lower() in AUDIO_EXTS],
        key=lambda p: p.name.lower(),
    )
    if not audio_files:
        return

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
    inferred_artist = primary_artist_only(album_dir.parent.name if album_dir.parent != MUSIC_ROOT else "Unknown Artist")

    if manifest_tracks:
        first_item = next(iter(manifest_tracks.values()))
        inferred_artist = primary_artist_only(first_item.get("artist") or inferred_artist)
        inferred_album = first_item.get("album") or inferred_album

    print(f"  Album: {inferred_artist} - {inferred_album} ({len(audio_files)} track(s))")

    genre, year = lookup_musicbrainz_album(inferred_artist, inferred_album)
    if genre or year:
        print(f"    [MB] Genre={genre or 'N/A'} | Year={year or 'N/A'}")

    cover_webp = album_dir / "cover.webp"
    fetch_apple_music_cover_webp(inferred_artist, inferred_album, cover_webp)

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
            genre=genre,
            year=year,
        )

        fetch_lyrics_as_lrc(
            artist=track_artist,
            album=track_album,
            title=track_title,
            track_stem=audio_path.stem,
            album_dir=album_dir,
        )


def process_user_music_dir(user_music_dir: Path) -> None:
    print(f"\n=== [Stage 2] Music User: {user_music_dir.name} ===")
    for artist_dir in sorted([p for p in user_music_dir.iterdir() if p.is_dir() and not p.name.startswith(".")]):
        for album_dir in sorted([p for p in artist_dir.iterdir() if p.is_dir() and not p.name.startswith(".")]):
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