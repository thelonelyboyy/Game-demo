class_name RunStats
extends Resource

signal gold_changed

const STARTING_GOLD := 70
const BASE_CARD_REWARDS := 3
const BASE_COMMON_WEIGHT := 85.0
const BASE_UNCOMMON_WEIGHT := 10.0
const BASE_RARE_WEIGHT := 5.0
const BASE_MYTHIC_WEIGHT := 0.0
const BASE_CARD_REMOVE_COST := 100
const CARD_REMOVE_COST_INCREMENT := 25
const MAX_DIFFICULTY_LEVEL := 15
const DIFFICULTY_RULES := [
	"标准规则。",
	"所有敌人生命提高 5%。",
	"商店价格提高 10%。",
	"战斗金币奖励减少 10%。",
	"篝火休息恢复从 30% 降至 25%。",
	"所有敌人伤害提高 5%。",
	"精英额外获得 10% 生命。",
	"Boss 额外获得 10% 生命。",
	"战斗卡牌奖励从 3 选 1 降为 2 选 1。",
	"初始灵石从 70 降至 55。",
	"进入新章节只恢复一半已损生命。",
	"精英额外造成 10% 伤害。",
	"商店价格总加成提高至 25%。",
	"以 90% 最大生命开始一局。",
	"Boss 额外造成 15% 伤害。",
	"所有敌人生命总加成提高至 15%，伤害总加成提高至 10%。",
]
const CHAPTER_CARD_RARITY_WEIGHTS := {
	1: {"common": 85.0, "uncommon": 10.0, "rare": 5.0, "mythic": 0.0},
	2: {"common": 72.0, "uncommon": 18.0, "rare": 9.0, "mythic": 1.0},
	3: {"common": 60.0, "uncommon": 23.0, "rare": 14.0, "mythic": 3.0},
}

@export var gold := STARTING_GOLD : set = set_gold
@export var card_rewards := BASE_CARD_REWARDS
@export var card_remove_cost := BASE_CARD_REMOVE_COST
@export_range(0.0, 100.0) var common_weight := BASE_COMMON_WEIGHT
@export_range(0.0, 100.0) var uncommon_weight := BASE_UNCOMMON_WEIGHT
@export_range(0.0, 100.0) var rare_weight := BASE_RARE_WEIGHT
@export_range(0.0, 100.0) var mythic_weight := BASE_MYTHIC_WEIGHT
@export_range(0, MAX_DIFFICULTY_LEVEL) var difficulty_level := 0
@export var enemy_health_multiplier := 1.0
@export var enemy_damage_multiplier := 1.0
@export var elite_health_multiplier := 1.0
@export var elite_damage_multiplier := 1.0
@export var boss_health_multiplier := 1.0
@export var boss_damage_multiplier := 1.0
@export var gold_reward_multiplier := 1.0
@export var shop_cost_multiplier := 1.0
@export var campfire_heal_ratio := 0.30
@export var chapter_recovery_ratio := 1.0
@export var starting_health_ratio := 1.0
@export_range(1, 3) var current_chapter := 1
@export var battles_won := 0
@export var elites_defeated := 0
@export var bosses_defeated := 0
@export var enemies_defeated := 0
@export var cards_played := 0
@export var events_resolved := 0
@export var shops_visited := 0
@export var campfires_visited := 0
@export var gold_spent := 0
@export var potions_used := 0
@export var card_reward_miss_streak := 0


func set_gold(new_amount: int) -> void:
	gold = new_amount
	gold_changed.emit()


func reset_weights() -> void:
	common_weight = BASE_COMMON_WEIGHT
	uncommon_weight = BASE_UNCOMMON_WEIGHT
	rare_weight = BASE_RARE_WEIGHT
	mythic_weight = BASE_MYTHIC_WEIGHT


