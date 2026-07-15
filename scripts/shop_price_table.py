"""Read/write the shop price constants exposed in game_data.xlsx."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CARD = ROOT / "game-demo/scenes/shop/shop_card.gd"
RELIC = ROOT / "game-demo/scenes/shop/shop_relic.gd"
POTION = ROOT / "game-demo/scenes/shop/shop_potion.gd"
RUN_STATS = ROOT / "game-demo/custom_resources/run_stats.gd"

RARITIES = ["COMMON", "UNCOMMON", "RARE", "MYTHIC"]
RARITY_LABEL = {"COMMON": "白", "UNCOMMON": "蓝", "RARE": "金", "MYTHIC": "暗金", "BOSS": "首领"}


def _dict_ints(text: str, const_name: str) -> dict[str, int]:
    block = re.search(rf'const {const_name} := \{{(.*?)\n\}}', text, re.S)
    return {m.group(1): int(m.group(2)) for m in re.finditer(r'Rarity\.([A-Z]+):\s*(\d+)', block.group(1))} if block else {}


def _dict_ranges(text: str, const_name: str) -> dict[str, tuple[int, int]]:
    block = re.search(rf'const {const_name} := \{{(.*?)\n\}}', text, re.S)
    return {m.group(1): (int(m.group(2)), int(m.group(3))) for m in re.finditer(r'Rarity\.([A-Z]+):\s*Vector2i\((\d+),\s*(\d+)\)', block.group(1))} if block else {}


def _const_number(text: str, key: str) -> float:
    m = re.search(rf'^const {key} := ([0-9.]+)', text, re.M)
    if not m:
        raise ValueError(f"constant not found: {key}")
    return float(m.group(1))


def parse_all() -> list[dict]:
    card_text, relic_text, potion_text = CARD.read_text(encoding="utf-8"), RELIC.read_text(encoding="utf-8"), POTION.read_text(encoding="utf-8")
    rows: list[dict] = []
    for key, value in _dict_ints(card_text, "PRICE_BY_RARITY").items():
        rows.append({"group": "卡牌", "tier": RARITY_LABEL[key], "base": value, "min": None, "max": None, "percent": None, "key": f"card:{key}", "note": "基价；实际售价按浮动比例随机"})
    rows.append({"group": "卡牌", "tier": "价格浮动", "base": None, "min": None, "max": None, "percent": _const_number(card_text, "CARD_PRICE_VARIANCE"), "key": "card:variance", "note": "0.10 = 基价上下浮动 10%"})
    rows.append({"group": "卡牌", "tier": "特惠折扣", "base": None, "min": None, "max": None, "percent": _const_number(card_text, "CARD_SALE_MULTIPLIER"), "key": "card:sale", "note": "0.50 = 半价"})
    for key, (low, high) in _dict_ranges(relic_text, "RELIC_PRICE_RANGES").items():
        rows.append({"group": "法宝", "tier": RARITY_LABEL[key], "base": None, "min": low, "max": high, "percent": None, "key": f"relic:{key}", "note": "在最低价与最高价之间随机"})
    for key, value in _dict_ints(potion_text, "PRICE_BY_RARITY").items():
        rows.append({"group": "符箓丹药", "tier": RARITY_LABEL[key], "base": value, "min": None, "max": None, "percent": None, "key": f"potion:{key}", "note": "固定基价"})
    stats = RUN_STATS.read_text(encoding="utf-8")
    for key, tier, note in [("BASE_CARD_REMOVE_COST", "删牌起价", "第一次删牌价格"), ("CARD_REMOVE_COST_INCREMENT", "删牌递增", "每次删牌后的加价")]:
        rows.append({"group": "服务", "tier": tier, "base": int(_const_number(stats, key)), "min": None, "max": None, "percent": None, "key": f"run:{key}", "note": note})
    return rows


def _replace_dict_value(text: str, const_name: str, rarity: str, value: int) -> str:
    pat = re.compile(r'(const ' + re.escape(const_name) + r' := \{.*?Rarity\.' + re.escape(rarity) + r':\s*)\d+', re.S)
    new, count = pat.subn(lambda m: m.group(1) + str(value), text, count=1)
    if not count:
        raise ValueError(f"{const_name}.{rarity} not found")
    return new


def _replace_range(text: str, rarity: str, low: int, high: int) -> str:
    pat = re.compile(r'(const RELIC_PRICE_RANGES := \{.*?Rarity\.' + re.escape(rarity) + r':\s*)Vector2i\(\d+,\s*\d+\)', re.S)
    new, count = pat.subn(lambda m: m.group(1) + f"Vector2i({low}, {high})", text, count=1)
    if not count:
        raise ValueError(f"RELIC_PRICE_RANGES.{rarity} not found")
    return new


def _replace_const(text: str, key: str, value: int | float) -> str:
    pat = re.compile(rf'(^const {re.escape(key)} := )[0-9.]+', re.M)
    rendered = f"{value:.2f}" if isinstance(value, float) and not value.is_integer() else str(int(value))
    new, count = pat.subn(lambda m: m.group(1) + rendered, text, count=1)
    if not count:
        raise ValueError(f"constant not found: {key}")
    return new


def write_rows(rows: list[dict]) -> int:
    texts = {CARD: CARD.read_text(encoding="utf-8"), RELIC: RELIC.read_text(encoding="utf-8"), POTION: POTION.read_text(encoding="utf-8"), RUN_STATS: RUN_STATS.read_text(encoding="utf-8")}
    for row in rows:
        prefix, key = str(row["key"]).split(":", 1)
        if prefix == "card" and key in RARITIES:
            texts[CARD] = _replace_dict_value(texts[CARD], "PRICE_BY_RARITY", key, int(row["base"]))
        elif prefix == "card" and key == "variance":
            texts[CARD] = _replace_const(texts[CARD], "CARD_PRICE_VARIANCE", float(row["percent"]))
        elif prefix == "card" and key == "sale":
            texts[CARD] = _replace_const(texts[CARD], "CARD_SALE_MULTIPLIER", float(row["percent"]))
        elif prefix == "relic":
            texts[RELIC] = _replace_range(texts[RELIC], key, int(row["min"]), int(row["max"]))
        elif prefix == "potion":
            texts[POTION] = _replace_dict_value(texts[POTION], "PRICE_BY_RARITY", key, int(row["base"]))
        elif prefix == "run":
            texts[RUN_STATS] = _replace_const(texts[RUN_STATS], key, int(row["base"]))
    changed = 0
    for path, new in texts.items():
        old = path.read_text(encoding="utf-8")
        if new != old:
            path.write_text(new, encoding="utf-8")
            changed += 1
    return changed
