"""Shared helpers for the card data <-> Excel round trip.

The Excel sheet is the editing surface for card *numbers* (cost, name, type,
target, rarity, exhaust, element and each effect's amount). Effect *types* and
status references are exported for reference only and are NOT written back —
those structural changes stay in the Godot editor.
"""

from __future__ import annotations

import re
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1] / "game-demo"

# ---- enum label maps (Excel shows readable text; we map back on import) ----
TYPE = {0: "攻击", 1: "技能", 2: "功法"}
TARGET = {0: "自身", 1: "单体", 2: "全体敌", 3: "所有"}
RARITY = {0: "白", 1: "蓝", 2: "金", 3: "暗金"}
ELEMENT = {0: "无", 1: "金", 2: "木", 3: "水", 4: "火", 5: "土"}
TYPE_R = {v: k for k, v in TYPE.items()}
TARGET_R = {v: k for k, v in TARGET.items()}
RARITY_R = {v: k for k, v in RARITY.items()}
ELEMENT_R = {v: k for k, v in ELEMENT.items()}

EFFECT_LABEL = {
    "configured_damage_effect": "伤害",
    "configured_block_effect": "护体",
    "configured_draw_effect": "抽牌",
    "configured_heal_effect": "治疗",
    "configured_self_damage_effect": "自损",
    "configured_status_effect": "状态",
    "configured_mana_effect": "灵气",
    "configured_exhaust_random_effect": "消耗",
    "configured_pile_tutor_effect": "牌堆检索",
    "configured_self_damage_scaling_damage_effect": "血债清算",
    "configured_consume_status_to_damage_effect": "耗煞伤害",
    "configured_count_scaling_effect": "计数增幅",
    "configured_copy_previous_card_effect": "复刻",
    "low_health_bonus_damage_effect": "半血爆伤",
}

MAX_EFFECTS = 4


def find_card_files() -> list[Path]:
    roots = [
        PROJECT_ROOT / "common_cards",
        PROJECT_ROOT / "characters",
        PROJECT_ROOT / "fusion_cards",
    ]
    files: list[Path] = []
    for root in roots:
        if not root.exists():
            continue
        for path in root.rglob("*.tres"):
            text = path.read_text(encoding="utf-8", errors="ignore")
            if 'script_class="CultivationCard"' in text:
                files.append(path)
    return sorted(files)


def _res_section(text: str) -> str:
    return text.split("[resource]", 1)[1] if "[resource]" in text else text


def _get_int(text: str, key: str, default: int = 0) -> int:
    m = re.search(rf"^{key} = (-?\d+)", _res_section(text), re.M)
    return int(m.group(1)) if m else default


def _get_str(text: str, key: str, default: str = "") -> str:
    m = re.search(rf'^{key} = "([^"]*)"', _res_section(text), re.M)
    return m.group(1) if m else default


def _get_bool(text: str, key: str) -> bool:
    return re.search(rf"^{key} = true", _res_section(text), re.M) is not None


def _ext_maps(text: str) -> tuple[dict, dict]:
    """ext_resource id -> effect-script-basename, and id -> status-id."""
    scripts: dict[str, str] = {}
    for m in re.finditer(
        r'\[ext_resource type="Script"[^\]]*path="res://custom_resources/effects/([a-z_]+)\.gd"[^\]]*id="([^"]+)"',
        text,
    ):
        scripts[m.group(2)] = m.group(1)
    statuses: dict[str, str] = {}
    for m in re.finditer(
        r'\[ext_resource type="Resource"[^\]]*path="res://statuses/([a-z_0-9]+)\.tres"[^\]]*id="([^"]+)"',
        text,
    ):
        statuses[m.group(2)] = m.group(1)
    return scripts, statuses


def _effect_blocks(text: str) -> list[str]:
    """The [sub_resource] blocks (effects), in order, before [resource]."""
    head = text.split("[resource]", 1)[0]
    parts = re.split(r"\n(?=\[sub_resource)", head)
    return [p for p in parts if p.lstrip().startswith("[sub_resource")]


