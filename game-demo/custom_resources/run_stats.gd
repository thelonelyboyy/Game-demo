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

@export var gold := STARTING_GOLD : set = set_gold
@export var card_rewards := BASE_CARD_REWARDS
@export var card_remove_cost := BASE_CARD_REMOVE_COST
@export_range(0.0, 100.0) var common_weight := BASE_COMMON_WEIGHT
@export_range(0.0, 100.0) var uncommon_weight := BASE_UNCOMMON_WEIGHT
@export_range(0.0, 100.0) var rare_weight := BASE_RARE_WEIGHT
@export_range(0.0, 100.0) var mythic_weight := BASE_MYTHIC_WEIGHT


func set_gold(new_amount: int) -> void:
	gold = new_amount
	gold_changed.emit()


func reset_weights() -> void:
	common_weight = BASE_COMMON_WEIGHT
	uncommon_weight = BASE_UNCOMMON_WEIGHT
	rare_weight = BASE_RARE_WEIGHT
	mythic_weight = BASE_MYTHIC_WEIGHT
