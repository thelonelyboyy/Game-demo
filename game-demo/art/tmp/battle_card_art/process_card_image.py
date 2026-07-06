from __future__ import annotations

import argparse
import shutil
from pathlib import Path

from PIL import Image


ROOT = Path(r"E:\code\game-demo\game-demo")
OUT_DIR = ROOT / "art" / "ui" / "battle_cards"
WORK_DIR = ROOT / "art" / "tmp" / "battle_card_art"
TARGET_SIZE = (1024, 1536)


def cover_resize(im: Image.Image, size: tuple[int, int]) -> Image.Image:
    src_w, src_h = im.size
    dst_w, dst_h = size
    scale = max(dst_w / src_w, dst_h / src_h)
    fit = (round(src_w * scale), round(src_h * scale))
    resized = im.resize(fit, Image.Resampling.LANCZOS)
    left = max(0, (resized.width - dst_w) // 2)
    top = max(0, (resized.height - dst_h) // 2)
    return resized.crop((left, top, left + dst_w, top + dst_h))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--name", required=True)
    args = parser.parse_args()

    WORK_DIR.mkdir(parents=True, exist_ok=True)
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    source_copy = WORK_DIR / f"{args.name}__imagegen_source.png"
    shutil.copy2(args.source, source_copy)

    im = Image.open(source_copy).convert("RGB")
    final = cover_resize(im, TARGET_SIZE)
    out = OUT_DIR / f"{args.name}.png"
    final.save(out)
    print(f"saved {out} size={final.size} mode={final.mode}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
