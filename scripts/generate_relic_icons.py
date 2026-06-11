#!/usr/bin/env python3
"""Generate distinctive xianxia relic icons and wire them into relic resources."""

from __future__ import annotations

import math
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
RELIC_DIR = ROOT / "game-demo" / "relics"
OUT_DIR = ROOT / "game-demo" / "art" / "relics" / "icons"
SIZE = 96
SCALE = 4


PALETTES = {
    "all": ("#16383c", "#c49a43", "#f1d184", "#79d8d6"),
    "body": ("#30342f", "#d0aa52", "#ffe2a0", "#b7c0ae"),
    "sword": ("#1c3548", "#8fd5e8", "#ecf9ff", "#d2b66a"),
    "demonic": ("#3b1b2b", "#c44f55", "#ffe0c2", "#9b5cd2"),
    "beast": ("#223923", "#8fbd58", "#f3e6b4", "#d48a44"),
    "fire": ("#3e2418", "#dc6a31", "#ffe0a0", "#f0bf4f"),
    "water": ("#173648", "#6fb2d8", "#e6fbff", "#b7d7ea"),
    "wood": ("#1f3d2a", "#79b66a", "#eef6c8", "#c3924a"),
    "metal": ("#343334", "#d4be69", "#fff1be", "#9fd7d2"),
}

CHARACTER_PALETTE = {
    "body_": "body",
    "sword_": "sword",
    "demon_": "demonic",
    "ghost_": "demonic",
    "blood_": "demonic",
    "beast_": "beast",
    "pack_": "beast",
}


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    hex_color = hex_color.lstrip("#")
    return (
        int(hex_color[0:2], 16),
        int(hex_color[2:4], 16),
        int(hex_color[4:6], 16),
        alpha,
    )


def p(x: float, y: float) -> tuple[int, int]:
    return round(x * SCALE), round(y * SCALE)


def rect(x1: float, y1: float, x2: float, y2: float) -> tuple[int, int, int, int]:
    return round(x1 * SCALE), round(y1 * SCALE), round(x2 * SCALE), round(y2 * SCALE)


def line(draw: ImageDraw.ImageDraw, points: list[tuple[float, float]], fill, width: float = 2.0) -> None:
    draw.line([p(x, y) for x, y in points], fill=fill, width=round(width * SCALE), joint="curve")


def poly(draw: ImageDraw.ImageDraw, points: list[tuple[float, float]], fill, outline=None, width: float = 1.5) -> None:
    draw.polygon([p(x, y) for x, y in points], fill=fill)
    if outline:
        line(draw, points + [points[0]], outline, width)


def ellipse(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    rx: float,
    ry: float,
    fill,
    outline=None,
    width: float = 1.5,
) -> None:
    draw.ellipse(rect(cx - rx, cy - ry, cx + rx, cy + ry), fill=fill, outline=outline, width=round(width * SCALE))


def rounded(draw: ImageDraw.ImageDraw, xy, radius: float, fill, outline=None, width: float = 1.5) -> None:
    draw.rounded_rectangle(
        tuple(round(v * SCALE) for v in xy),
        radius=round(radius * SCALE),
        fill=fill,
        outline=outline,
        width=round(width * SCALE),
    )


def arc(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, start: float, end: float, fill, width: float = 2.0) -> None:
    draw.arc(rect(cx - r, cy - r, cx + r, cy + r), start, end, fill=fill, width=round(width * SCALE))


def star(draw: ImageDraw.ImageDraw, cx: float, cy: float, r_outer: float, r_inner: float, fill, outline=None) -> None:
    pts: list[tuple[float, float]] = []
    for i in range(10):
        angle = math.radians(-90 + i * 36)
        radius = r_outer if i % 2 == 0 else r_inner
        pts.append((cx + math.cos(angle) * radius, cy + math.sin(angle) * radius))
    poly(draw, pts, fill, outline, 1.2)


