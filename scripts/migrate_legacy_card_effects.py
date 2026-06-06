#!/usr/bin/env python3
"""Migrate legacy CultivationCard numeric fields to configured_effects subresources."""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = REPO_ROOT / "game-demo"

CARD_ROOTS = [
    PROJECT_ROOT / "common_cards",
    PROJECT_ROOT / "fusion_cards",
]
CARD_ROOTS.extend(sorted((PROJECT_ROOT / "characters").glob("*/cards")))

LEGACY_FIELDS = {
    "base_damage",
    "base_block",
    "cards_to_draw",
    "muscle_stacks",
    "qi_flow_stacks",
    "exposed_duration",
    "self_damage",
    "forge_sword_stacks",
    "consume_forge_for_damage",
    "gold_body_stacks",
    "blood_refine_bonus_damage",
    "soul_mark_stacks",
    "spirit_beast_stacks",
    "beast_pack_stacks",
}

EFFECT_SCRIPTS = {
    "damage": "res://custom_resources/effects/configured_damage_effect.gd",
    "block": "res://custom_resources/effects/configured_block_effect.gd",
    "draw": "res://custom_resources/effects/configured_draw_effect.gd",
    "self_damage": "res://custom_resources/effects/configured_self_damage_effect.gd",
    "status": "res://custom_resources/effects/configured_status_effect.gd",
    "consume_status": "res://custom_resources/effects/consume_status_effect.gd",
    "low_health_damage": "res://custom_resources/effects/low_health_bonus_damage_effect.gd",
}

STATUS_PATHS = {
    "muscle": "res://statuses/muscle.tres",
    "qi_flow": "res://statuses/qi_flow.tres",
    "exposed": "res://statuses/exposed.tres",
    "forge_sword": "res://statuses/forge_sword.tres",
    "gold_body": "res://statuses/gold_body.tres",
    "soul_mark": "res://statuses/soul_mark.tres",
    "spirit_beast": "res://statuses/spirit_beast.tres",
    "beast_pack": "res://statuses/beast_pack.tres",
}


@dataclass
class EffectSpec:
    kind: str
    fields: list[tuple[str, str | int | float | bool]]


def iter_card_files() -> list[Path]:
    files: list[Path] = []
    for root in CARD_ROOTS:
        if root.exists():
            files.extend(sorted(root.rglob("*.tres")))
    return files


def parse_resource_properties(text: str) -> dict[str, str]:
    properties: dict[str, str] = {}
    in_resource = False
    for line in text.splitlines():
        if line.strip() == "[resource]":
            in_resource = True
            continue
        if not in_resource:
            continue
        match = re.match(r"^(\w+) = (.*)$", line)
        if match:
            properties[match.group(1)] = match.group(2).strip()
    return properties


def parse_int(properties: dict[str, str], key: str) -> int:
    value = properties.get(key, "0")
    try:
        return int(value)
    except ValueError:
        return 0


def parse_bool(properties: dict[str, str], key: str) -> bool:
    return properties.get(key, "false").lower() == "true"


def find_configured_effects_line(text: str) -> str | None:
    match = re.search(r"^configured_effects = Array\[Resource\]\(\[.*?\]\)", text, re.M)
    return match.group(0) if match else None


def has_configured_effects(text: str) -> bool:
    line = find_configured_effects_line(text)
    return bool(line and "SubResource(" in line)


