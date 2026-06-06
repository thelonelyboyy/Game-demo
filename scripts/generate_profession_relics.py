#!/usr/bin/env python3
"""Generate profession-specific relics and refresh the reward pool."""

from __future__ import annotations

import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = REPO_ROOT / "game-demo"
RELIC_ROOT = PROJECT_ROOT / "relics"

RELIC_POOL_SCRIPT = "res://custom_resources/relic_reward_pool.gd"
BASE_RELIC_SCRIPT = "res://custom_resources/relic.gd"

RELICS = {
    "sword_resonance_charm": '''[gd_resource type="Resource" script_class="CardPlayDamageRelic" load_steps=4 format=3]

[ext_resource type="Script" path="res://relics/effects/card_play_damage_relic.gd" id="1"]
[ext_resource type="Texture2D" path="res://art/relics/phase4/metal_edge_ring.png" id="2"]

[resource]
script = ExtResource("1")
relic_name = "剑鸣玉坠"
id = "sword_resonance_charm"
type = 4
character_type = 2
icon = ExtResource("2")
tooltip = "剑修专属。每回合第一次打出剑修牌时，对随机敌人造成 3 点伤害。"
match_profession = 2
damage_amount = 3
target_mode = 1
once_per_turn = true
''',
    "sword_cloud_manual": '''[gd_resource type="Resource" script_class="CardPlayDrawRelic" load_steps=4 format=3]

[ext_resource type="Script" path="res://relics/effects/card_play_draw_relic.gd" id="1"]
[ext_resource type="Texture2D" path="res://art/relics/phase4/water_moon_bottle.png" id="2"]

[resource]
script = ExtResource("1")
relic_name = "云剑残卷"
id = "sword_cloud_manual"
type = 4
character_type = 2
icon = ExtResource("2")
tooltip = "剑修专属。每回合第一次打出剑修牌时，抽 1 张牌。"
match_profession = 2
draw_amount = 1
once_per_turn = true
''',
    "body_marrow_drum": '''[gd_resource type="Resource" script_class="PlayerHitBlockRelic" load_steps=4 format=3]

[ext_resource type="Script" path="res://relics/effects/player_hit_block_relic.gd" id="1"]
[ext_resource type="Texture2D" path="res://art/relics/phase4/golden_bone_bead.png" id="2"]

[resource]
script = ExtResource("1")
relic_name = "髓鼓"
id = "body_marrow_drum"
type = 4
character_type = 1
icon = ExtResource("2")
tooltip = "体修专属。每回合第一次受到伤害后，获得 7 点护体。"
block_amount = 7
once_per_turn = true
''',
    "body_goldskin_seal": '''[gd_resource type="Resource" script_class="TimingStatusRelic" load_steps=5 format=3]

[ext_resource type="Script" path="res://relics/effects/status_relic.gd" id="1"]
[ext_resource type="Texture2D" path="res://art/relics/phase4/stone_heart_bell.png" id="2"]
[ext_resource type="Resource" path="res://statuses/gold_body.tres" id="3"]

[resource]
script = ExtResource("1")
relic_name = "金皮印"
id = "body_goldskin_seal"
type = 1
character_type = 1
icon = ExtResource("2")
tooltip = "体修专属。战斗开始时，获得 1 层金身。"
status = ExtResource("3")
stacks = 1
target_mode = 0
''',
    "demon_heart_seal": '''[gd_resource type="Resource" script_class="CardPlayStatusRelic" load_steps=5 format=3]

[ext_resource type="Script" path="res://relics/effects/card_play_status_relic.gd" id="1"]
[ext_resource type="Texture2D" path="res://art/relics/phase4/ghost_contract.png" id="2"]
[ext_resource type="Resource" path="res://statuses/soul_mark.tres" id="3"]

[resource]
script = ExtResource("1")
relic_name = "魔心印"
id = "demon_heart_seal"
type = 4
character_type = 3
icon = ExtResource("2")
tooltip = "魔修专属。每回合第一次打出魔修牌时，给随机敌人 1 层魂印。"
match_profession = 3
status = ExtResource("3")
stacks = 1
target_mode = 2
once_per_turn = true
''',
    "demon_sacrifice_dagger": '''[gd_resource type="Resource" script_class="CardPlayDamageRelic" load_steps=4 format=3]

[ext_resource type="Script" path="res://relics/effects/card_play_damage_relic.gd" id="1"]
[ext_resource type="Texture2D" path="res://art/relics/phase4/sacrifice_blade.png" id="2"]

[resource]
script = ExtResource("1")
relic_name = "祭血匕"
id = "demon_sacrifice_dagger"
type = 4
character_type = 3
icon = ExtResource("2")
tooltip = "魔修专属。打出魔修牌时，对所有敌人造成 1 点伤害。"
match_profession = 3
damage_amount = 1
target_mode = 0
once_per_turn = false
''',
    "beast_king_totem": '''[gd_resource type="Resource" script_class="CardPlayStatusRelic" load_steps=5 format=3]

[ext_resource type="Script" path="res://relics/effects/card_play_status_relic.gd" id="1"]
[ext_resource type="Texture2D" path="res://art/relics/phase4/pack_banner.png" id="2"]
[ext_resource type="Resource" path="res://statuses/beast_pack.tres" id="3"]

[resource]
script = ExtResource("1")
relic_name = "兽王图腾"
id = "beast_king_totem"
type = 4
character_type = 4
icon = ExtResource("2")
tooltip = "驭兽师专属。每回合第一次打出驭兽牌时，获得 1 层兽群。"
match_profession = 4
status = ExtResource("3")
stacks = 1
target_mode = 0
once_per_turn = true
''',
    "beast_life_nest": '''[gd_resource type="Resource" script_class="CardPlayHealRelic" load_steps=4 format=3]

[ext_resource type="Script" path="res://relics/effects/card_play_heal_relic.gd" id="1"]
[ext_resource type="Texture2D" path="res://art/relics/phase4/beast_jade_whistle.png" id="2"]

[resource]
script = ExtResource("1")
relic_name = "灵巢"
id = "beast_life_nest"
type = 4
character_type = 4
icon = ExtResource("2")
tooltip = "驭兽师专属。每回合第一次打出驭兽牌时，回复 2 点生命。"
match_profession = 4
heal_amount = 2
once_per_turn = true
''',
}


