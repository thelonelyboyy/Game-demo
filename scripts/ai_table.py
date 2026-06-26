"""Read/write the 4 fixed-sequence enemy AI .tscn files for the unified workbook.

只覆盖固定套路敌人：符纸兵 / 雾隐狼 / 牛魔 / 渊狱剑魂。
可调字段：每个行动的数值(damage/block)、出招序列(fixed_sequence)；
格挡行动的意图文字会随 block 值自动同步。
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# (显示名, 相对仓库根的 .tscn 路径)
AI_FILES = [
    ("符纸兵", "game-demo/enemies/paper_soldier/paper_soldier_ai.tscn"),
    ("雾隐狼", "game-demo/enemies/mist_wolf/mist_wolf_ai.tscn"),
    ("牛魔", "game-demo/enemies/bull_demon/bull_demon_ai.tscn"),
    ("渊狱剑魂", "game-demo/enemies/abyssal_sword_soul/abyssal_sword_soul_ai.tscn"),
]

TYPE_ATTACK = "攻击"
TYPE_MULTI = "多段"
TYPE_BLOCK = "格挡"


def _script_type(script_basename: str) -> tuple[str, str]:
    """返回 (类型显示名, 数值字段名)。"""
    if "block" in script_basename:
        return TYPE_BLOCK, "block"
    if "bat_attack" in script_basename:
        return TYPE_MULTI, "damage"
    return TYPE_ATTACK, "damage"


def parse_file(rel_path: str, display_name: str) -> dict:
    text = (ROOT / rel_path).read_text(encoding="utf-8")

    # ext_resource(Script) id -> 文件名
    id_to_script: dict[str, str] = {}
    for m in re.finditer(r'\[ext_resource type="Script"[^\]]*path="([^"]+)"[^\]]*id="([^"]+)"\]', text):
        id_to_script[m.group(2)] = m.group(1).split("/")[-1]

    seq_m = re.search(r'fixed_sequence = Array\[int\]\(\[([^\]]*)\]\)', text)
    sequence = seq_m.group(1).strip() if seq_m else ""

    actions = []
    for m in re.finditer(r'\[node name="([^"]+)" type="Node" parent="\."\](.*?)(?=\n\[|\Z)', text, re.S):
        node_name, body = m.group(1), m.group(2)
        sm = re.search(r'script = ExtResource\("([^"]+)"\)', body)
        if not sm:
            continue
        script_name = id_to_script.get(sm.group(1), "")
        type_label, field = _script_type(script_name)
        vm = re.search(field + r" = (\d+)", body)
        if not vm:
            continue
        actions.append({
            "node": node_name,
            "type": type_label,
            "field": field,
            "value": int(vm.group(1)),
        })

    return {"name": display_name, "file": rel_path, "sequence": sequence, "actions": actions}


def parse_all() -> list[dict]:
    return [parse_file(p, name) for name, p in AI_FILES]


def _set_node_value(text: str, node_name: str, field: str, value: int) -> str:
    pat = re.compile(
        r'(\[node name="' + re.escape(node_name) + r'" type="Node" parent="\."\].*?\n' + field + r' = )\d+',
        re.S,
    )
    return pat.sub(lambda mm: mm.group(1) + str(value), text, count=1)


def _set_block_intent_text(text: str, node_name: str, value: int) -> str:
    """格挡行动：把它绑定的 intent 子资源 base_text 同步成 block 值。"""
    nm = re.search(
        r'\[node name="' + re.escape(node_name) + r'" type="Node" parent="\."\].*?intent = SubResource\("([^"]+)"\)',
        text, re.S,
    )
    if not nm:
        return text
    sub_id = nm.group(1)
    pat = re.compile(
        r'(\[sub_resource type="Resource" id="' + re.escape(sub_id) + r'"\].*?\nbase_text = ")[^"]*(")',
        re.S,
    )
    return pat.sub(lambda mm: mm.group(1) + str(value) + mm.group(2), text, count=1)


def write_file(rel_path: str, sequence: str, actions: list[dict]) -> bool:
    path = ROOT / rel_path
    text = path.read_text(encoding="utf-8")
    original = text

    seq_clean = re.sub(r"\s+", " ", str(sequence).strip())
    text = re.sub(
        r'(fixed_sequence = Array\[int\]\(\[)[^\]]*(\]\))',
        lambda mm: mm.group(1) + seq_clean + mm.group(2),
        text, count=1,
    )

    for a in actions:
        text = _set_node_value(text, a["node"], a["field"], int(a["value"]))
        if a["field"] == "block":
            text = _set_block_intent_text(text, a["node"], int(a["value"]))

    if text == original:
        return False
    path.write_text(text, encoding="utf-8")
    return True