def make_effect_specs(properties: dict[str, str]) -> list[EffectSpec]:
    specs: list[EffectSpec] = []

    base_damage = parse_int(properties, "base_damage")
    blood_bonus = parse_int(properties, "blood_refine_bonus_damage")
    target = parse_int(properties, "target")
    target_mode = 2 if target == 2 else 0

    if base_damage > 0 and blood_bonus > 0:
        fields: list[tuple[str, str | int | float | bool]] = [
            ("amount", base_damage),
            ("bonus_amount", blood_bonus),
        ]
        if target_mode != 0:
            fields.append(("target_mode", target_mode))
        specs.append(EffectSpec("low_health_damage", fields))
    elif base_damage > 0:
        fields = [("amount", base_damage)]
        if target_mode != 0:
            fields.append(("target_mode", target_mode))
        specs.append(EffectSpec("damage", fields))

    simple_effects = [
        ("base_block", "block"),
        ("cards_to_draw", "draw"),
        ("self_damage", "self_damage"),
    ]
    for field_name, effect_kind in simple_effects:
        value = parse_int(properties, field_name)
        if value <= 0:
            continue
        fields = [("amount", value)]
        if effect_kind == "self_damage":
            fields.append(("affected_by_spirit_root", False))
        specs.append(EffectSpec(effect_kind, fields))

    status_fields = [
        ("muscle_stacks", "muscle", 1, False),
        ("qi_flow_stacks", "qi_flow", 1, False),
        ("exposed_duration", "exposed", 0, True),
        ("forge_sword_stacks", "forge_sword", 1, False),
        ("gold_body_stacks", "gold_body", 1, False),
        ("soul_mark_stacks", "soul_mark", 0, False),
        ("spirit_beast_stacks", "spirit_beast", 1, False),
        ("beast_pack_stacks", "beast_pack", 1, False),
    ]
    for field_name, status_id, status_target_mode, use_duration in status_fields:
        value = parse_int(properties, field_name)
        if value <= 0:
            continue
        fields = [
            ("status", f'ExtResource("{status_ext_id(status_id)}")'),
            ("target_mode", status_target_mode),
            ("use_duration", use_duration),
            ("amount", value),
        ]
        specs.append(EffectSpec("status", fields))

    if parse_bool(properties, "consume_forge_for_damage"):
        fields = [
            ("status_id", "forge_sword"),
            ("consume_all", True),
            ("value_per_stack", 1),
            ("convert_to", 0),
        ]
        if target_mode != 0:
            fields.append(("target_mode", target_mode))
        specs.append(EffectSpec("consume_status", fields))

    return specs


def effect_ext_id(kind: str) -> str:
    return f"auto_effect_{kind}"


def status_ext_id(status_id: str) -> str:
    return f"auto_status_{status_id}"


def subresource_id(index: int, spec: EffectSpec) -> str:
    return f"AutoEffect_{index}_{spec.kind}"


def value_to_godot(value: str | int | float | bool) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        return str(value)
    if value.startswith('ExtResource("'):
        return value
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def existing_ext_resource_paths(text: str) -> set[str]:
    return set(re.findall(r'\[ext_resource[^\]]*path="([^"]+)"', text))


def build_ext_resource_lines(text: str, specs: list[EffectSpec]) -> list[str]:
    existing_paths = existing_ext_resource_paths(text)
    lines: list[str] = []

    for kind in sorted({spec.kind for spec in specs}):
        path = EFFECT_SCRIPTS[kind]
        if path not in existing_paths:
            lines.append(f'[ext_resource type="Script" path="{path}" id="{effect_ext_id(kind)}"]')
            existing_paths.add(path)

    for spec in specs:
        for key, value in spec.fields:
            if key != "status" or not isinstance(value, str):
                continue
            match = re.match(r'ExtResource\("auto_status_(.+)"\)', value)
            if not match:
                continue
            status_id = match.group(1)
            path = STATUS_PATHS[status_id]
            if path not in existing_paths:
                lines.append(f'[ext_resource type="Resource" path="{path}" id="{status_ext_id(status_id)}"]')
                existing_paths.add(path)

    return lines


def build_subresources(specs: list[EffectSpec]) -> list[str]:
    lines: list[str] = []
    for index, spec in enumerate(specs, start=1):
        lines.append(f'[sub_resource type="Resource" id="{subresource_id(index, spec)}"]')
        lines.append(f'script = ExtResource("{effect_ext_id(spec.kind)}")')
        for key, value in spec.fields:
            lines.append(f"{key} = {value_to_godot(value)}")
        lines.append("")
    return lines


