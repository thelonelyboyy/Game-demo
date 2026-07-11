class_name BattleStatsPool
extends Resource

@export var pool: Array[BattleStats]

var total_weights_by_tier := [0.0, 0.0, 0.0]
var active_chapter := 0
var battle_bags: Array[Array] = [[], [], []]


func _get_all_battles_for_tier(tier: int) -> Array[BattleStats]:
	return pool.filter(
		func(battle: BattleStats):
			return battle.battle_tier == tier and battle.is_available_in_chapter(active_chapter)
	)


func _setup_weight_for_tier(tier: int) -> void:
	var battles := _get_all_battles_for_tier(tier)
	total_weights_by_tier[tier] = 0.0
	
	for battle: BattleStats in battles:
		total_weights_by_tier[tier] += battle.weight
		battle.accumulated_weight = total_weights_by_tier[tier]


func get_random_battle_for_tier(tier: int) -> BattleStats:
	if tier < 0 or tier >= battle_bags.size():
		return null
	if battle_bags[tier].is_empty():
		_refill_bag(tier)
	if battle_bags[tier].is_empty():
		return null
	return battle_bags[tier].pop_back() as BattleStats


func setup(chapter := 0) -> void:
	active_chapter = chapter
	for i in 3:
		_setup_weight_for_tier(i)
		_refill_bag(i)


func _refill_bag(tier: int) -> void:
	var remaining := _get_all_battles_for_tier(tier)
	var weighted_order: Array[BattleStats] = []
	while not remaining.is_empty():
		var picked := _pick_weighted_without_replacement(remaining)
		if not picked:
			break
		weighted_order.append(picked)
		remaining.erase(picked)
	battle_bags[tier] = weighted_order


func _pick_weighted_without_replacement(candidates: Array[BattleStats]) -> BattleStats:
	var total_weight := 0.0
	for battle: BattleStats in candidates:
		total_weight += maxf(battle.weight, 0.0)
	if total_weight <= 0.0:
		return RNG.array_pick_random(candidates) as BattleStats

	var roll := RNG.instance.randf_range(0.0, total_weight)
	var fallback: BattleStats
	for battle: BattleStats in candidates:
		var battle_weight := maxf(battle.weight, 0.0)
		if battle_weight <= 0.0:
			continue
		fallback = battle
		roll -= battle_weight
		if roll <= 0.0:
			return battle
	return fallback