func apply_chapter_card_weights(chapter: int) -> void:
	var chapter_key := clampi(chapter, 1, 3)
	current_chapter = chapter_key
	var weights: Dictionary = CHAPTER_CARD_RARITY_WEIGHTS[chapter_key]
	common_weight = float(weights["common"])
	uncommon_weight = float(weights["uncommon"])
	rare_weight = float(weights["rare"])
	mythic_weight = float(weights["mythic"])


func configure_difficulty(level: int, initialize_run := true) -> void:
	difficulty_level = clampi(level, 0, MAX_DIFFICULTY_LEVEL)
	refresh_difficulty_modifiers(initialize_run)


func refresh_difficulty_modifiers(initialize_run := false) -> void:
	enemy_health_multiplier = 1.0
	enemy_damage_multiplier = 1.0
	elite_health_multiplier = 1.0
	elite_damage_multiplier = 1.0
	boss_health_multiplier = 1.0
	boss_damage_multiplier = 1.0
	gold_reward_multiplier = 1.0
	shop_cost_multiplier = 1.0
	campfire_heal_ratio = 0.30
	chapter_recovery_ratio = 1.0
	starting_health_ratio = 1.0
	card_rewards = BASE_CARD_REWARDS
	if initialize_run:
		gold = STARTING_GOLD
		card_remove_cost = BASE_CARD_REMOVE_COST

	if difficulty_level >= 1:
		enemy_health_multiplier = 1.05
	if difficulty_level >= 2:
		shop_cost_multiplier = 1.10
	if difficulty_level >= 3:
		gold_reward_multiplier = 0.90
	if difficulty_level >= 4:
		campfire_heal_ratio = 0.25
	if difficulty_level >= 5:
		enemy_damage_multiplier = 1.05
	if difficulty_level >= 6:
		elite_health_multiplier = 1.10
	if difficulty_level >= 7:
		boss_health_multiplier = 1.10
	if difficulty_level >= 8:
		card_rewards = 2
	if difficulty_level >= 9 and initialize_run:
		gold = 55
	if difficulty_level >= 10:
		chapter_recovery_ratio = 0.50
	if difficulty_level >= 11:
		elite_damage_multiplier = 1.10
	if difficulty_level >= 12:
		shop_cost_multiplier = 1.25
	if difficulty_level >= 13:
		starting_health_ratio = 0.90
	if difficulty_level >= 14:
		boss_damage_multiplier = 1.15
	if difficulty_level >= 15:
		enemy_health_multiplier = 1.15
		enemy_damage_multiplier = 1.10


func get_enemy_health_multiplier(battle_tier: int) -> float:
	var multiplier := enemy_health_multiplier
	if battle_tier == 1:
		multiplier *= elite_health_multiplier
	elif battle_tier == 2:
		multiplier *= boss_health_multiplier
	return multiplier


func get_enemy_damage_multiplier(battle_tier: int) -> float:
	var multiplier := enemy_damage_multiplier
	if battle_tier == 1:
		multiplier *= elite_damage_multiplier
	elif battle_tier == 2:
		multiplier *= boss_damage_multiplier
	return multiplier


func apply_gold_reward_multiplier(amount: int) -> int:
	return maxi(0, roundi(amount * gold_reward_multiplier))


func apply_shop_cost_multiplier(amount: int) -> int:
	return maxi(0, ceili(amount * shop_cost_multiplier))


func get_campfire_heal_amount(max_health: int) -> int:
	return maxi(0, ceili(max_health * campfire_heal_ratio))


func get_chapter_recovery_amount(current_health: int, max_health: int) -> int:
	return maxi(0, ceili((max_health - current_health) * chapter_recovery_ratio))


func get_starting_health(max_health: int) -> int:
	return clampi(ceili(max_health * starting_health_ratio), 1, max_health)


func get_difficulty_name() -> String:
	if difficulty_level <= 0:
		return "凡境"
	return "心魔 %s" % difficulty_level


static func get_difficulty_rule(level: int) -> String:
	return DIFFICULTY_RULES[clampi(level, 0, DIFFICULTY_RULES.size() - 1)]