def parse_card(path: Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="ignore")
    scripts, statuses = _ext_maps(text)
    effects = []
    for block in _effect_blocks(text):
        scr = re.search(r'script = ExtResource\("([^"]+)"\)', block)
        # 必须锚定行首，否则会误匹配 consume_amount / *_amount 等字段。
        amt = re.search(r"^amount = (-?\d+)", block, re.M)
        st = re.search(r'status = ExtResource\("([^"]+)"\)', block)
        label = EFFECT_LABEL.get(scripts.get(scr.group(1), ""), scripts.get(scr.group(1), "?")) if scr else "?"
        extra = statuses.get(st.group(1), "") if st else ""
        effects.append((label, int(amt.group(1)) if amt else None, extra))

    rel = path.relative_to(PROJECT_ROOT).as_posix()
    profession = "通用"
    for key, name in (("body_cultivator", "体修"), ("sword_cultivator", "剑修"),
                      ("demonic_cultivator", "魔修"), ("beastmaster", "驭兽"), ("fusion", "融合")):
        if key in rel:
            profession = name
            break
    return {
        "file": rel,
        "id": _get_str(text, "id"),
        "profession": profession,
        "name": _get_str(text, "display_name"),
        "cost": _get_int(text, "cost"),
        "type": TYPE.get(_get_int(text, "type"), "攻击"),
        "target": TARGET.get(_get_int(text, "target"), "自身"),
        "rarity": RARITY.get(_get_int(text, "rarity"), "白"),
        "exhausts": _get_bool(text, "exhausts"),
        "element": ELEMENT.get(_get_int(text, "element"), "无"),
        "effects": effects,
    }


# ----------------------------- writing back -----------------------------

def _set_res_field(text: str, key: str, raw_value: str, is_default: bool) -> str:
    """Replace `key = ...` in the [resource] section; insert if missing and
    not default; otherwise leave as-is."""
    if "[resource]" not in text:
        return text
    head, res = text.split("[resource]", 1)
    pattern = re.compile(rf"^{key} = .*$", re.M)
    if pattern.search(res):
        res = pattern.sub(f"{key} = {raw_value}", res, count=1)
    elif not is_default:
        # insert right after the leading `script = ExtResource(...)` line
        res = re.sub(r'(\nscript = ExtResource\("[^"]+"\)\n)', rf'\1{key} = {raw_value}\n', res, count=1)
    return head + "[resource]" + res


def _set_effect_amounts(text: str, amounts: list) -> str:
    if "[resource]" not in text:
        return text
    head, res = text.split("[resource]", 1)
    blocks = re.split(r"(\n\[sub_resource)", head)
    # rebuild head, tracking effect index
    out = blocks[0]
    idx = 0
    i = 1
    while i < len(blocks):
        sep = blocks[i]
        body = blocks[i + 1] if i + 1 < len(blocks) else ""
        if idx < len(amounts) and amounts[idx] is not None:
            val = int(amounts[idx])
            if re.search(r"^amount = -?\d+", body, re.M):
                body = re.sub(r"^amount = -?\d+", f"amount = {val}", body, count=1, flags=re.M)
            else:
                body = re.sub(r'(\nscript = ExtResource\("[^"]+"\)\n)', rf'\1amount = {val}\n', body, count=1)
        idx += 1
        out += sep + body
        i += 2
    return out + "[resource]" + res


def update_card_file(path: Path, row: dict) -> bool:
    """Apply editable values from a parsed Excel row to the .tres. Returns True
    if the file content changed."""
    text = path.read_text(encoding="utf-8", errors="ignore")
    original = text

    text = _set_res_field(text, "display_name", f'"{row["name"]}"', row["name"] == "")
    text = _set_res_field(text, "cost", str(row["cost"]), row["cost"] == 0)
    text = _set_res_field(text, "type", str(TYPE_R[row["type"]]), TYPE_R[row["type"]] == 0)
    text = _set_res_field(text, "target", str(TARGET_R[row["target"]]), TARGET_R[row["target"]] == 0)
    text = _set_res_field(text, "rarity", str(RARITY_R[row["rarity"]]), RARITY_R[row["rarity"]] == 0)
    text = _set_res_field(text, "element", str(ELEMENT_R[row["element"]]), ELEMENT_R[row["element"]] == 0)
    text = _set_res_field(text, "exhausts", "true" if row["exhausts"] else "false", not row["exhausts"])
    text = _set_effect_amounts(text, row["effect_amounts"])

    if text != original:
        path.write_text(text, encoding="utf-8")
        return True
    return False