def insert_effect_resources(text: str, extra_ext_lines: list[str], subresource_lines: list[str]) -> str:
    resource_index = text.index("[resource]")
    before_resource = text[:resource_index].rstrip()
    resource_and_after = text[resource_index:]

    additions: list[str] = []
    if extra_ext_lines:
        additions.extend(extra_ext_lines)
    if subresource_lines:
        if additions:
            additions.append("")
        additions.extend(subresource_lines)

    if additions:
        return before_resource + "\n" + "\n".join(additions).rstrip() + "\n\n" + resource_and_after
    return text


def configured_effects_line(specs: list[EffectSpec]) -> str:
    refs = ", ".join(f'SubResource("{subresource_id(index, spec)}")' for index, spec in enumerate(specs, start=1))
    return f"configured_effects = Array[Resource]([{refs}])"


def remove_legacy_fields_and_add_array(text: str, specs: list[EffectSpec]) -> str:
    lines = text.splitlines()
    output: list[str] = []
    inserted = False
    in_resource = False
    effect_line = configured_effects_line(specs)
    for line in lines:
        if line.strip() == "[resource]":
            in_resource = True
            output.append(line)
            continue
        match = re.match(r"^(\w+) = .*$", line)
        if match and match.group(1) == "configured_effects":
            continue
        if in_resource and match and match.group(1) in LEGACY_FIELDS:
            continue
        output.append(line)
        if in_resource and line.startswith("script = ExtResource(") and not inserted:
            output.append(effect_line)
            inserted = True
    return "\n".join(output) + "\n"


def repair_configured_effects_location(path: Path, dry_run: bool) -> bool:
    text = path.read_text(encoding="utf-8")
    effect_line = find_configured_effects_line(text)
    if not effect_line:
        return False

    lines = text.splitlines()
    in_resource = False
    line_in_resource = False
    for line in lines:
        if line.strip() == "[resource]":
            in_resource = True
            continue
        if line == effect_line and in_resource:
            line_in_resource = True
            break

    if line_in_resource:
        return False

    output: list[str] = []
    in_resource = False
    inserted = False
    for line in lines:
        if line == effect_line:
            continue
        if line.strip() == "[resource]":
            in_resource = True
            output.append(line)
            continue
        output.append(line)
        if in_resource and line.startswith("script = ExtResource(") and not inserted:
            output.append(effect_line)
            inserted = True

    if not inserted:
        return False

    if not dry_run:
        path.write_text("\n".join(output) + "\n", encoding="utf-8", newline="\n")
    return True


def refresh_load_steps(text: str) -> str:
    ext_count = len(re.findall(r"^\[ext_resource\b", text, re.M))
    sub_count = len(re.findall(r"^\[sub_resource\b", text, re.M))
    load_steps = ext_count + sub_count + 1
    return re.sub(r"load_steps=\d+", f"load_steps={load_steps}", text, count=1)


def migrate_file(path: Path, dry_run: bool) -> bool:
    text = path.read_text(encoding="utf-8")
    if repair_configured_effects_location(path, dry_run):
        return True

    if has_configured_effects(text):
        return False

    properties = parse_resource_properties(text)
    if properties.get("script", "") == "":
        return False

    specs = make_effect_specs(properties)
    if not specs:
        return False

    text = insert_effect_resources(text, build_ext_resource_lines(text, specs), build_subresources(specs))
    text = remove_legacy_fields_and_add_array(text, specs)
    text = refresh_load_steps(text)

    if not dry_run:
        path.write_text(text, encoding="utf-8", newline="\n")
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    changed: list[Path] = []
    for path in iter_card_files():
        if migrate_file(path, args.dry_run):
            changed.append(path)

    action = "Would migrate" if args.dry_run else "Migrated"
    print(f"{action} {len(changed)} card resource(s).")
    for path in changed:
        print(path.relative_to(REPO_ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
