"""Read/write GenericEvent scenes used by the unified game-data workbook."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = ROOT / "game-demo"
POOL = PROJECT_ROOT / "scenes" / "event_rooms" / "event_room_pool.tres"
MAX_CHOICES = 3
ROOT_NAMES = ["无", "金", "木", "水", "火", "土"]
EFFECT_TYPES = [
    "skip", "gain_gold", "lose_gold", "heal", "damage", "max_hp",
    "upgrade_random", "remove_random", "gain_random_card", "gain_rare_card",
    "gain_curse", "duplicate_last", "gamble_even", "gamble_risky",
    "duplicate_random", "purify_affliction", "transform_random",
    "heal_percent", "damage_percent", "gain_gold_per_missing_hp", "gain_gold_per_card",
]


def validate_effect(effect: str) -> bool:
    """Accept a base effect or a pipe-separated effect[:amount] sequence."""
    if not effect:
        return False
    for part in effect.split("|"):
        name, separator, amount = part.partition(":")
        if name not in EFFECT_TYPES:
            return False
        if separator and not re.fullmatch(r"-?\d+", amount):
            return False
    return True


def _decode_strings(raw: str) -> list[str]:
    return [json.loads(token) for token in re.findall(r'"(?:\\.|[^"\\])*"', raw)]


def _encode_strings(values: list[str]) -> str:
    return "PackedStringArray(" + ", ".join(json.dumps(str(v), ensure_ascii=False) for v in values) + ")"


def _ints(raw: str) -> list[int]:
    return [int(v) for v in re.findall(r"-?\d+", raw)]


def _field(text: str, key: str, default: str = "") -> str:
    m = re.search(rf'^{re.escape(key)} = "((?:\\.|[^"\\])*)"', text, re.M)
    return json.loads('"' + m.group(1) + '"') if m else default


def _array(text: str, key: str) -> list[str]:
    m = re.search(rf'^{re.escape(key)} = PackedStringArray\((.*)\)$', text, re.M)
    return _decode_strings(m.group(1)) if m else []


def _int_array(text: str, key: str) -> list[int]:
    m = re.search(rf'^{re.escape(key)} = PackedInt32Array\((.*)\)$', text, re.M)
    return _ints(m.group(1)) if m else []


def _pool_info() -> list[tuple[int, str]]:
    text = POOL.read_text(encoding="utf-8")
    id_to_path = {
        m.group(2): m.group(1)
        for m in re.finditer(r'\[ext_resource type="PackedScene" path="([^"]+)" id="([^"]+)"\]', text)
    }
    chapter_by_id: dict[str, int] = {}
    for chapter in (1, 2, 3):
        m = re.search(rf'^chapter_{chapter}_rooms = .*?\((.*)\)$', text, re.M)
        if m:
            for resource_id in re.findall(r'ExtResource\("([^"]+)"\)', m.group(1)):
                chapter_by_id[resource_id] = chapter
    event_m = re.search(r'^event_rooms = .*?\((.*)\)$', text, re.M)
    ids = re.findall(r'ExtResource\("([^"]+)"\)', event_m.group(1)) if event_m else []
    return [(chapter_by_id.get(resource_id, 0), id_to_path[resource_id]) for resource_id in ids]


def parse_all() -> list[dict]:
    rows: list[dict] = []
    for chapter, res_path in _pool_info():
        rel = "game-demo/" + res_path.removeprefix("res://")
        path = ROOT / rel
        text = path.read_text(encoding="utf-8")
        choices = _array(text, "choice_texts")
        effects = _array(text, "choice_effects")
        amounts = _int_array(text, "choice_amounts")
        ill_m = re.search(r'^event_illustration = ExtResource\("([^"]+)"\)', text, re.M)
        illustration = ""
        if ill_m:
            ext_m = re.search(rf'\[ext_resource type="Texture2D" path="([^"]+)" id="{re.escape(ill_m.group(1))}"\]', text)
            illustration = ext_m.group(1) if ext_m else ""
        index_m = re.search(r'^spirit_root_choice_index = (-?\d+)', text, re.M)
        rows.append({
            "chapter": chapter,
            "file": rel.replace("\\", "/"),
            "title": _field(text, "event_title"),
            "body": _field(text, "event_body"),
            "illustration": illustration,
            "choices": [
                {
                    "text": choices[i] if i < len(choices) else "",
                    "effect": effects[i] if i < len(effects) else "",
                    "amount": amounts[i] if i < len(amounts) else 0,
                }
                for i in range(MAX_CHOICES)
            ],
            "root_choice_index": int(index_m.group(1)) if index_m else -1,
            "root_texts": _array(text, "spirit_root_choice_texts"),
            "root_effects": _array(text, "spirit_root_choice_effects"),
            "root_amounts": _int_array(text, "spirit_root_choice_amounts"),
        })
    return rows


def _set_line(text: str, key: str, value: str) -> str:
    pattern = re.compile(rf'^{re.escape(key)} = .*$', re.M)
    replacement = f"{key} = {value}"
    if pattern.search(text):
        return pattern.sub(replacement, text, count=1)
    resource_pos = text.find("\n[node ")
    return text[:resource_pos] + replacement + "\n" + text[resource_pos:] if resource_pos >= 0 else text + "\n" + replacement + "\n"


def write_event(row: dict) -> bool:
    path = ROOT / str(row["file"])
    text = path.read_text(encoding="utf-8")
    new = _set_line(text, "event_title", json.dumps(str(row["title"]), ensure_ascii=False))
    new = _set_line(new, "event_body", json.dumps(str(row["body"]), ensure_ascii=False))
    choices = list(row.get("choices", [])[:MAX_CHOICES])
    while choices and not str(choices[-1].get("text", "")).strip() and not str(choices[-1].get("effect", "")).strip():
        choices.pop()
    new = _set_line(new, "choice_texts", _encode_strings([c.get("text", "") for c in choices]))
    new = _set_line(new, "choice_effects", _encode_strings([c.get("effect", "") for c in choices]))
    new = _set_line(new, "choice_amounts", "PackedInt32Array(" + ", ".join(str(int(c.get("amount", 0))) for c in choices) + ")")
    if new == text:
        return False
    path.write_text(new, encoding="utf-8")
    return True


def write_root_overrides(row: dict) -> bool:
    path = ROOT / str(row["file"])
    text = path.read_text(encoding="utf-8")
    new = _set_line(text, "spirit_root_choice_index", str(int(row.get("root_choice_index", -1))))
    new = _set_line(new, "spirit_root_choice_texts", _encode_strings(list(row.get("root_texts", []))))
    new = _set_line(new, "spirit_root_choice_effects", _encode_strings(list(row.get("root_effects", []))))
    new = _set_line(new, "spirit_root_choice_amounts", "PackedInt32Array(" + ", ".join(str(int(v)) for v in row.get("root_amounts", [])) + ")")
    if new == text:
        return False
    path.write_text(new, encoding="utf-8")
    return True
