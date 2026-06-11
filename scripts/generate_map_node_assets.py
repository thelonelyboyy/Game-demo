#!/usr/bin/env python3
"""Generate readable map room badge textures for the Godot project."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "game-demo" / "art" / "map" / "nodes"
SIZE = 160
SCALE = 3


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    hex_color = hex_color.lstrip("#")
    return (
        int(hex_color[0:2], 16),
        int(hex_color[2:4], 16),
        int(hex_color[4:6], 16),
        alpha,
    )


def p(x: float, y: float) -> tuple[int, int]:
    return (round(x * SCALE), round(y * SCALE))


def box(cx: float, cy: float, r: float) -> tuple[int, int, int, int]:
    return (
        round((cx - r) * SCALE),
        round((cy - r) * SCALE),
        round((cx + r) * SCALE),
        round((cy + r) * SCALE),
    )


def line(draw: ImageDraw.ImageDraw, points: list[tuple[float, float]], fill, width: float, joint: str = "curve") -> None:
    draw.line([p(x, y) for x, y in points], fill=fill, width=round(width * SCALE), joint=joint)


def polygon(draw: ImageDraw.ImageDraw, points: list[tuple[float, float]], fill, outline=None, width: float = 1.0) -> None:
    draw.polygon([p(x, y) for x, y in points], fill=fill, outline=outline)
    if outline:
        closed = points + [points[0]]
        line(draw, closed, outline, width)


def ellipse(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, fill, outline=None, width: float = 1.0) -> None:
    draw.ellipse(box(cx, cy, r), fill=fill, outline=outline, width=round(width * SCALE))


def arc(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, start: float, end: float, fill, width: float) -> None:
    draw.arc(box(cx, cy, r), start=start, end=end, fill=fill, width=round(width * SCALE))


def make_badge(name: str, palette: dict[str, str], draw_icon) -> None:
    canvas = Image.new("RGBA", (SIZE * SCALE, SIZE * SCALE), (0, 0, 0, 0))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(
        (
            round(27 * SCALE),
            round(31 * SCALE),
            round(137 * SCALE),
            round(141 * SCALE),
        ),
        fill=(0, 0, 0, 130),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(5 * SCALE))
    canvas.alpha_composite(shadow)

    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse(box(80, 77, 55), fill=rgba(palette["glow"], 72))
    glow = glow.filter(ImageFilter.GaussianBlur(7 * SCALE))
    canvas.alpha_composite(glow)

    draw = ImageDraw.Draw(canvas)
    ellipse(draw, 80, 75, 50, rgba("#1a1813", 255))
    ellipse(draw, 80, 75, 45, rgba(palette["rim_dark"], 255))
    ellipse(draw, 80, 75, 39, rgba(palette["rim"], 255))
    ellipse(draw, 80, 75, 32, rgba(palette["face"], 255))
    ellipse(draw, 80, 75, 26, rgba(palette["inner"], 255), rgba("#1b1712", 185), 2.2)
    arc(draw, 80, 75, 42, 205, 340, rgba("#fff4bf", 84), 3.0)
    arc(draw, 80, 75, 36, 25, 155, rgba("#000000", 86), 2.5)

    draw_icon(draw, rgba(palette["icon"], 255), rgba("#211c16", 210), rgba("#fff6d3", 190))

    image = canvas.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    image.save(OUT_DIR / f"{name}.png")


def icon_unknown(draw: ImageDraw.ImageDraw, icon, dark, light) -> None:
    arc(draw, 80, 66, 17, 205, 520, icon, 8)
    line(draw, [(85, 80), (78, 91)], icon, 7)
    ellipse(draw, 77, 104, 4.5, icon)
    arc(draw, 80, 66, 19, 205, 520, dark, 2)


def icon_shop(draw: ImageDraw.ImageDraw, icon, dark, light) -> None:
    line(draw, [(60, 51), (60, 107)], dark, 6)
    ellipse(draw, 60, 49, 5, light, dark, 1.5)
    ellipse(draw, 78, 51, 10, light, dark, 2)
    polygon(draw, [(67, 66), (93, 63), (103, 104), (59, 104)], icon, dark, 2.4)
    line(draw, [(70, 77), (93, 98)], dark, 3)
    draw.rounded_rectangle(
        (round(93 * SCALE), round(74 * SCALE), round(111 * SCALE), round(98 * SCALE)),
        radius=round(6 * SCALE),
        fill=light,
        outline=dark,
        width=round(2 * SCALE),
    )
    line(draw, [(66, 105), (101, 105)], dark, 5)


def icon_treasure(draw: ImageDraw.ImageDraw, icon, dark, light) -> None:
    # Open treasure casket: wider silhouette and gold/cyan contrast for fast map scanning.
    polygon(draw, [(55, 67), (105, 67), (112, 92), (48, 92)], rgba("#372414", 245), dark, 2.4)
    polygon(draw, [(56, 42), (102, 55), (98, 72), (50, 59)], icon, dark, 2.6)
    polygon(draw, [(61, 49), (95, 58), (92, 64), (58, 56)], light, None)
    polygon(draw, [(51, 76), (109, 76), (104, 108), (56, 108)], icon, dark, 3.2)
    draw.rounded_rectangle(
        (round(58 * SCALE), round(81 * SCALE), round(102 * SCALE), round(101 * SCALE)),
        radius=round(4 * SCALE),
        fill=rgba("#7b4b20", 255),
        outline=dark,
        width=round(2 * SCALE),
    )
    line(draw, [(80, 77), (80, 107)], dark, 3)
    draw.rounded_rectangle(
        (round(73 * SCALE), round(84 * SCALE), round(87 * SCALE), round(98 * SCALE)),
        radius=round(3 * SCALE),
        fill=rgba("#f7e7b0", 255),
        outline=dark,
        width=round(1.5 * SCALE),
    )
    polygon(draw, [(60, 80), (72, 87), (61, 94)], rgba("#f4cf64", 210), None)
    polygon(draw, [(100, 80), (88, 87), (99, 94)], rgba("#f4cf64", 210), None)
    ellipse(draw, 67, 62, 3.0, rgba("#dffcff", 245))
    ellipse(draw, 82, 56, 3.6, rgba("#dffcff", 245))
    ellipse(draw, 96, 66, 2.8, rgba("#dffcff", 245))


def icon_campfire(draw: ImageDraw.ImageDraw, icon, dark, light) -> None:
    polygon(draw, [(80, 37), (101, 75), (91, 106), (69, 106), (58, 76)], icon, dark, 2.2)
    polygon(draw, [(80, 53), (90, 78), (81, 96), (70, 80)], light, None)
    line(draw, [(55, 109), (106, 91)], dark, 6)
    line(draw, [(54, 91), (107, 110)], dark, 6)
    line(draw, [(55, 109), (106, 91)], icon, 2.5)
    line(draw, [(54, 91), (107, 110)], icon, 2.5)


def icon_monster(draw: ImageDraw.ImageDraw, icon, dark, light) -> None:
    polygon(draw, [(48, 48), (67, 62), (56, 77)], icon, dark, 2.5)
    polygon(draw, [(112, 48), (93, 62), (104, 77)], icon, dark, 2.5)
    ellipse(draw, 80, 79, 29, icon, dark, 4)
    polygon(draw, [(60, 78), (74, 70), (72, 89)], dark)
    polygon(draw, [(100, 78), (86, 70), (88, 89)], dark)
    polygon(draw, [(74, 93), (80, 101), (86, 93)], dark)
    line(draw, [(59, 101), (69, 112), (79, 101), (90, 112), (101, 101)], light, 5)
    arc(draw, 80, 78, 35, 210, 330, dark, 4)


def icon_elite(draw: ImageDraw.ImageDraw, icon, dark, light) -> None:
    polygon(draw, [(43, 50), (67, 61), (55, 81)], icon, dark, 3)
    polygon(draw, [(117, 50), (93, 61), (105, 81)], icon, dark, 3)
    ellipse(draw, 80, 79, 32, icon, dark, 4)
    polygon(draw, [(58, 78), (75, 69), (72, 91)], dark)
    polygon(draw, [(102, 78), (85, 69), (88, 91)], dark)
    polygon(draw, [(73, 95), (80, 104), (87, 95)], dark)
    line(draw, [(57, 102), (68, 114), (79, 102), (91, 114), (103, 102)], light, 5)
    arc(draw, 80, 78, 38, 205, 335, dark, 5)


def icon_boss(draw: ImageDraw.ImageDraw, icon, dark, light) -> None:
    polygon(draw, [(80, 37), (101, 70), (95, 103), (65, 103), (59, 70)], icon, dark, 3)
    polygon(draw, [(80, 55), (91, 73), (86, 94), (74, 94), (69, 73)], light, dark, 1.4)
    line(draw, [(57, 106), (103, 106)], dark, 7)
    line(draw, [(63, 113), (97, 113)], dark, 5)


def icon_blessing(draw: ImageDraw.ImageDraw, icon, dark, light) -> None:
    for angle in range(0, 360, 45):
        r1, r2 = 9, 31
        rad = math.radians(angle)
        line(
            draw,
            [(80 + math.cos(rad) * r1, 76 + math.sin(rad) * r1), (80 + math.cos(rad) * r2, 76 + math.sin(rad) * r2)],
            icon,
            6,
        )
    ellipse(draw, 80, 76, 13, light, dark, 2)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    palettes = {
        "map_node_unknown": {"rim_dark": "#6e5627", "rim": "#9c8044", "face": "#715d35", "inner": "#8a7242", "icon": "#f2e4c4", "glow": "#d7b36c"},
        "map_node_shop": {"rim_dark": "#4b5b27", "rim": "#7f8a3c", "face": "#506425", "inner": "#6f7c30", "icon": "#efecc3", "glow": "#98bd4b"},
        "map_node_treasure": {"rim_dark": "#6a4c17", "rim": "#d1a746", "face": "#745321", "inner": "#b0812f", "icon": "#f1bf4f", "glow": "#f4cf64"},
        "map_node_campfire": {"rim_dark": "#6e2d24", "rim": "#b44d37", "face": "#7f332b", "inner": "#9f4732", "icon": "#ffe6bc", "glow": "#e4653f"},
        "map_node_monster": {"rim_dark": "#5a4a35", "rim": "#8b7651", "face": "#6b5d47", "inner": "#827254", "icon": "#ede1c8", "glow": "#a99161"},
        "map_node_elite": {"rim_dark": "#5a2f55", "rim": "#9b5c92", "face": "#6d3e69", "inner": "#85517d", "icon": "#f0d7ee", "glow": "#c072bc"},
        "map_node_boss": {"rim_dark": "#552218", "rim": "#9f4228", "face": "#713024", "inner": "#8e3b28", "icon": "#ffe0bd", "glow": "#e05c38"},
        "map_node_blessing": {"rim_dark": "#3f6070", "rim": "#8bd9ef", "face": "#548ba0", "inner": "#75c6db", "icon": "#effcff", "glow": "#98efff"},
    }
    make_badge("map_node_unknown", palettes["map_node_unknown"], icon_unknown)
    make_badge("map_node_shop", palettes["map_node_shop"], icon_shop)
    make_badge("map_node_treasure", palettes["map_node_treasure"], icon_treasure)
    make_badge("map_node_campfire", palettes["map_node_campfire"], icon_campfire)
    make_badge("map_node_monster", palettes["map_node_monster"], icon_monster)
    make_badge("map_node_elite", palettes["map_node_elite"], icon_elite)
    make_badge("map_node_boss", palettes["map_node_boss"], icon_boss)
    make_badge("map_node_blessing", palettes["map_node_blessing"], icon_blessing)


if __name__ == "__main__":
    main()
