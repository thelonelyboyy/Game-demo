from __future__ import annotations

import argparse
import math
import re
import shutil
from collections import deque
from pathlib import Path

from PIL import Image, ImageFilter

ART_REF_RE = re.compile(r'\[ext_resource type="Texture2D" path="(res://art/[^\"]+\.png)"')


def res_path_to_file(project_dir: Path, res_path: str) -> Path:
    if not res_path.startswith("res://"):
        raise ValueError(f"Unsupported resource path: {res_path}")
    return project_dir / res_path.removeprefix("res://")


def find_enemy_art(project_dir: Path) -> list[Path]:
    paths: set[Path] = set()
    for tres in (project_dir / "enemies").rglob("*.tres"):
        text = tres.read_text(encoding="utf-8", errors="ignore")
        for match in ART_REF_RE.finditer(text):
            paths.add(res_path_to_file(project_dir, match.group(1)))
    return sorted(paths)


def has_existing_transparency(img: Image.Image) -> bool:
    if img.mode not in ("RGBA", "LA") and "transparency" not in img.info:
        return False
    alpha = img.convert("RGBA").getchannel("A")
    return alpha.getextrema()[0] < 255


def estimate_background(img: Image.Image, patch: int = 48) -> tuple[int, int, int]:
    w, h = img.size
    patch = max(1, min(patch, h // 4, w // 4))
    samples: list[tuple[int, int, int]] = []
    regions = [
        (0, 0, patch, patch),
        (w - patch, 0, w, patch),
        (0, h - patch, patch, h),
        (w - patch, h - patch, w, h),
    ]
    for box in regions:
        for rgba in img.crop(box).getdata():
            samples.append((rgba[0], rgba[1], rgba[2]))
    samples.sort()
    return samples[len(samples) // 2]


def connected_background_mask(close: bytearray, w: int, h: int) -> bytearray:
    visited = bytearray(w * h)
    q: deque[int] = deque()

    def add_seed(idx: int) -> None:
        if close[idx] and not visited[idx]:
            visited[idx] = 1
            q.append(idx)

    for x in range(w):
        add_seed(x)
        add_seed((h - 1) * w + x)
    for y in range(h):
        add_seed(y * w)
        add_seed(y * w + (w - 1))

    while q:
        idx = q.popleft()
        y, x = divmod(idx, w)
        if y > 0:
            n = idx - w
            if close[n] and not visited[n]:
                visited[n] = 1
                q.append(n)
        if y + 1 < h:
            n = idx + w
            if close[n] and not visited[n]:
                visited[n] = 1
                q.append(n)
        if x > 0:
            n = idx - 1
            if close[n] and not visited[n]:
                visited[n] = 1
                q.append(n)
        if x + 1 < w:
            n = idx + 1
            if close[n] and not visited[n]:
                visited[n] = 1
                q.append(n)
    return visited


def remove_flat_background(
    image_path: Path,
    backup_dir: Path,
    low: float,
    high: float,
    blur_radius: float,
    dry_run: bool,
) -> dict[str, object]:
    img = Image.open(image_path).convert("RGBA")
    w, h = img.size
    if has_existing_transparency(img):
        return {"path": str(image_path), "status": "skip-transparent", "size": f"{w}x{h}"}
    if min(w, h) < 900:
        return {"path": str(image_path), "status": "skip-small", "size": f"{w}x{h}"}

    pixels = img.load()
    bg = estimate_background(img)
    bg_r, bg_g, bg_b = bg
    dist2_high = high * high
    close = bytearray(w * h)

    for y in range(h):
        row_base = y * w
        for x in range(w):
            r, g, b, _a = pixels[x, y]
            dr = r - bg_r
            dg = g - bg_g
            db = b - bg_b
            if dr * dr + dg * dg + db * db <= dist2_high:
                close[row_base + x] = 1

    bg_mask = connected_background_mask(close, w, h)
    alpha = Image.new("L", (w, h), 255)
    alpha_pixels = alpha.load()
    denom = max(1.0, high - low)

    for y in range(h):
        row_base = y * w
        for x in range(w):
            idx = row_base + x
            if not bg_mask[idx]:
                continue
            r, g, b, _a = pixels[x, y]
            dr = r - bg_r
            dg = g - bg_g
            db = b - bg_b
            dist = math.sqrt(dr * dr + dg * dg + db * db)
            alpha_pixels[x, y] = int(max(0.0, min(1.0, (dist - low) / denom)) * 255.0)

    if blur_radius > 0:
        alpha = alpha.filter(ImageFilter.GaussianBlur(blur_radius))
    alpha_pixels = alpha.load()
    for y in range(h):
        row_base = y * w
        for x in range(w):
            idx = row_base + x
            if not bg_mask[idx]:
                alpha_pixels[x, y] = 255
            elif alpha_pixels[x, y] < 8:
                alpha_pixels[x, y] = 0

    transparent_pixels = 0
    partial_pixels = 0
    for y in range(h):
        for x in range(w):
            value = alpha_pixels[x, y]
            if value < 8:
                transparent_pixels += 1
            elif value < 250:
                partial_pixels += 1

    if not dry_run:
        backup_dir.mkdir(parents=True, exist_ok=True)
        backup_path = backup_dir / image_path.name
        if not backup_path.exists():
            shutil.copy2(image_path, backup_path)
        out = img.copy()
        out.putalpha(alpha)
        out.save(image_path)

    return {
        "path": str(image_path),
        "status": "processed" if not dry_run else "would-process",
        "size": f"{w}x{h}",
        "background": bg,
        "transparent_pixels": transparent_pixels,
        "partial_pixels": partial_pixels,
    }


def make_preview(paths: list[Path], output: Path) -> None:
    thumbs: list[Image.Image] = []
    cell = 220
    checker = Image.new("RGB", (cell, cell), "white")
    tile = 20
    pix = checker.load()
    for y in range(cell):
        for x in range(cell):
            if ((x // tile) + (y // tile)) % 2:
                pix[x, y] = (210, 210, 210)
    for path in paths:
        img = Image.open(path).convert("RGBA")
        img.thumbnail((cell - 16, cell - 16), Image.Resampling.LANCZOS)
        canvas = checker.copy().convert("RGBA")
        x = (cell - img.width) // 2
        y = (cell - img.height) // 2
        canvas.alpha_composite(img, (x, y))
        thumbs.append(canvas.convert("RGB"))

    cols = 5
    rows = (len(thumbs) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cell, rows * cell), "white")
    for i, thumb in enumerate(thumbs):
        sheet.paste(thumb, ((i % cols) * cell, (i // cols) * cell))
    sheet.save(output, quality=92)


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert fake enemy PNG backgrounds to real alpha.")
    parser.add_argument("--project-dir", default="game-demo")
    parser.add_argument("--low", type=float, default=18.0)
    parser.add_argument("--high", type=float, default=72.0)
    parser.add_argument("--blur-radius", type=float, default=0.75)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--preview", default="enemy_preview_after.jpg")
    args = parser.parse_args()

    project_dir = Path(args.project_dir).resolve()
    backup_dir = project_dir / "art" / "_alpha_backup"
    art_paths = [path for path in find_enemy_art(project_dir) if path.exists()]

    results = [
        remove_flat_background(path, backup_dir, args.low, args.high, args.blur_radius, args.dry_run)
        for path in art_paths
    ]

    processed_paths = [Path(result["path"]) for result in results if result["status"] in {"processed", "would-process"}]
    if processed_paths and not args.dry_run:
        make_preview(processed_paths, Path(args.preview).resolve())

    for result in results:
        bits = [result["status"], result["size"], result["path"]]
        if "background" in result:
            bits.append(f"bg={result['background']}")
            bits.append(f"transparent={result['transparent_pixels']}")
            bits.append(f"partial={result['partial_pixels']}")
        print(" | ".join(str(bit) for bit in bits))


if __name__ == "__main__":
    main()
