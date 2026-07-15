"""Read/write every enemy AI scene referenced by EnemyStats resources."""

from __future__ import annotations

import re
from pathlib import Path

try:
    import enemy_table as et
except ModuleNotFoundError:  # 支持作为 scripts.ai_table 导入
    from scripts import enemy_table as et

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "game-demo"
MAX_PARAMS = 5

TYPE_CONDITIONAL = "条件"
TYPE_WEIGHTED = "权重"
PARAM_PRIORITY = {
    "damage": 0, "block": 1, "base_damage": 2, "damage_per_discard": 3,
    "max_bonus_damage": 4, "healing": 5, "health_cost": 6, "muscle_stacks": 7,
    "stacks": 8, "stacks_per_action": 9, "copies": 10, "max_enemies": 11,
    "fallback_block": 12, "chance_weight": 20, "max_consecutive_uses": 21,
}


def _attrs(section: str) -> dict[str, str]:
    return dict(re.findall(r'(\w+)="([^"]*)"', section))


def _ext_resources(text: str) -> dict[str, dict[str, str]]:
    result: dict[str, dict[str, str]] = {}
    for match in re.finditer(r'\[ext_resource ([^\]]+)\]', text):
        attrs = _attrs(match.group(1))
        if "id" in attrs:
            result[attrs["id"]] = attrs
    return result


def _number(value: str) -> int | float:
    return float(value) if "." in value else int(value)


def _script_defaults(res_path: str) -> dict[str, int | float]:
    path = PROJECT / res_path.removeprefix("res://")
    if not path.exists():
        return {}
    text = path.read_text(encoding="utf-8", errors="ignore")
    result: dict[str, int | float] = {}
    pattern = r'@export[^\n]*?var\s+([A-Za-z_][A-Za-z0-9_]*)(?:\s*:\s*[^:=\n]+)?\s*(?::=|=)\s*(-?\d+(?:\.\d+)?)'
    for match in re.finditer(pattern, text):
        result[match.group(1)] = _number(match.group(2))
    return result


def _action_params(body: str, script_path: str, weighted: bool) -> list[dict]:
    params = _script_defaults(script_path)
    for match in re.finditer(r'^([A-Za-z_][A-Za-z0-9_]*) = (-?\d+(?:\.\d+)?)$', body, re.M):
        if match.group(1) != "type":
            params[match.group(1)] = _number(match.group(2))
    if weighted:
        params.setdefault("chance_weight", 0.0)
        params.setdefault("max_consecutive_uses", 2)
    ordered = sorted(params.items(), key=lambda item: (PARAM_PRIORITY.get(item[0], 15), item[0]))
    return [{"name": key, "value": value} for key, value in ordered[:MAX_PARAMS]]


def parse_file(res_path: str, users: list[str] | None = None) -> dict:
    rel_path = "game-demo/" + res_path.removeprefix("res://")
    path = ROOT / rel_path
    text = path.read_text(encoding="utf-8")
    ext = _ext_resources(text)
    sequence_match = re.search(r'fixed_sequence = Array\[int\]\(\[([^\]]*)\]\)', text)
    sequence = sequence_match.group(1).strip() if sequence_match else ""
    actions = []
    for match in re.finditer(r'\[node name="([^"]+)" type="Node" parent="\."\](.*?)(?=\n\[|\Z)', text, re.S):
        node_name, body = match.group(1), match.group(2)
        script_match = re.search(r'script = ExtResource\("([^"]+)"\)', body)
        if not script_match:
            continue
        script_path = ext.get(script_match.group(1), {}).get("path", "")
        type_match = re.search(r'^type = (\d+)', body, re.M)
        weighted = bool(type_match and int(type_match.group(1)) == 1)
        actions.append({
            "node": node_name,
            "script": script_path.split("/")[-1].removesuffix(".gd"),
            "script_path": script_path,
            "type": TYPE_WEIGHTED if weighted else TYPE_CONDITIONAL,
            "params": _action_params(body, script_path, weighted),
        })
    return {"name": path.stem, "file": rel_path, "res_path": res_path,
            "users": "、".join(users or []), "sequence": sequence, "actions": actions}


