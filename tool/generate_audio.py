#!/usr/bin/env python3
"""Pre-generate en-US neural MP3 clips for Chenning.

Uses Microsoft Edge neural TTS (edge-tts) for near-human American English.
Output layout matches the Flutter SpeakService contract so the same files can
later be hosted on a CDN / backend and resolved via remoteBaseUrl.

Usage:
  python3 -m venv tool/.venv
  tool/.venv/bin/pip install -r tool/requirements-audio.txt
  tool/.venv/bin/python tool/generate_audio.py

Keep `audio_key()` in sync with lib/services/audio_key.dart.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VOCAB = ROOT / "assets" / "vocab" / "grade5_beijing.json"
LEVELS = ROOT / "assets" / "levels" / "grade5_levels.json"
OUT_DIR = ROOT / "assets" / "audio" / "en-us"
MANIFEST = ROOT / "assets" / "audio" / "manifest.json"

DEFAULT_VOICE = "en-US-AriaNeural"
DEFAULT_RATE = "-10%"  # slightly slower for kids / vocabulary


def audio_key(text: str) -> str:
    lower = text.strip().lower()
    if not lower:
        return ""
    slug = re.sub(r"[^a-z0-9]+", "_", lower)
    return slug.strip("_")


def collect_phrases() -> dict[str, str]:
    """Map audio_key -> original speak text."""
    phrases: dict[str, str] = {}

    def add(text: str) -> None:
        cleaned = text.strip()
        if not cleaned:
            return
        key = audio_key(cleaned)
        if not key:
            return
        # Prefer first-seen casing; keys are case-insensitive.
        phrases.setdefault(key, cleaned)

    vocab = json.loads(VOCAB.read_text(encoding="utf-8"))
    for word in vocab["words"]:
        add(word.get("tts") or word["en"])
        add(word["en"])

    levels = json.loads(LEVELS.read_text(encoding="utf-8"))
    for level in levels["levels"]:
        for q in level.get("questions", []):
            add(q.get("word") or "")

    add("recyclable")  # home demo
    return phrases


async def synthesize_one(
    text: str,
    out_path: Path,
    voice: str,
    rate: str,
    proxy: str | None,
) -> None:
    import edge_tts

    tmp_path = out_path.with_suffix(".mp3.partial")
    if tmp_path.exists():
        tmp_path.unlink()
    communicate = edge_tts.Communicate(text, voice, rate=rate, proxy=proxy)
    await communicate.save(str(tmp_path))
    if tmp_path.stat().st_size <= 0:
        tmp_path.unlink(missing_ok=True)
        raise RuntimeError("empty audio file")
    tmp_path.replace(out_path)


async def generate(
    voice: str,
    rate: str,
    force: bool,
    proxy: str | None,
    limit: int | None,
) -> None:
    try:
        import edge_tts  # noqa: F401
    except ImportError:
        print(
            "edge-tts not installed. Run:\n"
            "  python3 -m venv tool/.venv\n"
            "  tool/.venv/bin/pip install -r tool/requirements-audio.txt",
            file=sys.stderr,
        )
        sys.exit(1)

    phrases = collect_phrases()
    items = sorted(phrases.items(), key=lambda kv: kv[0])
    if limit is not None:
        items = items[:limit]

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    clips: dict[str, dict] = {}
    ok = 0
    skipped = 0
    failed: list[str] = []

    for i, (key, text) in enumerate(items, 1):
        out_path = OUT_DIR / f"{key}.mp3"
        clips[key] = {"text": text, "file": f"en-us/{key}.mp3"}
        if out_path.exists() and out_path.stat().st_size > 0 and not force:
            skipped += 1
            print(f"[{i}/{len(items)}] skip {key}", flush=True)
            continue
        try:
            await synthesize_one(text, out_path, voice, rate, proxy)
            ok += 1
            print(f"[{i}/{len(items)}] ok   {key}  ({text})", flush=True)
        except Exception as exc:  # noqa: BLE001
            failed.append(key)
            print(f"[{i}/{len(items)}] FAIL {key}: {exc}", file=sys.stderr, flush=True)
            for p in (out_path, out_path.with_suffix(".mp3.partial")):
                if p.exists():
                    p.unlink()

    manifest = {
        "locale": "en-US",
        "voice": voice,
        "rate": rate,
        "version": 1,
        # Bundle path prefix inside Flutter assets/.
        "assetBase": "assets/audio",
        # When non-null, SpeakService prefers CDN / backend clips:
        #   {remoteBaseUrl}/{file}  e.g. https://cdn.example/audio/en-us/which.mp3
        "remoteBaseUrl": None,
        "clips": clips,
    }
    MANIFEST.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        f"\nDone. generated={ok} skipped={skipped} failed={len(failed)} "
        f"total={len(items)}"
    )
    print(f"Manifest: {MANIFEST.relative_to(ROOT)}")
    if failed:
        print("Failed keys:", ", ".join(failed), file=sys.stderr)
        sys.exit(2)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--voice", default=DEFAULT_VOICE)
    parser.add_argument("--rate", default=DEFAULT_RATE)
    parser.add_argument("--force", action="store_true", help="Regenerate existing")
    parser.add_argument(
        "--proxy",
        default=None,
        help="HTTP(S) proxy, e.g. http://127.0.0.1:7890",
    )
    parser.add_argument("--limit", type=int, default=None, help="Only first N (debug)")
    args = parser.parse_args()
    asyncio.run(
        generate(
            voice=args.voice,
            rate=args.rate,
            force=args.force,
            proxy=args.proxy,
            limit=args.limit,
        )
    )


if __name__ == "__main__":
    main()
