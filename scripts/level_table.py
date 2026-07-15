"""Read/write battle encounter design data used by the active battle pool."""

from __future__ import annotations

import re
from pathlib import Path

try:
    import enemy_table as et
except ModuleNotFoundError:  # 支持作为 scripts.level_table 导入
    from scripts import enemy_table as et

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "game-demo"
POOL = PROJECT / "battles" / "battle_stats_pool.tres"
MAX_ENEMIES = 3
TIER = {0: "普通", 1: "精英", 2: "首领"}
TIER_R = {value: key for key, value in TIER.items()}


def _attrs(section: str) -> dict[str, str]:
    return dict(re.findall(r'(\w+)="([^"]*)"', section))


def _ext_lines(text: str) -> list[dict[str, str]]:
    result = []
    for match in re.finditer(r'\[ext_resource ([^\]]+)\]', text):
        attrs = _attrs(match.group(1))
        attrs["line"] = match.group(0)
        result.append(attrs)
    return result


def _resource(text: str) -> str:
    return text.split("[resource]", 1)[1] if "[resource]" in text else text


def _number(text: str, key: str, default: int | float = 0) -> int | float:
    match = re.search(rf'^{re.escape(key)} = (-?\d+(?:\.\d+)?)', _resource(text), re.M)
    if not match:
        return default
    return float(match.group(1)) if "." in match.group(1) else int(match.group(1))


def _scene_path(text: str) -> str:
    match = re.search(r'^enemies = ExtResource\("([^"]+)"\)', _resource(text), re.M)
    if not match:
        return ""
    for attrs in _ext_lines(text):
        if attrs.get("id") == match.group(1):
            return attrs.get("path", "")
    return ""


def _battle_paths() -> list[str]:
    text = POOL.read_text(encoding="utf-8")
    ext = {attrs.get("id", ""): attrs.get("path", "") for attrs in _ext_lines(text)}
    pool_match = re.search(r'^pool = .*?\((.*)\)$', _resource(text), re.M)
    ids = re.findall(r'ExtResource\("([^"]+)"\)', pool_match.group(1)) if pool_match else []
    return [ext[resource_id] for resource_id in ids if resource_id in ext]


def _scene_enemies(res_path: str) -> list[dict]:
    path = PROJECT / res_path.removeprefix("res://")
    text = path.read_text(encoding="utf-8")
    ext = {attrs.get("id", ""): attrs.get("path", "") for attrs in _ext_lines(text)}
    enemies_by_file = {enemy["file"].removeprefix("game-demo/"): enemy for enemy in et.parse_all()}
    result = []
    for node in re.finditer(r'\[node name="([^"]+)"[^\]]*parent="\."[^\]]*\](.*?)(?=\n\[|\Z)', text, re.S):
        stats = re.search(r'^stats = ExtResource\("([^"]+)"\)', node.group(2), re.M)
        if not stats:
            continue
        enemy_path = ext.get(stats.group(1), "").removeprefix("res://")
        enemy = enemies_by_file.get(enemy_path, {})
        result.append({"node": node.group(1), "resource_id": stats.group(1), "path": "res://" + enemy_path,
                       "id": enemy.get("id", ""), "name": enemy.get("name", "")})
    return result


def parse_all() -> list[dict]:
    rows = []
    for res_path in _battle_paths():
        file_path = PROJECT / res_path.removeprefix("res://")
        text = file_path.read_text(encoding="utf-8")
        scene = _scene_path(text)
        enemies = _scene_enemies(scene)
        rows.append({
            "file": "game-demo/" + res_path.removeprefix("res://"),
            "id": file_path.stem,
            "tier": TIER.get(int(_number(text, "battle_tier", 0)), "普通"),
            "chapter_min": int(_number(text, "chapter_min", 1)),
            "chapter_max": int(_number(text, "chapter_max", 3)),
            "weight": float(_number(text, "weight", 0.0)),
            "gold_min": int(_number(text, "gold_reward_min", 0)),
            "gold_max": int(_number(text, "gold_reward_max", 0)),
            "health_multiplier": float(_number(text, "enemy_health_multiplier", 1.0)),
            "damage_multiplier": float(_number(text, "enemy_damage_multiplier", 1.0)),
            "scene": scene,
            "enemy_count": len(enemies),
            "enemies": enemies,
            "encounter": " + ".join(enemy.get("name") or enemy.get("id", "") for enemy in enemies),
        })
    return rows


def _render(value: int | float, decimal: bool = False) -> str:
    if not decimal:
        return str(int(value))
    number = float(value)
    return f"{number:.4f}".rstrip("0").rstrip(".") if not number.is_integer() else f"{number:.1f}"