def parse_all() -> list[dict]:
    users = et.ai_users()
    return [parse_file(path, names) for path, names in sorted(users.items())]


def _render_number(value: int | float) -> str:
    number = float(value)
    return str(int(number)) if number.is_integer() else f"{number:.4f}".rstrip("0").rstrip(".")


def _set_sequence(text: str, sequence: str) -> str:
    clean = ", ".join(re.findall(r"-?\d+", str(sequence)))
    pattern = re.compile(r'(fixed_sequence = Array\[int\]\(\[)[^\]]*(\]\))')
    if pattern.search(text):
        return pattern.sub(lambda match: match.group(1) + clean + match.group(2), text, count=1)
    if not clean:
        return text
    root = re.search(r'(\[node name="[^"]+" type="Node"\].*?^script = ExtResource\("[^"]+"\)\n)', text, re.M | re.S)
    return text[:root.end()] + f"fixed_sequence = Array[int]([{clean}])\n" + text[root.end():] if root else text


def _set_node_param(text: str, node_name: str, key: str, value: int | float) -> tuple[str, int | float | None]:
    pattern = re.compile(r'(\[node name="' + re.escape(node_name) + r'" type="Node" parent="\."\]\n)(.*?)(?=\n\[|\Z)', re.S)
    old_value: int | float | None = None

    def replace(match: re.Match) -> str:
        nonlocal old_value
        header, body = match.group(1), match.group(2)
        field_pattern = re.compile(r'^' + re.escape(key) + r' = (-?\d+(?:\.\d+)?)$', re.M)
        found = field_pattern.search(body)
        if found:
            old_value = _number(found.group(1))
            body = field_pattern.sub(f"{key} = {_render_number(value)}", body, count=1)
        else:
            body = body.rstrip() + f"\n{key} = {_render_number(value)}\n"
        return header + body

    return pattern.sub(replace, text, count=1), old_value


def _sync_static_intent(text: str, node_name: str, old_value: int | float | None, new_value: int | float) -> str:
    if old_value is None or old_value == new_value:
        return text
    node = re.search(r'\[node name="' + re.escape(node_name) + r'" type="Node" parent="\."\].*?intent = SubResource\("([^"]+)"\)', text, re.S)
    if not node:
        return text
    sub_id = node.group(1)
    pattern = re.compile(r'(\[sub_resource type="Resource" id="' + re.escape(sub_id) + r'"\].*?^base_text = ")([^"]*)(")', re.M | re.S)

    def replace(match: re.Match) -> str:
        label = match.group(2)
        if "%s" in label:
            return match.group(0)
        label = re.sub(r'(?<!\d)' + re.escape(_render_number(old_value)) + r'(?!\d)', _render_number(new_value), label, count=1)
        return match.group(1) + label + match.group(3)
    return pattern.sub(replace, text, count=1)


def write_file(rel_path: str, sequence: str, actions: list[dict]) -> bool:
    path = ROOT / rel_path
    text = path.read_text(encoding="utf-8")
    original = text
    text = _set_sequence(text, sequence)
    effective = {action["node"]: {param["name"]: param["value"] for param in action["params"]}
                 for action in parse_file("res://" + rel_path.removeprefix("game-demo/"))["actions"]}
    for action in actions:
        for param in action.get("params", []):
            old_effective = effective.get(action["node"], {}).get(param["name"])
            if old_effective is not None and float(old_effective) == float(param["value"]):
                continue
            text, old = _set_node_param(text, action["node"], param["name"], param["value"])
            if param["name"] in {"damage", "block", "base_damage"}:
                text = _sync_static_intent(text, action["node"], old if old is not None else old_effective, param["value"])
    if text == original:
        return False
    path.write_text(text, encoding="utf-8")
    return True