def make_canvas(bg: str, rim: str) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    canvas = Image.new("RGBA", (SIZE * SCALE, SIZE * SCALE), (0, 0, 0, 0))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(rect(12, 14, 86, 88), fill=(0, 0, 0, 118))
    shadow = shadow.filter(ImageFilter.GaussianBlur(4 * SCALE))
    canvas.alpha_composite(shadow)

    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse(rect(12, 10, 84, 82), fill=rgba(rim, 54))
    glow = glow.filter(ImageFilter.GaussianBlur(5 * SCALE))
    canvas.alpha_composite(glow)

    draw = ImageDraw.Draw(canvas)
    ellipse(draw, 48, 46, 37, 37, rgba("#101214", 245))
    ellipse(draw, 48, 46, 33, 33, rgba(rim, 245))
    ellipse(draw, 48, 46, 27, 27, rgba(bg, 255), rgba("#0a0c0d", 210), 1.7)
    arc(draw, 48, 46, 30, 205, 330, rgba("#fff3bc", 82), 2.0)
    return canvas, draw


def palette_for(relic_id: str) -> tuple[str, str, str, str]:
    for prefix, key in CHARACTER_PALETTE.items():
        if relic_id.startswith(prefix):
            return PALETTES[key]
    if "fire" in relic_id or "ember" in relic_id or "thunder" in relic_id or "explosive" in relic_id:
        return PALETTES["fire"]
    if "water" in relic_id or "spring" in relic_id or "moon" in relic_id:
        return PALETTES["water"]
    if "wood" in relic_id:
        return PALETTES["wood"]
    if "metal" in relic_id or "gold" in relic_id:
        return PALETTES["metal"]
    return PALETTES["all"]


def draw_bell(draw, fg, dark, hi, accent):
    poly(draw, [(34, 57), (62, 57), (57, 28), (39, 28)], fg, dark, 2.2)
    ellipse(draw, 48, 61, 17, 7, fg, dark, 2)
    ellipse(draw, 48, 68, 4, 4, accent, dark, 1)
    line(draw, [(48, 22), (48, 30)], hi, 2)


def draw_whistle(draw, fg, dark, hi, accent):
    rounded(draw, (27, 43, 69, 55), 6, fg, dark, 2)
    poly(draw, [(68, 44), (78, 49), (68, 55)], fg, dark, 2)
    ellipse(draw, 42, 49, 4, 4, accent, dark, 1)
    line(draw, [(32, 39), (43, 30), (52, 38)], hi, 2)


def draw_totem(draw, fg, dark, hi, accent):
    rounded(draw, (34, 22, 62, 72), 6, fg, dark, 2.4)
    poly(draw, [(30, 34), (40, 27), (39, 42)], accent, dark, 1.5)
    poly(draw, [(66, 34), (56, 27), (57, 42)], accent, dark, 1.5)
    ellipse(draw, 42, 43, 4, 5, dark)
    ellipse(draw, 54, 43, 4, 5, dark)
    line(draw, [(41, 58), (48, 63), (56, 58)], hi, 2.2)


def draw_nest(draw, fg, dark, hi, accent):
    for y in [56, 61, 66]:
        arc(draw, 48, y, 25, 190, 350, fg if y != 61 else accent, 5)
    ellipse(draw, 42, 47, 7, 10, hi, dark, 1.2)
    ellipse(draw, 54, 46, 7, 10, accent, dark, 1.2)


def draw_blind_talisman(draw, fg, dark, hi, accent):
    rounded(draw, (36, 22, 60, 72), 4, hi, dark, 2)
    ellipse(draw, 48, 45, 14, 8, fg, dark, 1.8)
    ellipse(draw, 48, 45, 4, 4, dark)
    line(draw, [(32, 62), (64, 29)], accent, 4)


def draw_pendant(draw, fg, dark, hi, accent):
    poly(draw, [(48, 20), (67, 42), (58, 70), (38, 70), (29, 42)], fg, dark, 2.4)
    ellipse(draw, 48, 44, 10, 12, accent, dark, 1.5)
    line(draw, [(40, 27), (48, 20), (56, 27)], hi, 2)


def draw_seal(draw, fg, dark, hi, accent):
    rounded(draw, (30, 27, 66, 65), 6, fg, dark, 2.4)
    rounded(draw, (37, 34, 59, 56), 4, accent, dark, 1.4)
    line(draw, [(40, 45), (56, 45)], hi, 2)
    line(draw, [(48, 37), (48, 54)], hi, 2)


