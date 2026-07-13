#!/usr/bin/env python3
"""Generate deterministic filenames for Mello half-hour Edge TTS announcements."""

from __future__ import annotations

import argparse
import asyncio
import json
import os
import sys
import tempfile
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path


@dataclass(frozen=True)
class Announcement:
    filename: str
    text: str


def load_plan(manifest_path: Path) -> tuple[dict, list[Announcement]]:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    required = {"voice", "rate", "volume", "pitch", "schedule", "phraseTemplates", "fileTemplate"}
    missing = required - manifest.keys()
    if missing:
        raise ValueError(f"manifest is missing: {', '.join(sorted(missing))}")

    schedule = manifest["schedule"]
    if schedule != {"start": "00:00", "intervalMinutes": 30, "count": 48}:
        raise ValueError("schedule must describe all 48 half-hour slots beginning at 00:00")

    start = datetime.strptime(schedule["start"], "%H:%M")
    announcements: list[Announcement] = []
    for index in range(schedule["count"]):
        instant = start + timedelta(minutes=index * schedule["intervalMinutes"])
        values = {
            "hour24": instant.strftime("%H"),
            "hour12": str(int(instant.strftime("%I"))),
            "minute": instant.strftime("%M"),
            "ampm": instant.strftime("%p"),
        }
        template_key = "onHour" if instant.minute == 0 else "halfHour"
        announcements.append(
            Announcement(
                filename=manifest["fileTemplate"].format(**values),
                text=manifest["phraseTemplates"][template_key].format(**values),
            )
        )

    filenames = [item.filename for item in announcements]
    expected = [f"Time_{hour:02d}_{minute:02d}.mp3" for hour in range(24) for minute in (0, 30)]
    if filenames != expected or len(set(filenames)) != 48:
        raise ValueError("manifest does not produce the required 48 deterministic filenames")
    return manifest, announcements


async def generate(manifest: dict, plan: list[Announcement], output_dir: Path, force: bool) -> None:
    try:
        import edge_tts
    except ImportError as error:
        raise RuntimeError("Install the pinned dependency with: pip install -r requirements.txt") from error

    output_dir.mkdir(parents=True, exist_ok=True)
    for index, item in enumerate(plan, start=1):
        destination = output_dir / item.filename
        if destination.exists() and not force:
            raise FileExistsError(f"output exists: {destination}; pass --force to replace generated files")

        fd, temporary_name = tempfile.mkstemp(prefix=f".{item.filename}.", suffix=".tmp", dir=output_dir)
        os.close(fd)
        temporary = Path(temporary_name)
        try:
            communicate = edge_tts.Communicate(
                item.text,
                manifest["voice"],
                rate=manifest["rate"],
                volume=manifest["volume"],
                pitch=manifest["pitch"],
            )
            await communicate.save(str(temporary))
            if temporary.stat().st_size == 0:
                raise RuntimeError(f"service returned an empty file for {item.filename}")
            os.replace(temporary, destination)
            print(f"[{index:02d}/48] {destination.name}: {item.text}")
        finally:
            temporary.unlink(missing_ok=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=Path(__file__).with_name("manifest.json"))
    parser.add_argument("--output-dir", type=Path, default=Path(__file__).with_name("generated"))
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()

    try:
        manifest, plan = load_plan(args.manifest.resolve())
        print(f"Validated {len(plan)} announcements for voice {manifest['voice']}.")
        if not args.validate_only:
            print("Warning: Edge TTS requires the network and service output/availability can vary.", file=sys.stderr)
            asyncio.run(generate(manifest, plan, args.output_dir.resolve(), args.force))
    except Exception as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
