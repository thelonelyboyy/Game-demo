from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(r"E:\code\game-demo\game-demo")
CHROMA_HELPER = Path(
    r"C:\Users\Administrator\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py"
)


def fit_alpha_png(
    src: Path,
    out: Path,
    size: tuple[int, int],
    padding: int,
    stretch: bool,
    align: str,
) -> None:
    im = Image.open(src).convert("RGBA")
    alpha = im.getchannel("A")
    bbox = alpha.getbbox()
    if not bbox:
        raise RuntimeError(f"empty alpha after key removal: {src}")

    asset = im.crop(bbox)
    max_w = max(1, size[0] - padding * 2)
    max_h = max(1, size[1] - padding * 2)
    if stretch:
        fit_size = (max_w, max_h)
    else:
        scale = min(max_w / asset.width, max_h / asset.height)
        fit_size = (max(1, round(asset.width * scale)), max(1, round(asset.height * scale)))
    asset = asset.resize(fit_size, Image.Resampling.LANCZOS)

    positions = {
        "center": ((size[0] - fit_size[0]) // 2, (size[1] - fit_size[1]) // 2),
        "top-left": (padding, padding),
        "top-right": (size[0] - fit_size[0] - padding, padding),
        "bottom-left": (padding, size[1] - fit_size[1] - padding),
        "bottom-right": (size[0] - fit_size[0] - padding, size[1] - fit_size[1] - padding),
    }
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.alpha_composite(asset, positions[align])
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--category", required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("--width", required=True, type=int)
    parser.add_argument("--height", required=True, type=int)
    parser.add_argument("--candidate", default="a")
    parser.add_argument("--padding", default=6, type=int)
    parser.add_argument("--stretch", action="store_true")
    parser.add_argument(
        "--align",
        default="center",
        choices=["center", "top-left", "top-right", "bottom-left", "bottom-right"],
    )
    args = parser.parse_args()

    work_dir = ROOT / "art" / "tmp" / "imagegen_batch67"
    work_dir.mkdir(parents=True, exist_ok=True)
    source_copy = work_dir / f"{args.name}__candidate_{args.candidate}_source.png"
    alpha_png = work_dir / f"{args.name}__candidate_{args.candidate}_alpha.png"
    shutil.copy2(args.source, source_copy)

    subprocess.run(
        [
            sys.executable,
            str(CHROMA_HELPER),
            "--input",
            str(source_copy),
            "--out",
            str(alpha_png),
            "--auto-key",
            "border",
            "--soft-matte",
            "--transparent-threshold",
            "12",
            "--opaque-threshold",
            "220",
            "--despill",
            "--force",
        ],
        check=True,
    )

    out_dir = ROOT / "assets" / "ui" / "generated" / args.category
    candidate_out = out_dir / f"{args.name}__candidate_{args.candidate}.png"
    final_out = out_dir / f"{args.name}.png"
    fit_alpha_png(
        alpha_png,
        candidate_out,
        (args.width, args.height),
        args.padding,
        args.stretch,
        args.align,
    )
    shutil.copy2(candidate_out, final_out)

    im = Image.open(final_out).convert("RGBA")
    corners = [
        im.getchannel("A").getpixel((0, 0)),
        im.getchannel("A").getpixel((im.width - 1, 0)),
        im.getchannel("A").getpixel((0, im.height - 1)),
        im.getchannel("A").getpixel((im.width - 1, im.height - 1)),
    ]
    print(f"saved {final_out} size={im.size} mode={im.mode} corners={corners}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