def draw_ember_seal(draw, fg, dark, hi, accent):
    rounded(draw, (31, 28, 65, 66), 6, fg, dark, 2.4)
    poly(draw, [(48, 34), (59, 50), (54, 64), (42, 64), (36, 50)], accent, dark, 1.5)
    poly(draw, [(48, 42), (53, 53), (48, 61), (42, 53)], hi, None)
    line(draw, [(37, 33), (59, 33)], hi, 1.7)


def draw_heart_seal(draw, fg, dark, hi, accent):
    rounded(draw, (31, 27, 65, 67), 7, fg, dark, 2.4)
    poly(draw, [(48, 62), (34, 46), (38, 36), (48, 40), (58, 36), (62, 46)], accent, dark, 1.6)
    line(draw, [(48, 31), (48, 67)], hi, 1.8)
    line(draw, [(39, 51), (57, 51)], hi, 1.8)


def draw_cloud_step(draw, fg, dark, hi, accent):
    arc(draw, 40, 49, 13, 180, 360, hi, 5)
    arc(draw, 55, 48, 16, 180, 360, hi, 5)
    line(draw, [(28, 50), (72, 50)], hi, 5)
    poly(draw, [(39, 32), (61, 38), (56, 51), (34, 46)], fg, dark, 2)
    line(draw, [(44, 40), (58, 44)], accent, 2)
    line(draw, [(37, 63), (59, 63)], accent, 2.5)


def draw_drum(draw, fg, dark, hi, accent):
    rounded(draw, (30, 35, 66, 61), 9, fg, dark, 2.3)
    ellipse(draw, 31, 48, 8, 14, hi, dark, 1.4)
    ellipse(draw, 65, 48, 8, 14, hi, dark, 1.4)
    line(draw, [(37, 35), (59, 61), (59, 35), (37, 61)], accent, 1.6)


def draw_charm(draw, fg, dark, hi, accent):
    rounded(draw, (36, 24, 60, 70), 4, fg, dark, 2)
    line(draw, [(42, 36), (54, 36), (45, 49), (55, 49)], hi, 2)
    line(draw, [(48, 22), (48, 16)], accent, 2)
    poly(draw, [(37, 70), (48, 62), (59, 70)], accent, dark, 1)


def draw_staff(draw, fg, dark, hi, accent):
    line(draw, [(36, 72), (56, 24)], fg, 6)
    line(draw, [(36, 72), (56, 24)], dark, 2)
    arc(draw, 60, 29, 11, 70, 320, accent, 4)
    ellipse(draw, 61, 29, 5, 5, hi, dark, 1)


def draw_tickets(draw, fg, dark, hi, accent):
    rounded(draw, (28, 35, 59, 65), 4, fg, dark, 1.8)
    rounded(draw, (39, 29, 70, 59), 4, hi, dark, 1.8)
    line(draw, [(46, 39), (62, 39)], accent, 2)
    line(draw, [(46, 49), (60, 49)], accent, 2)


def draw_mirror(draw, fg, dark, hi, accent):
    ellipse(draw, 48, 41, 18, 20, fg, dark, 2.5)
    ellipse(draw, 48, 41, 10, 12, hi, dark, 1.4)
    line(draw, [(48, 61), (48, 76)], dark, 5)
    line(draw, [(42, 71), (54, 71)], accent, 3)


def draw_dagger(draw, fg, dark, hi, accent):
    poly(draw, [(53, 19), (59, 24), (43, 61), (35, 64)], hi, dark, 2)
    line(draw, [(39, 61), (57, 72)], accent, 5)
    line(draw, [(33, 58), (48, 68)], dark, 3)
    ellipse(draw, 61, 21, 3, 3, accent)


def draw_barrel(draw, fg, dark, hi, accent):
    rounded(draw, (34, 29, 62, 68), 8, fg, dark, 2.3)
    line(draw, [(35, 39), (61, 39)], hi, 2)
    line(draw, [(35, 58), (61, 58)], hi, 2)
    poly(draw, [(49, 20), (59, 39), (50, 37), (55, 55), (38, 32), (48, 35)], accent, dark, 1.2)


def draw_book(draw, fg, dark, hi, accent):
    rounded(draw, (30, 26, 67, 68), 5, fg, dark, 2)
    line(draw, [(48, 29), (48, 66)], dark, 2)
    line(draw, [(36, 39), (44, 36)], hi, 1.6)
    line(draw, [(53, 39), (62, 36)], hi, 1.6)
    star(draw, 48, 52, 7, 3, accent, dark)


