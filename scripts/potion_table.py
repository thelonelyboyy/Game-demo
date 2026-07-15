"""Read/write potion and talisman resources for the unified workbook."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POTION_ROOT = ROOT / "game-demo" / "potions"

CATEGORY = {0: "符箓", 1: "丹药"}
RARITY = {0: "白", 1: "蓝", 2: "金", 3: "暗金"}
TARGET = {0: "自身", 1: "单体敌人", 2: "全体敌人"}
CHARACTER = {0: "通用", 1: "体修", 2: "剑修", 3: "魔修", 4: "驭兽"}
CATEGORY_R = {v: k for k, v in CATEGORY.items()}
RARITY_R = {v: k for k, v in RARITY.items()}
TARGET_R = {v: k for k, v in TARGET.items()}
CHARACTER_R = {v: k for k, v in CHARACTER.items()}

EFFECT_LABELS = {
    "configured_block_effect": "护体", "configured_cleanse_debuff_effect": "净化",
    "configured_damage_effect": "伤害", "configured_draw_effect": "抽牌",
    "configured_heal_effect": "治疗", "configured_mana_effect": "灵气",
    "configured_self_damage_effect": "自损", "configured_soul_mark_detonate_effect": "魂印引爆",
    "configured_status_effect": "状态",
}


def _resource(text: str) -> str:
    return text.split("[resource]", 1)[1] if "[resource]" in text else text


def _str(text: str, key: str) -> str:
    m = re.search(rf'^{key} = "((?:\\.|[^"\\])*)"', _resource(text), re.M)
    return json.loads('"' + m.group(1) + '"') if m else ""


def _int(text: str, key: str, default: int = 0) -> int:
    m = re.search(rf'^{key} = (-?\d+)', _resource(text), re.M)
    return int(m.group(1)) if m else default


def parse_file(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    script_paths = {
        m.group(2): m.group(1).split("/")[-1].removesuffix(".gd")
        for m in re.finditer(r'\[ext_resource type="Script" path="([^"]+)" id="([^"]+)"\]', text)
    }
    subresources: dict[str, str] = {
        m.group(1): m.group(2)
        for m in re.finditer(r'\[sub_resource type="Resource" id="([^"]+)"\]\n(.*?)(?=\n\[|\Z)', text, re.S)
    }
    refs_m = re.search(r'^configured_effects = .*?\((.*)\)$', _resource(text), re.M)
    refs = re.findall(r'SubResource\("([^"]+)"\)', refs_m.group(1)) if refs_m else []
    effects = []
    for sub_id in refs:
        body = subresources.get(sub_id, "")
        sm = re.search(r'script = ExtResource\("([^"]+)"\)', body)
        script_name = script_paths.get(sm.group(1), "") if sm else ""
        params = []
        for pm in re.finditer(r'^([a-z_]+) = (-?\d+(?:\.\d+)?)$', body, re.M):
            if pm.group(1) not in {"target_mode"}:
                raw = pm.group(2)
                params.append({"name": pm.group(1), "value": float(raw) if "." in raw else int(raw)})
        effects.append({"sub_id": sub_id, "script": script_name,
                        "label": EFFECT_LABELS.get(script_name, script_name), "params": params[:2]})
    rel = path.relative_to(ROOT).as_posix()
    return {
        "file": rel, "id": _str(text, "id"), "name": _str(text, "potion_name"),
        "category": CATEGORY.get(_int(text, "category"), "符箓"),
        "rarity": RARITY.get(_int(text, "rarity"), "白"),
        "target": TARGET.get(_int(text, "target_kind"), "自身"),
        "out_of_combat": "是" if re.search(r'^usable_out_of_combat = true', _resource(text), re.M) else "否",
        "tooltip": _str(text, "tooltip"),
        "character": CHARACTER.get(_int(text, "character_type"), "通用"),
        "effects": effects[:2],
    }


def parse_all() -> list[dict]:
    return [parse_file(p) for p in sorted(POTION_ROOT.glob("*.tres"))]


def _set_resource(text: str, key: str, value: str) -> str:
    head, resource = text.split("[resource]", 1)
    pat = re.compile(rf'^{re.escape(key)} = .*$', re.M)
    if not pat.search(resource):
        raise ValueError(f"resource field not found: {key}")
    return head + "[resource]" + pat.sub(f"{key} = {value}", resource, count=1)


def write_file(row: dict) -> bool:
    path = ROOT / str(row["file"])
    text = path.read_text(encoding="utf-8")
    new = text
    fields = [
        ("potion_name", json.dumps(str(row["name"]), ensure_ascii=False)),
        ("category", str(CATEGORY_R[str(row["category"])])),
        ("rarity", str(RARITY_R[str(row["rarity"])])),
        ("target_kind", str(TARGET_R[str(row["target"])])),
        ("usable_out_of_combat", "true" if row["out_of_combat"] == "是" else "false"),
        ("tooltip", json.dumps(str(row["tooltip"]), ensure_ascii=False)),
        ("character_type", str(CHARACTER_R[str(row["character"])])),
    ]
    for key, value in fields:
        new = _set_resource(new, key, value)
    for effect in row.get("effects", []):
        sub_id = str(effect.get("sub_id", ""))
        for param in effect.get("params", []):
            key, value = str(param.get("name", "")), param.get("value", 0)
            pat = re.compile(r'(\[sub_resource type="Resource" id="' + re.escape(sub_id) + r'"\].*?^' + re.escape(key) + r' = )-?\d+(?:\.\d+)?', re.M | re.S)
            new, count = pat.subn(lambda m: m.group(1) + str(value), new, count=1)
            if not count:
                raise ValueError(f"{path.name}: effect {sub_id} field not found: {key}")
    if new == text:
        return False
    path.write_text(new, encoding="utf-8")
    return True
