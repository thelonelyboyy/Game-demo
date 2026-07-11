"""Read/write game-demo/data/blessings.json for the unified game-data workbook.

祝福数据外置在 JSON，本模块负责 JSON <-> 行 的双向转换。导入时按表内容整体重建 JSON。
"""

from __future__ import annotations

import json
from pathlib import Path

BLESSINGS_JSON = Path(__file__).resolve().parents[1] / "game-demo" / "data" / "blessings.json"

MAX_EFFECTS = 3

# 可用效果类型（下拉框用）
EFFECT_TYPES = [
    "max_health", "lose_max_health", "full_heal",
    "gold", "lose_gold", "lose_all_gold", "max_mana", "draw",
    "upgrade", "remove_card", "remove_strike_defend",
    "duplicate_card", "add_random_cards", "add_random_rare_card", "transform_card",
    "grant_relic", "gain_potion", "weaken_next_battles",
]

# 命格（命格共鸣按此过滤；空=通用）
CLASS_VALUES = ["", "demonic", "sword", "body", "beastmaster"]


def load() -> dict:
    return json.loads(BLESSINGS_JSON.read_text(encoding="utf-8"))


def to_rows() -> list[dict]:
    """每条祝福一行。"""
    data = load()
    rows: list[dict] = []
    for src in data.get("sources", []):
        for b in src.get("blessings", []):
            effects = [(e.get("type", ""), int(e.get("amount", 0))) for e in b.get("effects", [])]
            rows.append({
                "source": src.get("name", ""),
                "source_desc": src.get("description", ""),
                "name": b.get("name", ""),
                "desc": b.get("description", ""),
                "cls": b.get("class", ""),
                "icon": b.get("icon", ""),
                "effects": effects,
            })
    return rows


def write_rows(rows: list[dict]) -> bool:
    """按行整体重建 blessings.json，保留来源出现顺序。返回是否有改动。"""
    sources: list[dict] = []
    by_name: dict[str, dict] = {}
    for r in rows:
        sname = (r.get("source") or "").strip()
        if not sname:
            continue
        if sname not in by_name:
            src = {"name": sname, "description": r.get("source_desc", ""), "blessings": []}
            by_name[sname] = src
            sources.append(src)
        b: dict = {"name": r.get("name", ""), "description": r.get("desc", "")}
        if r.get("icon"):
            b["icon"] = r["icon"]
        if r.get("cls"):
            b["class"] = r["cls"]
        effects = []
        for (t, a) in r.get("effects", []):
            t = (t or "").strip()
            if t:
                effects.append({"type": t, "amount": int(a or 0)})
        b["effects"] = effects
        by_name[sname]["blessings"].append(b)

    new_text = json.dumps({"sources": sources}, ensure_ascii=False, indent="\t") + "\n"
    if BLESSINGS_JSON.exists() and BLESSINGS_JSON.read_text(encoding="utf-8") == new_text:
        return False
    BLESSINGS_JSON.write_text(new_text, encoding="utf-8")
    return True