def draw_pearl(draw, fg, dark, hi, accent):
    ellipse(draw, 48, 47, 18, 18, fg, dark, 2.3)
    ellipse(draw, 42, 40, 5, 5, hi)
    poly(draw, [(48, 20), (56, 37), (48, 32), (40, 37)], accent, dark, 1.2)
    arc(draw, 48, 48, 25, 205, 335, accent, 3)


def draw_contract(draw, fg, dark, hi, accent):
    rounded(draw, (34, 22, 62, 70), 5, hi, dark, 2)
    line(draw, [(41, 35), (56, 35)], fg, 2)
    line(draw, [(40, 46), (57, 46)], fg, 2)
    ellipse(draw, 48, 61, 8, 6, accent, dark, 1)


def draw_bone_bead(draw, fg, dark, hi, accent):
    ellipse(draw, 48, 47, 15, 15, fg, dark, 2)
    ellipse(draw, 48, 47, 5, 5, dark)
    line(draw, [(28, 63), (38, 55), (58, 39), (70, 30)], hi, 5)
    line(draw, [(28, 63), (38, 55), (58, 39), (70, 30)], dark, 1.5)


def draw_gourd(draw, fg, dark, hi, accent):
    ellipse(draw, 48, 35, 11, 13, fg, dark, 2)
    ellipse(draw, 48, 57, 18, 19, fg, dark, 2)
    rounded(draw, (42, 19, 54, 29), 3, hi, dark, 1.4)
    line(draw, [(36, 56), (60, 56)], accent, 2)


def draw_spring_gourd(draw, fg, dark, hi, accent):
    draw_gourd(draw, fg, dark, hi, accent)
    arc(draw, 48, 60, 24, 25, 155, rgba("#dffcff", 230), 2)
    ellipse(draw, 61, 44, 4, 5, rgba("#dffcff", 235), dark, 1)


def draw_shield_talisman(draw, fg, dark, hi, accent):
    poly(draw, [(48, 23), (66, 32), (62, 60), (48, 73), (34, 60), (30, 32)], fg, dark, 2.4)
    rounded(draw, (40, 34, 56, 58), 3, hi, dark, 1.4)
    line(draw, [(48, 30), (48, 66)], accent, 2)


def draw_abacus(draw, fg, dark, hi, accent):
    rounded(draw, (28, 31, 68, 65), 4, fg, dark, 2.2)
    for y in [40, 50, 59]:
        line(draw, [(32, y), (64, y)], dark, 1.4)
    for x in [38, 48, 58]:
        ellipse(draw, x, 45, 3, 3, hi, dark, 1)
        ellipse(draw, x, 57, 3, 3, accent, dark, 1)


def draw_lotus_mirror(draw, fg, dark, hi, accent):
    ellipse(draw, 48, 42, 16, 17, hi, dark, 2)
    for dx in [-17, 0, 17]:
        poly(draw, [(48, 62), (48 + dx, 47), (48 + dx * 0.4, 70)], fg if dx else accent, dark, 1.4)
    line(draw, [(48, 58), (48, 75)], dark, 4)


def draw_ring(draw, fg, dark, hi, accent):
    ellipse(draw, 48, 47, 21, 21, fg, dark, 2.4)
    ellipse(draw, 48, 47, 11, 11, rgba("#000000", 0), dark, 2)
    poly(draw, [(48, 18), (55, 34), (48, 31), (41, 34)], hi, dark, 1.2)
    poly(draw, [(48, 76), (55, 60), (48, 63), (41, 60)], hi, dark, 1.2)


def draw_banner(draw, fg, dark, hi, accent):
    line(draw, [(36, 22), (36, 74)], dark, 4)
    poly(draw, [(38, 25), (66, 32), (57, 48), (66, 65), (38, 58)], fg, dark, 2)
    ellipse(draw, 50, 44, 6, 6, hi, dark, 1)


def draw_sword_box(draw, fg, dark, hi, accent):
    rounded(draw, (30, 32, 66, 66), 5, fg, dark, 2.2)
    line(draw, [(36, 58), (60, 34)], hi, 4)
    poly(draw, [(63, 31), (58, 43), (53, 38)], accent, dark, 1)
    line(draw, [(35, 40), (55, 60)], dark, 1.8)


