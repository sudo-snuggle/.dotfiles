#!/usr/bin/env python3
"""
Stage 1: Organize per-user MeTube downloads (~/Downloads/metube/<user>)
into ~/Music/<user>/<Artist>/<Album>/ and move files cleanly.
"""

from __future__ import annotations

import json
import os
import re
import shutil
from pathlib import Path
from typing import Any

from mutagen import File as MutagenFile

SCRIPT_DIR = Path(__file__).resolve().parent  # ~/.dotfiles/Music
HOME = Path.home()
METUBE_ROOT = HOME / "Downloads" / "metube"
MUSIC_ROOT = HOME / "Music"

AUDIO_EXTS = {".opus", ".m4a", ".mp3", ".flac", ".ogg", ".wav", ".aac", ".wma"}
LYRIC_EXTS = {".lrc", ".elrc", ".ttml"}


def sanitize_path_part(name: str, fallback: str = "Unknown") -> str:
    cleaned = (name or "").strip()
    cleaned = re.sub(r'[\\/:*?"<>|]+', "_", cleaned)
    cleaned = re.sub(r"\s+", " ", cleaned).strip(" .")
    return cleaned if cleaned else fallback


def primary_artist_only(raw_artist: str | None) -> str:
    """Keep only the first artist when comma-separated (e.g. 'aaaa, dddd' -> 'aaaa')."""
    if not raw_artist:
        return "Unknown Artist"
    first = raw_artist.split(",", 1)[0].strip()
    return first if first else "Unknown Artist"


def extract_tag_value(tags: Any, keys: list[str]) -> str | None:
    if not tags:
        return None
    for k in keys:
        if k in tags:
            val = tags[k]
        else:
            matched = next((tk for tk in tags.keys() if str(tk).lower() == k.lower()), None)
            val = tags[matched] if matched is not None else None

        if val is None:
            continue
        if isinstance(val, (list, tuple)) and val:
            text = str(val[0]).strip()
            if text:
                return text
        else:
            text = str(val).strip()
            if text:
                return text
    return None


def read_audio_metadata(audio_path: Path) -> dict[str, str]:
    fallback_title = audio_path.stem
    artist = "Unknown Artist"
    album = fallback_title
    title = fallback_title

    try:
        audio = MutagenFile(audio_path, easy=True)
        if audio is not None and audio.tags:
            raw_artist = extract_tag_value(audio.tags, ["artist", "albumartist", "performer"])
            raw_album = extract_tag_value(audio.tags, ["album"])
            raw_title = extract_tag_value(audio.tags, ["title"])

            if raw_artist:
                artist = primary_artist_only(raw_artist)
            if raw_title:
                title = raw_title
            album = raw_album if raw_album else title
    except Exception as exc:
        print(f"  [WARN] Could not read tags from {audio_path.name}: {exc}")

    return {
        "artist": artist,
        "album": album,
        "title": title,
    }


def normalize_lyric_dest_name(fname: str) -> str:
    """Converts .lrc.txt -> .lrc while keeping .elrc, .lrc, and .ttml extensions."""
    if re.search(r"\.lrc\.txt$", fname, flags=re.IGNORECASE):
        return re.sub(r"\.lrc\.txt$", ".lrc", fname, flags=re.IGNORECASE)
    return fname


def move_matching_lyrics(
    track_stem: str,
    title: str,
    user_down_dir: Path,
    dest_album_dir: Path,
) -> list[str]:
    moved_files: list[str] = []
    candidates = {track_stem.lower().strip(), title.lower().strip()}
    candidates.discard("")
    if not candidates:
        return moved_files

    search_roots = [user_down_dir]
    dl_dir = HOME / "Downloads"
    if dl_dir.exists() and dl_dir.resolve() != METUBE_ROOT.resolve():
        search_roots.append(dl_dir)

    music_resolved = MUSIC_ROOT.resolve()

    for sdir in search_roots:
        if not sdir.exists():
            continue
        for root, dirs, files in os.walk(sdir):
            root_path = Path(root).resolve()
            if root_path == music_resolved or music_resolved in root_path.parents:
                dirs[:] = []
                continue
            if sdir == dl_dir and root_path == METUBE_ROOT.resolve():
                dirs[:] = [d for d in dirs if (root_path / d) == user_down_dir.resolve()]

            for fname in files:
                fl = fname.lower()
                is_lyric = fl.endswith(".lrc.txt") or Path(fl).suffix in LYRIC_EXTS
                if not is_lyric:
                    continue

                base = re.sub(r"\.(elrc|lrc(\.txt)?|ttml)$", "", fname, flags=re.IGNORECASE).lower()
                if any(c in base or base in c for c in candidates):
                    src = Path(root) / fname
                    out_fname = normalize_lyric_dest_name(fname)
                    dest = dest_album_dir / out_fname
                    if src.resolve() == dest.resolve():
                        continue
                    dest_album_dir.mkdir(parents=True, exist_ok=True)
                    if dest.exists():
                        dest.unlink()
                    shutil.move(str(src), str(dest))
                    moved_files.append(dest.name)

    return moved_files


