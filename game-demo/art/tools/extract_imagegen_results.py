#!/usr/bin/env python3
"""Extract Codex Desktop image_gen results from the local session JSONL.

Codex Desktop currently records generated image bytes in session history as
base64 under image_generation_* payloads. This utility makes those images
usable as project assets when they are not mirrored into generated_images.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
from dataclasses import dataclass
from pathlib import Path


@dataclass
class GeneratedImage:
    line: int
    timestamp: str
    call_id: str
    prompt: str
    ext: str
    data: bytes


def default_codex_home() -> Path:
    return Path(os.environ.get("CODEX_HOME") or Path.home() / ".codex")


def find_session_file(codex_home: Path, explicit: str | None) -> Path:
    if explicit:
        path = Path(explicit)
        if not path.is_file():
            raise FileNotFoundError(f"Session file not found: {path}")
        return path

    thread_id = os.environ.get("CODEX_THREAD_ID")
    sessions_root = codex_home / "sessions"
    candidates = []
    if thread_id:
        candidates.extend(sessions_root.glob(f"**/*{thread_id}.jsonl"))
    if not candidates:
        candidates.extend(sessions_root.glob("**/*.jsonl"))
    if not candidates:
        raise FileNotFoundError(f"No Codex session JSONL files under {sessions_root}")
    return max(candidates, key=lambda p: p.stat().st_mtime)


def decode_result(result: object) -> tuple[bytes, str]:
    if isinstance(result, dict):
        result = result.get("b64_json") or result.get("data") or result.get("image")
    if not isinstance(result, str) or not result:
        raise ValueError("empty image result")
    if result.startswith("data:"):
        result = result.split(",", 1)[1]

    data = base64.b64decode(result, validate=False)
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return data, "png"
    if data.startswith(b"\xff\xd8\xff"):
        return data, "jpg"
    if data.startswith(b"RIFF"):
        return data, "webp"
    return data, "bin"


def iter_generated_images(session_file: Path) -> list[GeneratedImage]:
    images: list[GeneratedImage] = []
    seen: set[tuple[str, int]] = set()

    with session_file.open("r", encoding="utf-8", errors="replace") as handle:
        for line_no, line in enumerate(handle, 1):
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue

            payload = obj.get("payload") or {}
            if payload.get("type") not in {"image_generation_call", "image_generation_end"}:
                continue

            result = payload.get("result")
            if not result:
                continue

            call_id = payload.get("id") or payload.get("call_id") or f"line-{line_no}"
            try:
                data, ext = decode_result(result)
            except ValueError:
                continue

            key = (call_id, len(data))
            if key in seen:
                continue
            seen.add(key)

            images.append(
                GeneratedImage(
                    line=line_no,
                    timestamp=obj.get("timestamp") or "",
                    call_id=call_id,
                    prompt=(payload.get("revised_prompt") or "").strip(),
                    ext=ext,
                    data=data,
                )
            )

    return images


def write_image(image: GeneratedImage, destination: Path) -> Path:
    if destination.suffix:
        out_path = destination
    else:
        out_path = destination.with_suffix(f".{image.ext}")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(image.data)
    return out_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--session", help="Specific Codex session JSONL file.")
    parser.add_argument("--codex-home", default=str(default_codex_home()))
    parser.add_argument("--latest-out", help="Write only the newest generated image to this path.")
    parser.add_argument("--all-dir", help="Extract every generated image into this directory.")
    parser.add_argument("--list", action="store_true", help="List generated images found.")
    args = parser.parse_args()

    session_file = find_session_file(Path(args.codex_home), args.session)
    images = iter_generated_images(session_file)
    print(f"session={session_file}")
    print(f"images={len(images)}")

    if args.list or (not args.latest_out and not args.all_dir):
        for image in images:
            prompt = image.prompt.replace("\n", " ")[:100]
            print(f"{image.line}\t{image.timestamp}\t{image.ext}\t{len(image.data)}\t{image.call_id}\t{prompt}")

    if args.all_dir:
        out_dir = Path(args.all_dir)
        for image in images:
            name = f"{image.line:04d}_{image.call_id[-12:]}.{image.ext}"
            path = write_image(image, out_dir / name)
            print(f"wrote={path}")

    if args.latest_out:
        if not images:
            raise RuntimeError("No generated images found in the session.")
        path = write_image(images[-1], Path(args.latest_out))
        print(f"latest={images[-1].line}\nwrote={path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