def draw_armor(draw, fg, dark, hi, accent):
    poly(draw, [(35, 25), (61, 25), (68, 42), (61, 72), (35, 72), (28, 42)], fg, dark, 2.3)
    line(draw, [(48, 27), (48, 70)], hi, 2)
    line(draw, [(34, 45), (62, 45)], accent, 2)


def draw_lantern(draw, fg, dark, hi, accent):
    rounded(draw, (34, 31, 62, 66), 10, fg, dark, 2.2)
    ellipse(draw, 48, 49, 9, 12, accent, dark, 1)
    line(draw, [(40, 25), (56, 25), (61, 34)], hi, 2)
    line(draw, [(48, 66), (48, 76)], dark, 3)


def draw_compass(draw, fg, dark, hi, accent):
    ellipse(draw, 48, 47, 22, 22, fg, dark, 2.4)
    star(draw, 48, 47, 17, 5, hi, dark)
    ellipse(draw, 48, 47, 4, 4, accent, dark, 1)


def draw_scroll_sword(draw, fg, dark, hi, accent):
    rounded(draw, (30, 34, 62, 66), 5, hi, dark, 2)
    line(draw, [(38, 55), (63, 30)], accent, 4)
    poly(draw, [(66, 27), (61, 39), (56, 34)], fg, dark, 1)
    arc(draw, 36, 32, 9, 90, 270, hi, 3)


def draw_tally(draw, fg, dark, hi, accent):
    for x in [36, 44, 52, 60]:
        line(draw, [(x, 28), (x - 5, 68)], fg, 5)
        line(draw, [(x, 28), (x - 5, 68)], dark, 1)
    line(draw, [(31, 52), (63, 39)], accent, 4)


def draw_grindstone(draw, fg, dark, hi, accent):
    ellipse(draw, 46, 55, 19, 13, fg, dark, 2.2)
    line(draw, [(35, 30), (64, 65)], hi, 4)
    poly(draw, [(32, 26), (44, 34), (38, 39)], accent, dark, 1)


def draw_resonance(draw, fg, dark, hi, accent):
    poly(draw, [(48, 21), (62, 42), (48, 72), (34, 42)], fg, dark, 2.2)
    line(draw, [(48, 31), (48, 62)], hi, 3)
    arc(draw, 48, 47, 25, 125, 235, accent, 2.2)
    arc(draw, 48, 47, 31, 125, 235, accent, 1.8)


def draw_thunder(draw, fg, dark, hi, accent):
    rounded(draw, (34, 25, 62, 69), 6, fg, dark, 2)
    poly(draw, [(50, 29), (39, 49), (49, 49), (43, 68), (61, 43), (51, 43)], hi, dark, 1.5)


def draw_bottle_moon(draw, fg, dark, hi, accent):
    rounded(draw, (39, 26, 57, 68), 8, fg, dark, 2)
    line(draw, [(41, 42), (55, 42)], hi, 2)
    ellipse(draw, 49, 54, 9, 9, accent, dark, 1)
    ellipse(draw, 53, 50, 8, 8, fg)


def draw_tassel(draw, fg, dark, hi, accent):
    line(draw, [(38, 25), (58, 49)], hi, 4)
    poly(draw, [(61, 52), (55, 39), (50, 45)], fg, dark, 1)
    line(draw, [(58, 52), (48, 73)], accent, 3)
    line(draw, [(62, 51), (64, 73)], accent, 3)
    line(draw, [(54, 54), (34, 69)], accent, 3)


def draw_seed(draw, fg, dark, hi, accent):
    ellipse(draw, 48, 58, 14, 12, fg, dark, 2)
    line(draw, [(48, 58), (48, 34)], accent, 3)
    poly(draw, [(48, 39), (31, 31), (37, 50)], hi, dark, 1.2)
    poly(draw, [(48, 37), (66, 28), (61, 49)], hi, dark, 1.2)


def draw_wooden_sword(draw, fg, dark, hi, accent):
    line(draw, [(35, 70), (61, 26)], fg, 7)
    line(draw, [(35, 70), (61, 26)], dark, 2)
    line(draw, [(31, 55), (50, 66)], accent, 4)
    poly(draw, [(64, 22), (59, 36), (54, 31)], hi, dark, 1)


