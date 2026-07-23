"""Detailed, numeric card-effect table with bidirectional writeback."""

from __future__ import annotations

import re
from pathlib import Path

try:
    import card_table as ct
    import game_data_labels as labels
except ModuleNotFoundError:
    from scripts import card_table as ct
    from scripts import game_data_labels as labels

PROJECT_ROOT = ct.PROJECT_ROOT
TRIGGERS = {
    "configured_effects": "打出时",
    "draw_trigger_effects": "抽到时",
    "discard_trigger_effects": "弃置时",
    "exhaust_trigger_effects": "消耗时",
    "end_turn_trigger_effects": "回合结束时",
}
STRUCTURAL_FIELDS = {
    "target_mode", "condition_type", "condition_card_type", "result", "count_source",
    "source_pile", "card_filter", "engine", "color", "bonus", "rider", "growth_trigger",
    "condition_element",
    "convert_to", "type", "target", "rarity", "element", "profession", "upgrade_type",
}

CONDITION_NAMES = {
    0: "无条件", 1: "所选灵根一致", 2: "拥有机制标签", 3: "本牌类型匹配",
    4: "玩家拥有指定状态", 5: "焰轮颜色数达标", 6: "连携上一张牌类型",
    7: "连携上一张牌元素", 8: "本回合出牌数达标", 9: "低生命",
}


def _number(raw: str) -> int | float:
    return float(raw) if "." in raw else int(raw)


def _subresources(text: str) -> dict[str, str]:
    return {
        m.group(1): m.group(2)
        for m in re.finditer(r'\[sub_resource type="Resource" id="([^"]+)"\]\n(.*?)(?=\n\[|\Z)', text, re.S)
    }


def _script_maps(text: str) -> tuple[dict[str, str], dict[str, str]]:
    names: dict[str, str] = {}
    paths: dict[str, str] = {}
    for m in re.finditer(r'\[ext_resource type="Script"[^\]]*path="([^"]+)"[^\]]*id="([^"]+)"', text):
        path, ext_id = m.group(1), m.group(2)
        if "/effects/" in path:
            paths[ext_id] = path
            names[ext_id] = Path(path).stem
    return names, paths


def _script_defaults(script_path: str) -> dict[str, int | float]:
    path = PROJECT_ROOT / script_path.removeprefix("res://")
    if not path.exists():
        return {}
    text = path.read_text(encoding="utf-8", errors="ignore")
    result: dict[str, int | float] = {}
    pattern = r'@export[^\n]*?var\s+([A-Za-z_][A-Za-z0-9_]*)(?:\s*:\s*[^:=\n]+)?\s*(?::=|=)\s*(-?\d+(?:\.\d+)?)'
    for m in re.finditer(pattern, text):
        if m.group(1) not in STRUCTURAL_FIELDS:
            result[m.group(1)] = _number(m.group(2))
    return result


def _trigger_refs(text: str) -> dict[str, str]:
    resource = text.split("[resource]", 1)[1] if "[resource]" in text else ""
    result: dict[str, str] = {}
    for field, label in TRIGGERS.items():
        m = re.search(rf'^{field} = .*?\((.*)\)$', resource, re.M)
        if m:
            for sub_id in re.findall(r'SubResource\("([^"]+)"\)', m.group(1)):
                result[sub_id] = label
    return result


def parse_file(path: Path) -> list[dict]:
    text = path.read_text(encoding="utf-8", errors="ignore")
    card = ct.parse_card(path)
    scripts, script_paths = _script_maps(text)
    triggers = _trigger_refs(text)
    rows: list[dict] = []
    for sub_id, body in _subresources(text).items():
        sm = re.search(r'script = ExtResource\("([^"]+)"\)', body)
        ext_id = sm.group(1) if sm else ""
        script = scripts.get(ext_id, "")
        if not script:
            continue
        params = _script_defaults(script_paths[ext_id])
        condition_match = re.search(r'^condition_type = (\d+)$', body, re.M)
        condition_type = int(condition_match.group(1)) if condition_match else 0
        condition = CONDITION_NAMES.get(condition_type, "特殊条件")
        for pm in re.finditer(r'^([a-z_][a-z_0-9]*) = (-?\d+(?:\.\d+)?)$', body, re.M):
            if pm.group(1) not in STRUCTURAL_FIELDS:
                params[pm.group(1)] = _number(pm.group(2))
        for raw_name, value in sorted(params.items(), key=lambda item: (item[0] != "amount", item[0])):
            if raw_name not in labels.PARAM_LABELS:
                raise ValueError(f"缺少卡牌参数中文映射: {raw_name} ({path.name}/{sub_id})")
            rows.append({
                "file": card["file"], "card_id": card["id"], "card_name": card["name"],
                "trigger": triggers.get(sub_id, "嵌套效果"), "effect_id": sub_id,
                "effect": labels.CARD_EFFECT_LABELS.get(script, "未命名效果"),
                "condition": condition,
                "script_path": script_paths[ext_id], "param": labels.PARAM_LABELS[raw_name],
                "value": value,
            })
    return rows


def parse_all() -> list[dict]:
    rows: list[dict] = []
    for path in ct.find_card_files():
        rows.extend(parse_file(path))
    return rows


def _render_number(value: int | float) -> str:
    number = float(value)
    return str(int(number)) if number.is_integer() else f"{number:.6f}".rstrip("0").rstrip(".")


def write_file(rel_path: str, edits: list[dict]) -> bool:
    path = PROJECT_ROOT / rel_path
    text = path.read_text(encoding="utf-8")
    original = text
    effective = {
        (row["effect_id"], row["param"]): row["value"]
        for row in parse_file(path)
    }
    for edit in edits:
        sub_id = str(edit["effect_id"])
        if (sub_id, str(edit["param"])) in effective and float(effective[(sub_id, str(edit["param"]))]) == float(edit["value"]):
            continue
        raw_name = labels.PARAM_LABELS_R.get(str(edit["param"]))
        if not raw_name:
            raise ValueError(f"未知参数名称: {edit['param']}")
        value = _render_number(edit["value"])
        block_pattern = re.compile(r'(\[sub_resource type="Resource" id="' + re.escape(sub_id) + r'"\]\n)(.*?)(?=\n\[|\Z)', re.S)
        found = False

        def replace_block(match: re.Match) -> str:
            nonlocal found
            found = True
            header, body = match.group(1), match.group(2)
            field = re.compile(r'^' + re.escape(raw_name) + r' = -?\d+(?:\.\d+)?$', re.M)
            if field.search(body):
                body = field.sub(f"{raw_name} = {value}", body, count=1)
            else:
                body = re.sub(r'(script = ExtResource\("[^"]+"\)\n)', rf'\1{raw_name} = {value}\n', body, count=1)
            return header + body

        text = block_pattern.sub(replace_block, text, count=1)
        if not found:
            raise ValueError(f"效果ID不存在: {sub_id}")
    if text == original:
        return False
    path.write_text(text, encoding="utf-8")
    return True
