from __future__ import annotations

import argparse
import shutil
from pathlib import Path

from PIL import Image


ROOT = Path(r"E:\code\game-demo\game-demo")
CARD_DIR = ROOT / "art" / "cards" / "demonic_cultivator" / "ai"
WORK_DIR = ROOT / "art" / "tmp" / "demonic_cultivator_ai_rebuild"


def cover_resize(im: Image.Image, size: tuple[int, int]) -> Image.Image:
    src_w, src_h = im.size
    dst_w, dst_h = size
    scale = max(dst_w / src_w, dst_h / src_h)
    fit_size = (round(src_w * scale), round(src_h * scale))
    resized = im.resize(fit_size, Image.Resampling.LANCZOS)
    left = max(0, (resized.width - dst_w) // 2)
    top = max(0, (resized.height - dst_h) // 2)
    return resized.crop((left, top, left + dst_w, top + dst_h))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--name", required=True)
    args = parser.parse_args()

    target = CARD_DIR / args.name
    if not target.exists():
        raise FileNotFoundError(target)

    WORK_DIR.mkdir(parents=True, exist_ok=True)
    source_copy = WORK_DIR / f"{target.stem}__imagegen_source.png"
    shutil.copy2(args.source, source_copy)

    target_size = Image.open(target).size
    im = Image.open(source_copy).convert("RGB")
    out = cover_resize(im, target_size)
    out.save(target)
    print(f"saved {target} size={out.size} mode={out.mode}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
