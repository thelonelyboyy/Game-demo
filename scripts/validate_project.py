#!/usr/bin/env python3
"""Lightweight project validation for resource references and card data."""

from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = REPO_ROOT / "game-demo"

CARD_ROOTS = [PROJECT_ROOT / "common_cards", PROJECT_ROOT / "fusion_cards"]
CARD_ROOTS.extend(sorted((PROJECT_ROOT / "characters").glob("*/cards")))

TEXT_SUFFIXES = {".gd", ".tscn", ".tres", ".godot", ".import", ".cfg"}
SKIP_DIRS = {".git", ".godot", ".mono", "__pycache__"}
RES_PATH_RE = re.compile(r"res://[^\"'\\)\\]\\s]+")
EXT_RESOURCE_RE = re.compile(r'\[ext_resource[^\]]*type="Script"[^\]]*path="([^"]+)"[^\]]*id="([^"]+)"')
PROPERTY_RE = re.compile(r"^(\w+) = (.*)$")

LEGACY_EFFECT_FIELDS = {
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
ALLOWED_EFFECTLESS_CARD_IDS = {"toxin", "heart_demon", "eclipse_scar", "underworld_writ"}
EXPECTED_PROFESSION_TAGS = {
    "beastmaster": ("兽系", "兽群"),
    "body_cultivator": ("金身", "血炼"),
    "demonic_cultivator": ("献祭", "魂印"),
    "sword_cultivator": ("过牌", "铸剑"),
}


@dataclass
class Issue:
    level: str
    path: Path | None
    message: str

    def render(self) -> str:
        if self.path:
            return f"{self.level}: {self.path.relative_to(REPO_ROOT)} - {self.message}"
        return f"{self.level}: {self.message}"


def iter_project_files() -> list[Path]:
    files: list[Path] = []
    for path in PROJECT_ROOT.rglob("*"):
        if not path.is_file():
            continue
        if any(part in SKIP_DIRS for part in path.relative_to(PROJECT_ROOT).parts):
            continue
        files.append(path)
    return files


def iter_text_files() -> list[Path]:
    return [path for path in iter_project_files() if path.suffix in TEXT_SUFFIXES]


def iter_card_files() -> list[Path]:
    files: list[Path] = []
    for root in CARD_ROOTS:
        if root.exists():
            files.extend(sorted(root.rglob("*.tres")))
    return files


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def normalize_res_path(raw_path: str) -> str | None:
    value = raw_path.split("::", 1)[0].split("#", 1)[0].rstrip(".,;")
    if "%" in value or "{" in value or "}" in value:
        return None
    return value


def res_to_path(res_path: str) -> Path:
    return PROJECT_ROOT / res_path.removeprefix("res://")


def parse_properties(text: str) -> dict[str, str]:
    properties: dict[str, str] = {}
    in_resource = False
    for line in text.splitlines():
        if line.strip() == "[resource]":
            in_resource = True
            continue
        if not in_resource:
            continue
        match = PROPERTY_RE.match(line)
        if match:
            properties[match.group(1)] = match.group(2).strip()
    return properties


def strip_godot_string(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == '"' and value[-1] == '"':
        return value[1:-1]
    return value


def extract_ext_resource_paths(text: str) -> list[str]:
    return re.findall(r'\[ext_resource[^\]]*path="([^"]+)"', text)


def parse_int(value: str, fallback: int | None = None) -> int | None:
    try:
        return int(value)
    except ValueError:
        return fallback


def card_script_path(text: str, properties: dict[str, str]) -> str | None:
	scripts = {match.group(2): match.group(1) for match in EXT_RESOURCE_RE.finditer(text)}
	match = re.match(r'ExtResource\("([^"]+)"\)', properties.get("script", ""))
	if not match:
		return None
	return scripts.get(match.group(1))


def has_configured_effects(properties: dict[str, str]) -> bool:
    value = properties.get("configured_effects", "")
    return "SubResource(" in value


def has_nonzero_legacy_field(properties: dict[str, str]) -> bool:
    for key in LEGACY_EFFECT_FIELDS:
        value = properties.get(key)
        if value is None:
            continue
        if value not in {"0", "false"}:
            return True
    return False


def validate_resource_references(issues: list[Issue]) -> None:
    missing: dict[str, list[Path]] = defaultdict(list)
    for path in iter_text_files():
        text = read_text(path)
        for raw_res_path in RES_PATH_RE.findall(text):
            res_path = normalize_res_path(raw_res_path)
            if not res_path:
                continue
            if not res_to_path(res_path).exists():
                missing[res_path].append(path)

    for res_path, owners in sorted(missing.items()):
        owner_list = ", ".join(str(owner.relative_to(REPO_ROOT)) for owner in owners[:3])
        if len(owners) > 3:
            owner_list += f", +{len(owners) - 3} more"
        issues.append(Issue("ERROR", None, f"Missing resource {res_path} referenced by {owner_list}"))


def validate_cards(issues: list[Issue]) -> None:
    ids: dict[str, list[Path]] = defaultdict(list)
    effectless_cards: list[Path] = []

    for path in iter_card_files():
        text = read_text(path)
        properties = parse_properties(text)
        script_path = card_script_path(text, properties)

        if script_path != "res://custom_resources/cultivation_card.gd":
            issues.append(Issue("ERROR", path, f"Card resource script is {script_path or 'missing'}, expected CultivationCard"))

        card_id = strip_godot_string(properties.get("id", ""))
        if not card_id:
            issues.append(Issue("ERROR", path, "Missing card id"))
        else:
            ids[card_id].append(path)

        required_ints = {
            "type": (0, 2),
            "rarity": (0, 3),
            "target": (0, 3),
            # cost == -1 is the project convention for X-cost cards.
            "cost": (-1, 99),
        }
        for key, (low, high) in required_ints.items():
            val = properties.get(key, "0")
            parsed = parse_int(val)
            if parsed is None or parsed < low or parsed > high:
                issues.append(Issue("ERROR", path, f"Invalid {key}: {val}"))

        if has_nonzero_legacy_field(properties):
            issues.append(Issue("ERROR", path, "Legacy effect fields remain; migrate to configured_effects"))
        elif not has_configured_effects(properties) and card_id not in ALLOWED_EFFECTLESS_CARD_IDS:
            effectless_cards.append(path)

    for card_id, paths in sorted(ids.items()):
        if len(paths) <= 1:
            continue
        owners = ", ".join(str(path.relative_to(REPO_ROOT)) for path in paths)
        issues.append(Issue("ERROR", None, f"Duplicate card id {card_id}: {owners}"))

    for path in effectless_cards[:20]:
        issues.append(Issue("WARN", path, "Card has no configured_effects and no legacy effect fields"))
    if len(effectless_cards) > 20:
        issues.append(Issue("WARN", None, f"{len(effectless_cards) - 20} more effectless card(s) omitted"))


def validate_old_card_scripts(issues: list[Issue]) -> None:
    for cards_dir in sorted((PROJECT_ROOT / "characters").glob("*/cards")):
        for path in sorted(cards_dir.rglob("*.gd")):
            text = read_text(path)
            if re.search(r"^\s*func\s+apply_effects\b", text, re.M):
                issues.append(Issue("ERROR", path, "Old card script implements apply_effects"))
            if "extends CultivationCard" not in text:
                issues.append(Issue("ERROR", path, "Compatibility card script should extend CultivationCard"))


def validate_save_migrations(issues: list[Issue]) -> None:
    path = PROJECT_ROOT / "custom_resources" / "save_game.gd"
    if not path.exists():
        issues.append(Issue("ERROR", path, "Missing save_game.gd"))
        return
    for raw_res_path in RES_PATH_RE.findall(read_text(path)):
        res_path = normalize_res_path(raw_res_path)
        if res_path and not res_to_path(res_path).exists():
            issues.append(Issue("ERROR", path, f"Save migration references missing {res_path}"))


def validate_content_scale(issues: list[Issue]) -> None:
    enemy_count = len(list((PROJECT_ROOT / "enemies").rglob("*.tres")))
    battle_count = len([path for path in (PROJECT_ROOT / "battles").glob("*.tres") if path.name != "battle_stats_pool.tres"])
    event_root = PROJECT_ROOT / "scenes" / "event_rooms"
    event_count = len([path for path in event_root.rglob("*.tscn") if path.name.endswith("_event.tscn")]) if event_root.exists() else 0
    relic_count = len(list((PROJECT_ROOT / "relics").glob("*.tres")))

    if enemy_count < 19:
        issues.append(Issue("WARN", None, f"Enemy resources below demo goal: {enemy_count}/19"))
    if battle_count < 19:
        issues.append(Issue("WARN", None, f"Battle resources below demo goal: {battle_count}/19"))
    if event_count < 30:
        issues.append(Issue("WARN", None, f"Event scenes below demo goal: {event_count}/30"))
    if relic_count < 20:
        issues.append(Issue("WARN", None, f"Relic resources are thin for a long demo: {relic_count}"))


def validate_battle_pool_tiers(issues: list[Issue]) -> None:
    pool_path = PROJECT_ROOT / "battles" / "battle_stats_pool.tres"
    if not pool_path.exists():
        issues.append(Issue("ERROR", pool_path, "Missing battle_stats_pool.tres"))
        return

    battle_refs = [
        res_path
        for res_path in extract_ext_resource_paths(read_text(pool_path))
        if res_path.startswith("res://battles/") and res_path.endswith(".tres")
    ]
    tier_counts: dict[int, int] = defaultdict(int)
    for res_path in battle_refs:
        path = res_to_path(res_path)
        if not path.exists():
            issues.append(Issue("ERROR", pool_path, f"Battle pool references missing battle {res_path}"))
            continue
        tier = parse_int(parse_properties(read_text(path)).get("battle_tier", ""))
        if tier is None or tier < 0 or tier > 2:
            issues.append(Issue("ERROR", path, "Battle has invalid battle_tier"))
            continue
        tier_counts[tier] += 1

    required_counts = {0: 10, 1: 5, 2: 4}
    for tier, required in required_counts.items():
        if tier_counts[tier] < required:
            issues.append(Issue("ERROR", pool_path, f"Battle tier {tier} pool too small: {tier_counts[tier]}/{required}"))

    map_generator_path = PROJECT_ROOT / "scenes" / "map" / "map_generator.gd"
    map_generator_text = read_text(map_generator_path) if map_generator_path.exists() else ""
    for tier in required_counts:
        # 章节缩放后多数 tier 通过 _battle_for_room(tier) 包装请求；精英 tier 仍直接取池
        requests_tier = (
            f"get_random_battle_for_tier({tier})" in map_generator_text
            or f"_battle_for_room({tier})" in map_generator_text
        )
        if not requests_tier:
            issues.append(Issue("ERROR", map_generator_path, f"Map generator does not request battle tier {tier}"))


def validate_relic_trigger_coverage(issues: list[Issue]) -> None:
    relic_text = "\n".join(read_text(path) for path in sorted((PROJECT_ROOT / "relics").glob("*.tres")))
    required_scripts = {
        "res://relics/effects/card_play_damage_relic.gd": "card-play damage relic",
        "res://relics/effects/card_play_draw_relic.gd": "card-play draw relic",
        "res://relics/effects/player_hit_block_relic.gd": "damage-taken relic",
        "res://relics/effects/self_damage_relic.gd": "self-damage relic",
        "res://relics/effects/enemy_kill_relic.gd": "enemy-kill relic",
        "res://relics/effects/campfire_relic.gd": "campfire relic",
        "res://relics/effects/event_choice_relic.gd": "event-choice relic",
    }
    for script_path, label in required_scripts.items():
        if script_path not in relic_text:
            issues.append(Issue("ERROR", None, f"Missing build-defining relic trigger: {label} ({script_path})"))


def validate_profession_content(issues: list[Issue]) -> None:
    characters_root = PROJECT_ROOT / "characters"
    for profession_dir_name, expected_tags in EXPECTED_PROFESSION_TAGS.items():
        profession_root = characters_root / profession_dir_name
        card_paths = sorted((profession_root / "cards").rglob("*.tres"))
        if len(card_paths) < 20:
            issues.append(Issue("ERROR", profession_root, f"Profession card pool is too small: {len(card_paths)}/20"))

        combined_cards = "\n".join(read_text(path) for path in card_paths)
        for tag in expected_tags:
            if f'"{tag}"' not in combined_cards:
                issues.append(Issue("ERROR", profession_root, f"Missing defining mechanic tag {tag}"))

        starting_deck_path = profession_root / f"{profession_dir_name}_starting_deck.tres"
        if not starting_deck_path.exists():
            issues.append(Issue("ERROR", starting_deck_path, "Missing profession starting deck"))
        else:
            starting_refs = extract_ext_resource_paths(read_text(starting_deck_path))
            profession_refs = [path for path in starting_refs if f"characters/{profession_dir_name}/cards/" in path]
            if len(set(profession_refs)) < 2:
                issues.append(Issue("ERROR", starting_deck_path, "Starting deck should include at least two profession cards"))

        draftable_path = profession_root / f"{profession_dir_name}_draftable_cards.tres"
        if not draftable_path.exists():
            issues.append(Issue("ERROR", draftable_path, "Missing profession draftable card pile"))
        else:
            draft_refs = extract_ext_resource_paths(read_text(draftable_path))
            profession_refs = [path for path in draft_refs if f"characters/{profession_dir_name}/cards/" in path]
            if len(set(profession_refs)) < 20:
                issues.append(Issue("ERROR", draftable_path, f"Draftable pile has too few unique profession cards: {len(set(profession_refs))}/20"))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict-content", action="store_true", help="Treat content scale gaps as errors.")
    args = parser.parse_args()

    if not PROJECT_ROOT.exists():
        print(f"ERROR: Project root not found: {PROJECT_ROOT}", file=sys.stderr)
        return 2

    issues: list[Issue] = []
    validate_resource_references(issues)
    validate_cards(issues)
    validate_old_card_scripts(issues)
    validate_save_migrations(issues)
    validate_content_scale(issues)
    validate_battle_pool_tiers(issues)
    validate_relic_trigger_coverage(issues)
    validate_profession_content(issues)

    if args.strict_content:
        for issue in issues:
            if issue.level == "WARN" and ("below demo goal" in issue.message or "thin" in issue.message):
                issue.level = "ERROR"

    errors = [issue for issue in issues if issue.level == "ERROR"]
    warnings = [issue for issue in issues if issue.level == "WARN"]

    print(f"Project validation: {len(errors)} error(s), {len(warnings)} warning(s)")
    for issue in issues:
        print(issue.render())

    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
