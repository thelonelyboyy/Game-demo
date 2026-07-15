"""Read/write every EnemyStats resource exposed in game_data.xlsx."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENEMY_ROOT = ROOT / "game-demo" / "enemies"


def _resource(text: str) -> str:
    return text.split("[resource]", 1)[1] if "[resource]" in text else text


def _attrs(section: str) -> dict[str, str]:
    return dict(re.findall(r'(\w+)="([^"]*)"', section))


def _ext_resources(text: str) -> dict[str, dict[str, str]]:
    result: dict[str, dict[str, str]] = {}
    for match in re.finditer(r'\[ext_resource ([^\]]+)\]', text):
        attrs = _attrs(match.group(1))
        if "id" in attrs:
            result[attrs["id"]] = attrs
    return result


def _get_string(text: str, key: str) -> str:
    match = re.search(rf'^{re.escape(key)} = "((?:\\.|[^"\\])*)"', _resource(text), re.M)
    return json.loads('"' + match.group(1) + '"') if match else ""


def _get_number(text: str, key: str, default: int | float = 0) -> int | float:
    match = re.search(rf'^{re.escape(key)} = (-?\d+(?:\.\d+)?)', _resource(text), re.M)
    if not match:
        return default
    return float(match.group(1)) if "." in match.group(1) else int(match.group(1))


def _get_sequence(text: str, key: str) -> str:
    match = re.search(rf'^{re.escape(key)} = Array\[int\]\(\[([^\]]*)\]\)', _resource(text), re.M)
    return match.group(1).strip() if match else ""


def find_enemy_files() -> list[Path]:
    result = []
    for path in ENEMY_ROOT.rglob("*.tres"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        if 'script_class="EnemyStats"' in text or re.search(r'^display_name = ', _resource(text), re.M):
            result.append(path)
    return sorted(result)


def parse_file(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    resource = _resource(text)
    ext = _ext_resources(text)
    ai_match = re.search(r'^ai = ExtResource\("([^"]+)"\)', resource, re.M)
    ai_path = ext.get(ai_match.group(1), {}).get("path", "") if ai_match else ""
    status_paths: list[str] = []
    status_match = re.search(r'^starting_statuses = .*?\((.*)\)$', resource, re.M)
    if status_match:
        for resource_id in re.findall(r'ExtResource\("([^"]+)"\)', status_match.group(1)):
            status_path = ext.get(resource_id, {}).get("path", "")
            if status_path:
                status_paths.append(status_path)
    return {
        "file": path.relative_to(ROOT).as_posix(),
        "id": _get_string(text, "id"),
        "name": _get_string(text, "display_name"),
        "description": _get_string(text, "description"),
        "max_health": int(_get_number(text, "max_health", 1)),
        "ai_file": ai_path,
        "starting_statuses": ", ".join(status_paths),
        "phase_ratio": float(_get_number(text, "phase_two_health_ratio", 0.0)),
        "phase_name": _get_string(text, "phase_two_name"),
        "phase_block": int(_get_number(text, "phase_two_block", 0)),
        "phase_damage_bonus": float(_get_number(text, "phase_two_damage_bonus", 0.0)),
        "phase_sequence": _get_sequence(text, "phase_two_sequence"),
    }


def parse_all() -> list[dict]:
    return [parse_file(path) for path in find_enemy_files()]


def ai_users() -> dict[str, list[str]]:
    users: dict[str, list[str]] = {}
    for enemy in parse_all():
        if enemy["ai_file"]:
            users.setdefault(enemy["ai_file"], []).append(enemy["name"] or enemy["id"])
    return users


def enemy_by_id() -> dict[str, dict]:
    return {enemy["id"]: enemy for enemy in parse_all()}


def _render_number(value: int | float, decimal: bool = False) -> str:
    if not decimal:
        return str(int(value))
    number = float(value)
    return f"{number:.4f}".rstrip("0").rstrip(".") if not number.is_integer() else f"{number:.1f}"


def _set_resource_line(text: str, key: str, value: str) -> str:
    head, resource = text.split("[resource]", 1)
    pattern = re.compile(rf'^{re.escape(key)} = .*$', re.M)
    replacement = f"{key} = {value}"
    if pattern.search(resource):
        resource = pattern.sub(replacement, resource, count=1)
    else:
        resource = resource.rstrip() + "\n" + replacement + "\n"
    return head + "[resource]" + resource


def write_file(row: dict) -> bool:
    path = ROOT / str(row["file"])
    text = path.read_text(encoding="utf-8")
    new = text
    current = parse_file(path)
    values = [
        ("display_name", json.dumps(str(row["name"]), ensure_ascii=False), current["name"], str(row["name"])),
        ("description", json.dumps(str(row["description"]), ensure_ascii=False), current["description"], str(row["description"])),
        ("max_health", _render_number(row["max_health"]), current["max_health"], int(row["max_health"])),
        ("phase_two_health_ratio", _render_number(row["phase_ratio"], True), current["phase_ratio"], float(row["phase_ratio"] or 0)),
        ("phase_two_name", json.dumps(str(row["phase_name"]), ensure_ascii=False), current["phase_name"], str(row["phase_name"])),
        ("phase_two_block", _render_number(row["phase_block"]), current["phase_block"], int(row["phase_block"] or 0)),
        ("phase_two_damage_bonus", _render_number(row["phase_damage_bonus"], True), current["phase_damage_bonus"], float(row["phase_damage_bonus"] or 0)),
        ("phase_two_sequence", "Array[int]([" + str(row["phase_sequence"]).strip() + "])", current["phase_sequence"], str(row["phase_sequence"]).strip())
    ]
    for key, value, old_semantic, new_semantic in values:
        if old_semantic != new_semantic:
            new = _set_resource_line(new, key, value)
    if new == text:
        return False
    path.write_text(new, encoding="utf-8")
    return True