def write_profession_relics() -> None:
    for relic_id, text in RELICS.items():
        (RELIC_ROOT / f"{relic_id}.tres").write_text(text, encoding="utf-8", newline="\n")


def is_starter_relic(path: Path) -> bool:
    text = path.read_text(encoding="utf-8", errors="replace")
    return bool(re.search(r"^starter_relic = true", text, re.M))


def generate_pool() -> None:
    relic_paths = [
        path for path in sorted(RELIC_ROOT.glob("*.tres"))
        if path.name != "relic_reward_pool.tres" and not is_starter_relic(path)
    ]
    load_steps = len(relic_paths) + 3
    lines = [
        f'[gd_resource type="Resource" script_class="RelicRewardPool" load_steps={load_steps} format=3]',
        "",
        f'[ext_resource type="Script" path="{RELIC_POOL_SCRIPT}" id="1_pool"]',
        f'[ext_resource type="Script" path="{BASE_RELIC_SCRIPT}" id="2_relic"]',
    ]
    for index, path in enumerate(relic_paths, start=1):
        res_path = "res://relics/" + path.name
        lines.append(f'[ext_resource type="Resource" path="{res_path}" id="relic_{index}"]')

    refs = ", ".join(f'ExtResource("relic_{index}")' for index in range(1, len(relic_paths) + 1))
    lines.extend([
        "",
        "[resource]",
        'script = ExtResource("1_pool")',
        f'relics = Array[Resource("{BASE_RELIC_SCRIPT}")]([{refs}])',
        "",
    ])
    (RELIC_ROOT / "relic_reward_pool.tres").write_text("\n".join(lines), encoding="utf-8", newline="\n")


def main() -> int:
    write_profession_relics()
    generate_pool()
    print(f"Generated {len(RELICS)} profession relics and refreshed relic_reward_pool.tres.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
