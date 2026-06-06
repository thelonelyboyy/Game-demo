#!/usr/bin/env python3
"""Generate demo enemy resources, battle scenes, and the battle stats pool."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = REPO_ROOT / "game-demo"

ENEMY_SCENE = "res://scenes/enemy/enemy.tscn"
ENEMY_STATS_SCRIPT = "res://custom_resources/enemy_stats.gd"
BATTLE_STATS_SCRIPT = "res://custom_resources/battle_stats.gd"
BATTLE_POOL_SCRIPT = "res://custom_resources/battle_stats_pool.gd"

AI_SCENES = {
    "swift": "res://enemies/bat/bat_enemy_ai.tscn",
    "guard": "res://enemies/crab/crab_enemy_ai.tscn",
    "toxic": "res://enemies/toxic_ghost/toxic_ghost_ai.tscn",
}

ART = {
    "wolf": "res://art/enemies/silver_moon_wolf.png",
    "eagle": "res://art/enemies/dark_eagle.png",
    "demon": "res://art/enemies/bull_demon.png",
    "dragon": "res://art/enemies/bone_dragon.png",
}


@dataclass(frozen=True)
class EnemyDef:
    enemy_id: str
    display_name: str
    description: str
    health: int
    art_key: str
    ai_key: str
    category: str


@dataclass(frozen=True)
class BattleDef:
    battle_id: str
    tier: int
    enemy_ids: tuple[str, ...]
    weight: float
    gold_min: int
    gold_max: int
    health_multiplier: float = 1.0
    damage_multiplier: float = 1.0


ENEMIES = [
    EnemyDef("mist_wolf", "雾隐狼", "藏在云海边缘的灵狼，习惯用连扑试探修士破绽。", 14, "wolf", "swift", "normal"),
    EnemyDef("paper_soldier", "符纸兵", "被残缺符箓驱使的纸甲兵，动作僵硬但数量烦人。", 16, "eagle", "guard", "normal"),
    EnemyDef("ash_imp", "劫灰小鬼", "从炉灰里爬出的劫火小鬼，会在攻击间隙积攒护体灰烬。", 18, "demon", "swift", "normal"),
    EnemyDef("jade_spider", "碧玉蛛", "足肢如玉的毒蛛，吐出的灵丝会扰乱手牌节奏。", 20, "dragon", "toxic", "normal"),
    EnemyDef("storm_hawk", "雷羽鹰", "盘旋在云桥上的雷羽妖禽，俯冲速度极快。", 22, "eagle", "swift", "normal"),
    EnemyDef("grave_lantern", "幽冢灯", "墓道里飘出的魂灯，会借阴火强化自身。", 24, "dragon", "toxic", "normal"),
    EnemyDef("river_serpent", "寒潭蛇", "蛰伏在灵潭里的长蛇，攻守转换狡猾。", 26, "wolf", "guard", "normal"),
    EnemyDef("bronze_puppet", "铜傀儡", "古宗门遗留的铜质傀儡，防御厚重。", 30, "demon", "guard", "normal"),
    EnemyDef("venom_moth", "瘴毒蛾", "翅粉带毒的妖蛾，会把浊气混进牌堆。", 21, "eagle", "toxic", "normal"),
    EnemyDef("stone_goblin", "山魈石怪", "披着碎岩的山魈，力道不大但很耐打。", 28, "demon", "guard", "normal"),
    EnemyDef("iron_golem", "玄铁傀", "由玄铁和残魂铸成的精英守卫，护甲层层叠起。", 54, "demon", "guard", "elite"),
    EnemyDef("blood_tiger", "血纹虎", "背生血纹的山君，越战越凶。", 48, "wolf", "swift", "elite"),
    EnemyDef("thunder_roc", "劫雷鹏", "沐浴雷劫的巨鹏，会用高速连击撕开护体。", 50, "eagle", "swift", "elite"),
    EnemyDef("shadow_reaper", "摄魂影", "从阴影里凝成的修罗影，擅长拖慢牌序。", 46, "dragon", "toxic", "elite"),
    EnemyDef("jade_wyrm", "碧鳞蛟", "未化龙的碧鳞蛟，攻势与鳞甲同样棘手。", 58, "dragon", "guard", "elite"),
    EnemyDef("black_lotus_matriarch", "黑莲圣母", "黑莲业火化身的首领，擅长在消耗战中压垮修士。", 96, "demon", "toxic", "boss"),
    EnemyDef("sky_palace_guardian", "天阙镇将", "守护天阙遗迹的古代神将，攻防都极为稳定。", 108, "eagle", "guard", "boss"),
    EnemyDef("abyssal_sword_soul", "渊狱剑魂", "堕入渊狱的剑意残魂，出手凌厉且连续。", 92, "wolf", "swift", "boss"),
    EnemyDef("eclipse_tyrant", "蚀日妖皇", "吞过日冕碎片的妖皇，会用暗蚀拖入长线战。", 118, "dragon", "toxic", "boss"),
]

EXISTING_ENEMY_PATHS = {
    "silver_moon_wolf": "res://enemies/bat/bat_enemy.tres",
    "dark_eagle": "res://enemies/crab/crab_enemy.tres",
    "bull_demon": "res://enemies/bull_demon/bull_demon.tres",
    "bone_dragon": "res://enemies/toxic_ghost/toxic_ghost.tres",
}

BATTLES = [
    BattleDef("demo_n_mist_wolf", 0, ("mist_wolf",), 2.0, 45, 58),
    BattleDef("demo_n_paper_wolf", 0, ("paper_soldier", "mist_wolf"), 2.0, 48, 62),
    BattleDef("demo_n_ash_spider", 0, ("ash_imp", "jade_spider"), 1.8, 52, 66),
    BattleDef("demo_n_storm_hawk", 0, ("storm_hawk",), 1.5, 50, 64),
    BattleDef("demo_n_lantern_serpent", 0, ("grave_lantern", "river_serpent"), 1.5, 58, 74),
    BattleDef("demo_n_bronze_puppet", 0, ("bronze_puppet",), 1.2, 60, 76),
    BattleDef("demo_n_moth_goblin", 0, ("venom_moth", "stone_goblin"), 1.5, 62, 78),
    BattleDef("demo_n_swarm", 0, ("mist_wolf", "ash_imp", "venom_moth"), 1.0, 66, 82),
    BattleDef("demo_n_serpent_hawk", 0, ("river_serpent", "storm_hawk"), 1.4, 60, 78),
    BattleDef("demo_n_old_new_pack", 0, ("silver_moon_wolf", "jade_spider", "dark_eagle"), 1.0, 64, 80),
    BattleDef("demo_e_bull_demon", 1, ("bull_demon",), 1.0, 95, 122, 1.0, 1.0),
    BattleDef("demo_e_iron_golem", 1, ("iron_golem",), 1.2, 102, 130, 1.0, 1.1),
    BattleDef("demo_e_blood_tiger_pack", 1, ("blood_tiger", "mist_wolf"), 1.0, 106, 136, 1.0, 1.12),
    BattleDef("demo_e_thunder_roc", 1, ("thunder_roc",), 1.0, 106, 136, 1.0, 1.15),
    BattleDef("demo_e_shadow_reaper", 1, ("shadow_reaper", "paper_soldier"), 1.0, 110, 140, 1.0, 1.1),
    BattleDef("demo_e_jade_wyrm", 1, ("jade_wyrm",), 1.0, 112, 145, 1.0, 1.12),
    BattleDef("demo_b_bone_dragon", 2, ("bone_dragon",), 1.0, 150, 190, 1.25, 1.15),
    BattleDef("demo_b_black_lotus", 2, ("black_lotus_matriarch",), 1.0, 160, 205, 1.0, 1.18),
    BattleDef("demo_b_sky_guardian", 2, ("sky_palace_guardian",), 1.0, 165, 210, 1.0, 1.15),
    BattleDef("demo_b_sword_soul", 2, ("abyssal_sword_soul",), 1.0, 160, 210, 1.0, 1.25),
    BattleDef("demo_b_eclipse_tyrant", 2, ("eclipse_tyrant",), 1.0, 175, 230, 1.0, 1.2),
]


def res_to_path(res_path: str) -> Path:
    return PROJECT_ROOT / res_path.removeprefix("res://")


def enemy_res_path(enemy_id: str) -> str:
    if enemy_id in EXISTING_ENEMY_PATHS:
        return EXISTING_ENEMY_PATHS[enemy_id]
    return f"res://enemies/{enemy_id}/{enemy_id}_enemy.tres"


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def generate_enemy(enemy: EnemyDef) -> None:
    resource_path = res_to_path(enemy_res_path(enemy.enemy_id))
    text = f'''[gd_resource type="Resource" script_class="EnemyStats" load_steps=4 format=3]

[ext_resource type="Script" path="{ENEMY_STATS_SCRIPT}" id="1_stats"]
[ext_resource type="Texture2D" path="{ART[enemy.art_key]}" id="2_art"]
[ext_resource type="PackedScene" path="{AI_SCENES[enemy.ai_key]}" id="3_ai"]

[resource]
script = ExtResource("1_stats")
id = "{enemy.enemy_id}"
display_name = "{enemy.display_name}"
description = "{enemy.description}"
ai = ExtResource("3_ai")
max_health = {enemy.health}
art = ExtResource("2_art")
'''
    write_text(resource_path, text)


def battle_positions(count: int) -> list[tuple[int, int]]:
    if count == 1:
        return [(280, 124)]
    if count == 2:
        return [(248, 124), (316, 120)]
    return [(226, 128), (284, 120), (340, 126)]


def generate_battle_scene(battle: BattleDef) -> str:
    scene_res_path = f"res://battles/{battle.battle_id}.tscn"
    scene_path = res_to_path(scene_res_path)
    load_steps = 2 + len(battle.enemy_ids)
    lines = [
        f'[gd_scene load_steps={load_steps} format=3]',
        "",
        f'[ext_resource type="PackedScene" path="{ENEMY_SCENE}" id="1_enemy"]',
    ]
    for index, enemy_id in enumerate(battle.enemy_ids, start=2):
        lines.append(f'[ext_resource type="Resource" path="{enemy_res_path(enemy_id)}" id="{index}_stats"]')
    lines.extend(["", '[node name="Enemies" type="Node2D"]'])
    for index, (enemy_id, position) in enumerate(zip(battle.enemy_ids, battle_positions(len(battle.enemy_ids))), start=1):
        lines.append("")
        lines.append(f'[node name="Enemy{index}" parent="." instance=ExtResource("1_enemy")]')
        lines.append(f"position = Vector2({position[0]}, {position[1]})")
        lines.append(f'stats = ExtResource("{index + 1}_stats")')
    write_text(scene_path, "\n".join(lines) + "\n")
    return scene_res_path


def generate_battle_stats(battle: BattleDef, scene_res_path: str) -> str:
    stats_res_path = f"res://battles/{battle.battle_id}.tres"
    text = f'''[gd_resource type="Resource" script_class="BattleStats" load_steps=3 format=3]

[ext_resource type="Script" path="{BATTLE_STATS_SCRIPT}" id="1_stats"]
[ext_resource type="PackedScene" path="{scene_res_path}" id="2_scene"]

[resource]
script = ExtResource("1_stats")
battle_tier = {battle.tier}
weight = {battle.weight:.2f}
gold_reward_min = {battle.gold_min}
gold_reward_max = {battle.gold_max}
enemy_health_multiplier = {battle.health_multiplier:.2f}
enemy_damage_multiplier = {battle.damage_multiplier:.2f}
enemies = ExtResource("2_scene")
'''
    write_text(res_to_path(stats_res_path), text)
    return stats_res_path


def generate_battle_pool(battle_stats_paths: list[str]) -> None:
    load_steps = len(battle_stats_paths) + 3
    lines = [
        f'[gd_resource type="Resource" script_class="BattleStatsPool" load_steps={load_steps} format=3 uid="uid://by8ka073e8sah"]',
        "",
        f'[ext_resource type="Script" path="{BATTLE_POOL_SCRIPT}" id="1_pool"]',
        f'[ext_resource type="Script" path="{BATTLE_STATS_SCRIPT}" id="2_stats"]',
    ]
    for index, stats_path in enumerate(battle_stats_paths, start=1):
        lines.append(f'[ext_resource type="Resource" path="{stats_path}" id="battle_{index}"]')
    refs = ", ".join(f'ExtResource("battle_{index}")' for index in range(1, len(battle_stats_paths) + 1))
    lines.extend([
        "",
        "[resource]",
        'script = ExtResource("1_pool")',
        f'pool = Array[ExtResource("2_stats")]([{refs}])',
        "",
    ])
    write_text(PROJECT_ROOT / "battles" / "battle_stats_pool.tres", "\n".join(lines))


def main() -> int:
    for enemy in ENEMIES:
        generate_enemy(enemy)

    battle_stats_paths: list[str] = []
    for battle in BATTLES:
        scene_res_path = generate_battle_scene(battle)
        battle_stats_paths.append(generate_battle_stats(battle, scene_res_path))
    generate_battle_pool(battle_stats_paths)

    print(f"Generated {len(ENEMIES)} enemies and {len(BATTLES)} battles.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
