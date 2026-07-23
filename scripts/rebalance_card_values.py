"""Apply absolute numeric targets for lifecycle-differentiated cards.

Run once with --capture-targets after changing the identity rules.  The stored
targets make later runs idempotent and keep the balance pass reviewable.
"""

from __future__ import annotations

import argparse
import json
import math
import re
from pathlib import Path

import card_table as ct


ROOT = Path(__file__).resolve().parents[1]
TARGETS = ROOT / "scripts" / "card_balance_targets.json"
FACTORS = {"爆发": 1.35}
BENEFICIAL_EFFECTS = {
    "configured_block_effect", "configured_damage_effect", "configured_draw_effect",
    "configured_heal_effect", "configured_mana_effect", "configured_status_effect",
    "configured_count_scaling_effect", "configured_demonic_engine_effect",
    "configured_consume_status_to_block_effect", "configured_consume_status_to_damage_effect",
    "configured_self_damage_scaling_damage_effect", "configured_x_cost_damage_effect",
    "low_health_bonus_damage_effect", "player_status_damage_effect", "target_status_bonus_damage_effect",
}
TUNABLE_FIELDS = ("amount", "base_amount", "bonus_amount", "value")


def _tags(text: str) -> list[str]:
    match = re.search(r'^mechanic_tags = PackedStringArray\((.*)\)$', text.split("[resource]", 1)[1], re.M)
    return json.loads("[" + match.group(1) + "]") if match and match.group(1).strip() else []


def _script_map(text: str) -> dict[str, str]:
    return {
        match.group(2): Path(match.group(1)).stem
        for match in re.finditer(r'\[ext_resource type="Script"[^\]]*path="([^"]+)"[^\]]*id="([^"]+)"', text)
    }


def capture() -> None:
    targets: list[dict] = []
    for path in ct.find_card_files():
        text = path.read_text(encoding="utf-8")
        specialty = next((tag for tag in _tags(text) if tag in FACTORS), "")
        if not specialty:
            continue
        factor = FACTORS[specialty]
        scripts = _script_map(text)
        for block_match in re.finditer(r'\[sub_resource type="Resource" id="([^"]+)"\]\n(.*?)(?=\n\[|\Z)', text, re.S):
            sub_id, body = block_match.groups()
            script_match = re.search(r'script = ExtResource\("([^"]+)"\)', body)
            if not script_match or scripts.get(script_match.group(1), "") not in BENEFICIAL_EFFECTS:
                continue
            for field in TUNABLE_FIELDS:
                value_match = re.search(rf'^{field} = (\d+)$', body, re.M)
                if not value_match:
                    continue
                old = int(value_match.group(1))
                new = max(1, math.ceil(old * factor) if factor > 1 else math.floor(old * factor))
                if new != old:
                    targets.append({
                        "file": path.relative_to(ct.PROJECT_ROOT).as_posix(), "effect_id": sub_id,
                        "field": field, "value": new, "identity": specialty,
                    })
    TARGETS.write_text(json.dumps(targets, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"captured_targets={len(targets)}")


def apply() -> None:
    targets = json.loads(TARGETS.read_text(encoding="utf-8"))
    by_file: dict[str, list[dict]] = {}
    for target in targets:
        by_file.setdefault(target["file"], []).append(target)
    changed = 0
    for rel, edits in by_file.items():
        path = ct.PROJECT_ROOT / rel
        text = path.read_text(encoding="utf-8")
        original = text
        for edit in edits:
            pattern = re.compile(
                r'(\[sub_resource type="Resource" id="' + re.escape(edit["effect_id"]) + r'"\]\n)'
                r'(.*?)(?=\n\[|\Z)', re.S
            )
            def replace(match: re.Match[str]) -> str:
                body = re.sub(
                    rf'^{re.escape(edit["field"])} = \d+$',
                    f'{edit["field"]} = {int(edit["value"])}', match.group(2), count=1, flags=re.M,
                )
                return match.group(1) + body
            text = pattern.sub(replace, text, count=1)
        if text != original:
            path.write_text(text, encoding="utf-8")
            changed += 1
    print(f"balanced_card_files={changed} targets={len(targets)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture-targets", action="store_true")
    args = parser.parse_args()
    if args.capture_targets:
        capture()
    apply()


if __name__ == "__main__":
    main()
