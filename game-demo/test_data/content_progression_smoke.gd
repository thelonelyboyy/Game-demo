extends Node

const BATTLE_POOL_PATH := "res://battles/battle_stats_pool.tres"
const EXPECTED_COUNTS := {
	1: [8, 3, 3],
	2: [8, 3, 3],
	3: [8, 3, 3],
}

var failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var pool := (load(BATTLE_POOL_PATH) as BattleStatsPool).duplicate(true) as BattleStatsPool
	_check(pool != null, "battle pool loads")
	if not pool:
		_finish()
		return

	var ids_by_tier_and_chapter := {}
	for chapter in range(1, 4):
		pool.setup(chapter)
		for tier in range(3):
			var battles := pool._get_all_battles_for_tier(tier)
			var expected_count: int = EXPECTED_COUNTS[chapter][tier]
			_check(battles.size() == expected_count, "chapter %s tier %s has expected encounter count" % [chapter, tier])
			var ids := {}
			for battle: BattleStats in battles:
				ids[_battle_id(battle)] = true
				_check(battle.is_available_in_chapter(chapter), "chapter-filtered battle accepts active chapter")
			ids_by_tier_and_chapter["%s:%s" % [tier, chapter]] = ids

			for i in range(30):
				var picked := pool.get_random_battle_for_tier(tier)
				_check(picked != null, "chapter %s tier %s always selects an encounter" % [chapter, tier])
				if picked:
					_check(ids.has(_battle_id(picked)), "random encounter stays inside chapter pool")

	for tier in range(3):
		for first_chapter in range(1, 4):
			for second_chapter in range(first_chapter + 1, 4):
				var first: Dictionary = ids_by_tier_and_chapter["%s:%s" % [tier, first_chapter]]
				var second: Dictionary = ids_by_tier_and_chapter["%s:%s" % [tier, second_chapter]]
				_check(_sets_are_disjoint(first, second), "tier %s encounter pools do not repeat across chapters" % tier)

	_check_chapter_card_weights()

	_finish()


func _check_chapter_card_weights() -> void:
	var stats := RunStats.new()
	var previous_common := 101.0
	var previous_high_rarity := -1.0
	for chapter in range(1, 4):
		stats.apply_chapter_card_weights(chapter)
		var total := stats.common_weight + stats.uncommon_weight + stats.rare_weight + stats.mythic_weight
		var high_rarity := stats.rare_weight + stats.mythic_weight
		_check(is_equal_approx(total, 100.0), "chapter %s card rarity weights total 100" % chapter)
		_check(stats.common_weight < previous_common, "chapter %s does not increase common reward chance" % chapter)
		_check(high_rarity > previous_high_rarity, "chapter %s increases high-rarity reward chance" % chapter)
		previous_common = stats.common_weight
		previous_high_rarity = high_rarity


func _battle_id(battle: BattleStats) -> String:
	return battle.resource_path.get_file().get_basename()


func _sets_are_disjoint(first: Dictionary, second: Dictionary) -> bool:
	for id in first:
		if second.has(id):
			return false
	return true


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("CONTENT_PROGRESSION_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("CONTENT_PROGRESSION_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)