def _set_resource_number(text: str, key: str, value: int | float, decimal: bool = False) -> str:
    head, resource = text.split("[resource]", 1)
    pattern = re.compile(rf'^{re.escape(key)} = .*$', re.M)
    replacement = f"{key} = {_render(value, decimal)}"
    if not pattern.search(resource):
        resource = resource.rstrip() + "\n" + replacement + "\n"
    else:
        resource = pattern.sub(replacement, resource, count=1)
    return head + "[resource]" + resource


def _write_scene_composition(scene_path: str, enemy_ids: list[str]) -> bool:
    path = PROJECT / scene_path.removeprefix("res://")
    text = path.read_text(encoding="utf-8")
    original = text
    current_ids = [enemy["id"] for enemy in _scene_enemies(scene_path)]
    if current_ids == enemy_ids:
        return False
    nodes = []
    for node in re.finditer(r'(\[node name="([^"]+)"[^\]]*parent="\."[^\]]*\]\n)(.*?)(?=\n\[|\Z)', text, re.S):
        stats = re.search(r'^stats = ExtResource\("([^"]+)"\)', node.group(3), re.M)
        if stats:
            nodes.append((node.group(2), stats.group(1)))
    if len(enemy_ids) != len(nodes):
        raise ValueError(f"enemy slot count must stay {len(nodes)}")
    enemies = et.enemy_by_id()
    missing = [enemy_id for enemy_id in enemy_ids if enemy_id not in enemies]
    if missing:
        raise ValueError("unknown enemy id: " + ", ".join(missing))

    old_enemy_resource_ids = {resource_id for _, resource_id in nodes}
    ext_lines = _ext_lines(text)
    old_enemy_lines = [attrs["line"] for attrs in ext_lines if attrs.get("id") in old_enemy_resource_ids]
    unique_ids = list(dict.fromkeys(enemy_ids))
    new_resource_id = {enemy_id: f"xlsx_enemy_{index + 1}" for index, enemy_id in enumerate(unique_ids)}
    new_lines = []
    for enemy_id in unique_ids:
        res_path = enemies[enemy_id]["file"].removeprefix("game-demo/")
        new_lines.append(f'[ext_resource type="Resource" path="res://{res_path}" id="{new_resource_id[enemy_id]}"]')
    for line in old_enemy_lines:
        text = text.replace(line + "\n", "")
    insert_after = max((text.find(attrs["line"]) + len(attrs["line"]) for attrs in _ext_lines(text)), default=-1)
    if insert_after < 0:
        raise ValueError("scene has no ext_resource anchor")
    text = text[:insert_after] + "\n" + "\n".join(new_lines) + text[insert_after:]
    for (node_name, _old_id), enemy_id in zip(nodes, enemy_ids):
        pattern = re.compile(r'(\[node name="' + re.escape(node_name) + r'"[^\]]*parent="\."[^\]]*\].*?^stats = ExtResource\(")[^"]+("\))', re.M | re.S)
        text = pattern.sub(lambda match: match.group(1) + new_resource_id[enemy_id] + match.group(2), text, count=1)
    header = re.search(r'^\[gd_scene load_steps=(\d+)', text, re.M)
    if header:
        new_steps = int(header.group(1)) - len(old_enemy_lines) + len(new_lines)
        text = text[:header.start(1)] + str(new_steps) + text[header.end(1):]
    if text == original:
        return False
    path.write_text(text, encoding="utf-8")
    return True


def write_row(row: dict) -> int:
    path = ROOT / str(row["file"])
    text = path.read_text(encoding="utf-8")
    original = text
    for key, value, decimal, current_value in [
        ("battle_tier", TIER_R[str(row["tier"])], False, _number(text, "battle_tier", 0)),
        ("chapter_min", row["chapter_min"], False, _number(text, "chapter_min", 1)),
        ("chapter_max", row["chapter_max"], False, _number(text, "chapter_max", 3)),
        ("weight", row["weight"], True, _number(text, "weight", 0.0)),
        ("gold_reward_min", row["gold_min"], False, _number(text, "gold_reward_min", 0)),
        ("gold_reward_max", row["gold_max"], False, _number(text, "gold_reward_max", 0)),
        ("enemy_health_multiplier", row["health_multiplier"], True, _number(text, "enemy_health_multiplier", 1.0)),
        ("enemy_damage_multiplier", row["damage_multiplier"], True, _number(text, "enemy_damage_multiplier", 1.0)),
    ]:
        if float(value) != float(current_value):
            text = _set_resource_number(text, key, value, decimal)
    changed = 0
    if text != original:
        path.write_text(text, encoding="utf-8")
        changed += 1
    enemy_ids = [str(value).strip() for value in row.get("enemy_ids", []) if str(value).strip()]
    if _write_scene_composition(str(row["scene"]), enemy_ids):
        changed += 1
    return changed