def cleanup_empty_dirs(root_dir: Path) -> None:
    if not root_dir.exists():
        return
    for current_root, dirs, _ in os.walk(root_dir, topdown=False):
        for d in dirs:
            p = Path(current_root) / d
            try:
                if p.exists() and not any(p.iterdir()):
                    p.rmdir()
            except OSError:
                pass


def process_user_folder(user_down_dir: Path) -> None:
    user_name = user_down_dir.name
    user_music_dir = MUSIC_ROOT / user_name
    print(f"\n=== [Stage 1] User: {user_name} ===")
    print(f"Source : {user_down_dir}")
    print(f"Target : {user_music_dir}")

    audio_files: list[Path] = []
    for root, _, files in os.walk(user_down_dir):
        for fname in files:
            p = Path(root) / fname
            if p.suffix.lower() in AUDIO_EXTS:
                audio_files.append(p)

    if not audio_files:
        print("  No audio files found.")
        return

    manifests_by_album: dict[Path, dict[str, Any]] = {}

    for audio_path in sorted(audio_files):
        if not audio_path.exists():
            continue

        meta = read_audio_metadata(audio_path)
        artist_clean = sanitize_path_part(meta["artist"], "Unknown Artist")
        album_clean = sanitize_path_part(meta["album"], sanitize_path_part(audio_path.stem, "Unknown Album"))

        dest_album_dir = user_music_dir / artist_clean / album_clean
        dest_album_dir.mkdir(parents=True, exist_ok=True)

        dest_audio = dest_album_dir / audio_path.name
        if dest_audio.exists():
            dest_audio.unlink()
        shutil.move(str(audio_path), str(dest_audio))

        lyrics_moved = move_matching_lyrics(
            track_stem=audio_path.stem,
            title=meta["title"],
            user_down_dir=user_down_dir,
            dest_album_dir=dest_album_dir,
        )

        manifest = manifests_by_album.setdefault(
            dest_album_dir,
            {
                "user": user_name,
                "artist": meta["artist"],
                "album": meta["album"],
                "tracks": [],
            },
        )
        manifest["tracks"].append(
            {
                "file": dest_audio.name,
                "title": meta["title"],
                "artist": meta["artist"],
                "album": meta["album"],
                "lyrics_moved": lyrics_moved,
            }
        )
        print(f"  Moved: {dest_audio.name} -> {artist_clean}/{album_clean}/")

    for album_dir, data in manifests_by_album.items():
        manifest_path = album_dir / ".enrich_manifest.json"
        existing_tracks: list[dict[str, Any]] = []
        if manifest_path.exists():
            try:
                old = json.loads(manifest_path.read_text(encoding="utf-8"))
                existing_tracks = old.get("tracks", [])
            except Exception:
                pass

        known_files = {t["file"] for t in existing_tracks}
        for t in data["tracks"]:
            if t["file"] not in known_files:
                existing_tracks.append(t)

        data["tracks"] = existing_tracks
        manifest_path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")

    cleanup_empty_dirs(user_down_dir)


def main() -> None:
    if not METUBE_ROOT.exists():
        print(f"MeTube download directory not found: {METUBE_ROOT}")
        return

    user_dirs = sorted(
        [p for p in METUBE_ROOT.iterdir() if p.is_dir() and not p.name.startswith(".")],
        key=lambda p: p.name.lower(),
    )

    if not user_dirs:
        print(f"No user subfolders found in {METUBE_ROOT}")
        return

    for udir in user_dirs:
        process_user_folder(udir)

    print("\nStage 1 complete.")


if __name__ == "__main__":
    main()