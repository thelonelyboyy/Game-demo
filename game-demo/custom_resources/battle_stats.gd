class_name BattleStats
extends Resource

@export_range(0, 2) var battle_tier: int
@export_range(1, 3) var chapter_min := 1
@export_range(1, 3) var chapter_max := 3
@export_range(0.0, 10.0) var weight: float
@export var gold_reward_min: int
@export var gold_reward_max: int
@export var enemy_health_multiplier := 1.0
@export var enemy_damage_multiplier := 1.0
@export var enemies: PackedScene

var accumulated_weight: float = 0.0


func roll_gold_reward() -> int:
	return RNG.instance.randi_range(gold_reward_min, gold_reward_max)


func is_available_in_chapter(chapter: int) -> bool:
	if chapter <= 0:
		return true
	return chapter >= chapter_min and chapter <= chapter_max
