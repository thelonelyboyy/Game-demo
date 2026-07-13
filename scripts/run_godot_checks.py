#!/usr/bin/env python3
"""Run Godot headless smoke checks and fail only on actionable load/script errors."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = REPO_ROOT / "game-demo"
DEFAULT_GODOT = Path(
    r"F:\download\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64.exe"
)

CHECKS = [
    {"name": "main", "args": [], "quit": True},
    {"name": "character-selector", "args": ["res://scenes/ui/character_selector.tscn"], "quit": True},
    {"name": "codex", "args": ["res://test_data/codex_smoke.tscn"], "quit": False, "required_marker": "CODEX_SMOKE_OK"},
    {"name": "card-mechanics", "args": ["res://test_data/card_mechanics_smoke.tscn"], "quit": False, "required_marker": "CARD_MECHANICS_SMOKE_OK"},
    {"name": "card-reward-simulation", "args": ["res://test_data/card_reward_simulation_smoke.tscn"], "quit": False, "required_marker": "CARD_REWARD_SIMULATION_SMOKE_OK"},
    {"name": "content-progression", "args": ["res://test_data/content_progression_smoke.tscn"], "quit": False, "required_marker": "CONTENT_PROGRESSION_SMOKE_OK"},
    {"name": "battle", "args": ["res://scenes/battle/battle.tscn"], "quit": True},
    {"name": "map", "args": ["res://scenes/map/map.tscn"], "quit": True},
    {"name": "map-generation", "args": ["res://test_data/map_generation_smoke.tscn"], "quit": False, "required_marker": "MAP_GENERATION_SMOKE_OK"},
    {"name": "run-flow", "args": ["res://test_data/run_flow_smoke.tscn"], "quit": False, "required_marker": "RUN_FLOW_SMOKE_OK"},
    {"name": "boss-battle", "args": ["res://test_data/boss_battle_smoke.tscn"], "quit": False, "required_marker": "BOSS_BATTLE_SMOKE_OK"},
    {"name": "elite-tactics", "args": ["res://test_data/elite_tactics_smoke.tscn"], "quit": False, "required_marker": "ELITE_TACTICS_SMOKE_OK"},
    {"name": "normal-tactics", "args": ["res://test_data/normal_tactics_smoke.tscn"], "quit": False, "required_marker": "NORMAL_TACTICS_SMOKE_OK"},
    {"name": "status-ward", "args": ["res://test_data/status_ward_smoke.tscn"], "quit": False, "required_marker": "STATUS_WARD_SMOKE_OK"},
    {"name": "combat-debuff", "args": ["res://test_data/combat_debuff_smoke.tscn"], "quit": False, "required_marker": "COMBAT_DEBUFF_SMOKE_OK"},
    {"name": "debuff-counterplay", "args": ["res://test_data/debuff_counterplay_smoke.tscn"], "quit": False, "required_marker": "DEBUFF_COUNTERPLAY_SMOKE_OK"},
    {"name": "difficulty", "args": ["res://test_data/difficulty_smoke.tscn"], "quit": False, "required_marker": "DIFFICULTY_SMOKE_OK"},
    {"name": "demonic-card-suite", "args": ["res://test_data/demonic_card_suite_smoke.tscn"], "quit": False, "required_marker": "DEMONIC_CARD_SUITE_SMOKE_OK"},
    {"name": "demonic-relic", "args": ["res://test_data/demonic_relic_smoke.tscn"], "quit": False, "required_marker": "DEMONIC_RELIC_SMOKE_OK"},
    {"name": "demonic-pact-relic", "args": ["res://test_data/demonic_pact_relic_smoke.tscn"], "quit": False, "required_marker": "DEMONIC_PACT_RELIC_SMOKE_OK"},
    {"name": "relic-economy", "args": ["res://test_data/relic_economy_smoke.tscn"], "quit": False, "required_marker": "RELIC_ECONOMY_SMOKE_OK"},
    {"name": "universal-relic", "args": ["res://test_data/universal_relic_smoke.tscn"], "quit": False, "required_marker": "UNIVERSAL_RELIC_SMOKE_OK"},
    {"name": "boss-relic", "args": ["res://test_data/boss_relic_smoke.tscn"], "quit": False, "required_marker": "BOSS_RELIC_SMOKE_OK"},
    {"name": "event-progression", "args": ["res://test_data/event_progression_smoke.tscn"], "quit": False, "required_marker": "EVENT_PROGRESSION_SMOKE_OK"},
    {"name": "fusion-suite", "args": ["res://test_data/fusion_suite_smoke.tscn"], "quit": False, "required_marker": "FUSION_SUITE_SMOKE_OK"},
    {"name": "potion-economy", "args": ["res://test_data/potion_economy_smoke.tscn"], "quit": False, "required_marker": "POTION_ECONOMY_SMOKE_OK"},
    {"name": "run-history", "args": ["res://test_data/run_history_smoke.tscn"], "quit": False, "required_marker": "RUN_HISTORY_SMOKE_OK"},
    {"name": "campfire-choices", "args": ["res://test_data/campfire_choices_smoke.tscn"], "quit": False, "required_marker": "CAMPFIRE_CHOICES_SMOKE_OK"},
]
CHECK_TIMEOUT_SECONDS = 90

IGNORED_ERROR_FRAGMENTS = [
    "ObjectDB instances leaked at exit",
    "resources still in use at exit",
    "Resource still in use: res://custom_resources/room.gd",
    "RID allocations of type",
    "were leaked at exit",
]

FATAL_FRAGMENTS = [
    "SCRIPT ERROR:",
    "Parse Error:",
    "Failed loading resource:",
    "Failed to load script",
    "ERROR:",
]


def is_ignored_error(line: str) -> bool:
    return any(fragment in line for fragment in IGNORED_ERROR_FRAGMENTS)


def find_fatal_lines(output: str) -> list[str]:
    fatal: list[str] = []
    for line in output.splitlines():
        if is_ignored_error(line):
            continue
        if any(fragment in line for fragment in FATAL_FRAGMENTS):
            fatal.append(line)
    return fatal


def run_check(godot: Path, check: dict) -> tuple[bool, str]:
    name = str(check["name"])
    extra_args = list(check["args"])
    command = [str(godot), "--headless", "--path", str(PROJECT_ROOT), *extra_args]
    if check.get("quit", True):
        command.append("--quit")
    try:
        completed = subprocess.run(
            command,
            cwd=REPO_ROOT,
            text=True,
            encoding="utf-8",
            errors="replace",
            capture_output=True,
            check=False,
            timeout=CHECK_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired as error:
        stdout = error.stdout or ""
        stderr = error.stderr or ""
        output = stdout + stderr
        fatal_lines = find_fatal_lines(output)
        details = "\n".join(fatal_lines[:40]) if fatal_lines else output[-2000:]
        return False, f"{name}: failed\nTimed out after {CHECK_TIMEOUT_SECONDS}s\n{details}"

    output = completed.stdout + completed.stderr
    fatal_lines = find_fatal_lines(output)
    if fatal_lines:
        details = "\n".join(fatal_lines[:40])
        return False, f"{name}: failed\n{details}"
    marker = check.get("required_marker")
    if marker and marker not in output:
        return False, f"{name}: failed\nMissing marker: {marker}"
    return True, f"{name}: ok"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", type=Path, default=DEFAULT_GODOT)
    args = parser.parse_args()

    if not args.godot.exists():
        print(f"Godot executable not found: {args.godot}", file=sys.stderr)
        return 2

    all_ok = True
    for check in CHECKS:
        ok, message = run_check(args.godot, check)
        print(message)
        all_ok = all_ok and ok

    return 0 if all_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
