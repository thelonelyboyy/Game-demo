#!/usr/bin/env python3
"""Copy the newest Codex Desktop generated image for this thread."""

from __future__ import annotations

import argparse
import os
import shutil
from pathlib import Path


def default_codex_home() -> Path:
    return Path(os.environ.get("CODEX_HOME") or Path.home() / ".codex")


def latest_image(thread_id: str | None, codex_home: Path) -> Path:
    root = codex_home / "generated_images"
    if thread_id:
        candidates = list((root / thread_id).glob("*.png"))
    else:
        candidates = list(root.glob("**/*.png"))
    if not candidates:
        raise FileNotFoundError(f"No generated PNGs found under {root}")
    return max(candidates, key=lambda p: p.stat().st_mtime)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", help="Workspace destination PNG path.")
    parser.add_argument("--thread-id", default=os.environ.get("CODEX_THREAD_ID"))
    parser.add_argument("--codex-home", default=str(default_codex_home()))
    args = parser.parse_args()

    src = latest_image(args.thread_id, Path(args.codex_home))
    dst = Path(args.destination)
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    print(f"source={src}")
    print(f"copied={dst}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