def draw_bone_amulet(draw, fg, dark, hi, accent):
    rounded(draw, (38, 28, 58, 68), 9, fg, dark, 2)
    ellipse(draw, 48, 40, 5, 5, dark)
    line(draw, [(38, 58), (58, 58)], hi, 3)
    poly(draw, [(48, 20), (55, 29), (41, 29)], accent, dark, 1)


MOTIFS = {
    "beast_bell": draw_bell,
    "beast_jade_whistle": draw_whistle,
    "beast_king_totem": draw_totem,
    "beast_life_nest": draw_nest,
    "blinding_potion": draw_blind_talisman,
    "blood_jade": draw_pendant,
    "body_goldskin_seal": draw_seal,
    "body_marrow_drum": draw_drum,
    "campfire_ember_seal": draw_ember_seal,
    "cloud_step_charm": draw_cloud_step,
    "confusing_staff": draw_staff,
    "coupons": draw_tickets,
    "demon_blood_oath_mirror": draw_mirror,
    "demon_heart_seal": draw_heart_seal,
    "demon_sacrifice_dagger": draw_dagger,
    "explosive_barrel": draw_barrel,
    "fate_ledger": draw_book,
    "fire_spark_pearl": draw_pearl,
    "ghost_contract": draw_contract,
    "golden_bone_bead": draw_bone_bead,
    "healing_potion": draw_gourd,
    "ink_guard_talisman": draw_shield_talisman,
    "jade_abacus": draw_abacus,
    "lotus_mirror": draw_lotus_mirror,
    "mana_potion": draw_bottle_moon,
    "metal_edge_ring": draw_ring,
    "pack_banner": draw_banner,
    "qingfeng_sword_box": draw_sword_box,
    "reinforced_armor": draw_armor,
    "sacrifice_blade": draw_dagger,
    "soul_lantern": draw_lantern,
    "spirit_spring_gourd": draw_spring_gourd,
    "star_compass": draw_compass,
    "stone_heart_bell": draw_bell,
    "sword_cloud_manual": draw_scroll_sword,
    "sword_execution_tally": draw_tally,
    "sword_grindstone": draw_grindstone,
    "sword_resonance_charm": draw_resonance,
    "thunder_seal": draw_thunder,
    "water_moon_bottle": draw_bottle_moon,
    "wind_sword_tassel": draw_tassel,
    "wood_earth_seed": draw_seed,
    "wooden_sword": draw_wooden_sword,
    "xuangu_talisman": draw_bone_amulet,
}


def generate_icon(relic_id: str) -> None:
    bg, rim, fg, accent = palette_for(relic_id)
    canvas, draw = make_canvas(bg, rim)
    motif = MOTIFS.get(relic_id, draw_charm)
    motif(draw, rgba(fg), rgba("#120d0a", 230), rgba("#fff2bf", 230), rgba(accent))
    canvas = canvas.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    canvas.save(OUT_DIR / f"{relic_id}.png")


def update_relic_resource(path: Path) -> str | None:
    text = path.read_text(encoding="utf-8")
    id_match = re.search(r'^id = "([^"]+)"', text, re.MULTILINE)
    icon_match = re.search(r'^icon = ExtResource\("([^"]+)"\)', text, re.MULTILINE)
    if not id_match or not icon_match:
        return None

    relic_id = id_match.group(1)
    icon_id = icon_match.group(1)
    generate_icon(relic_id)

    ext_re = re.compile(rf'^\[ext_resource type="Texture2D" [^\n]*id="{re.escape(icon_id)}"\]$', re.MULTILINE)
    replacement = f'[ext_resource type="Texture2D" path="res://art/relics/icons/{relic_id}.png" id="{icon_id}"]'
    new_text, count = ext_re.subn(replacement, text, count=1)
    if count != 1:
        raise RuntimeError(f"Could not replace icon resource in {path}")

    path.write_text(new_text, encoding="utf-8", newline="\n")
    return relic_id


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    relic_ids: list[str] = []
    for resource in sorted(RELIC_DIR.glob("*.tres")):
        if resource.name == "relic_reward_pool.tres":
            continue
        relic_id = update_relic_resource(resource)
        if relic_id:
            relic_ids.append(relic_id)

    print(f"Generated {len(relic_ids)} relic icons:")
    for relic_id in relic_ids:
        print(f"  {relic_id}")


if __name__ == "__main__":
    main()
