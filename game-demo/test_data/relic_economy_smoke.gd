extends Node

const RELIC_POOL_PATH := "res://relics/relic_reward_pool.tres"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"

var failures: PackedStringArray = []


func _ready() -> void:
	get_tree().create_timer(10.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var pool := load(RELIC_POOL_PATH) as RelicRewardPool
	var character := load(CHARACTER_PATH) as CharacterStats
	_check(pool != null and character != null, "relic economy resources load")
	if not pool or not character:
		_finish()
		return

	var rarity_counts := [0, 0, 0, 0]
	for relic: Relic in pool.relics:
		if relic and relic.rarity < rarity_counts.size():
			rarity_counts[relic.rarity] += 1
	_check(pool.relics.size() == 45, "reward pool still contains forty-five relics")
	for rarity in Relic.Rarity.values():
		_check(rarity_counts[rarity] > 0, "rarity %s has at least one relic" % rarity)
	_check(rarity_counts[Relic.Rarity.BOSS] == 6, "demonic reward pool contains six boss relics")

	_check_context(pool, character, RelicRewardPool.RewardContext.STANDARD, false, true)
	_check_context(pool, character, RelicRewardPool.RewardContext.SHOP, false, true)
	_check_context(pool, character, RelicRewardPool.RewardContext.BOSS, true, false)
	await _check_three_chapter_boss_choices(pool, character)

	var choices := pool.get_random_available_choices(
		character, null, 4, 3, RelicRewardPool.RewardContext.TREASURE
	)
	var unique_ids := {}
	for relic: Relic in choices:
		unique_ids[relic.id] = true
	_check(choices.size() == unique_ids.size(), "multi-choice rewards never repeat a relic")

	var stats := RunStats.new()
	stats.apply_chapter_card_weights(3)
	_check(stats.current_chapter == 3, "run stats retain current chapter")
	_check_price_ladder()
	_finish()


func _check_context(
	pool: RelicRewardPool,
	character: CharacterStats,
	context: RelicRewardPool.RewardContext,
	require_non_common: bool,
	require_non_boss: bool
) -> void:
	for _i in 60:
		var relic := pool.get_random_available(character, null, 3, context)
		_check(relic != null, "context %s can produce a relic" % context)
		if not relic:
			continue
		if require_non_common:
			_check(relic.rarity != Relic.Rarity.COMMON, "boss rewards exclude common relics")
		if context == RelicRewardPool.RewardContext.BOSS:
			_check(relic.rarity == Relic.Rarity.BOSS, "boss rewards contain only boss relics")
		if require_non_boss:
			_check(relic.rarity != Relic.Rarity.BOSS, "non-boss rewards exclude boss relics")


func _check_three_chapter_boss_choices(pool: RelicRewardPool, character: CharacterStats) -> void:
	var handler_scene := load("res://scenes/relic_handler/relic_handler.tscn") as PackedScene
	var handler := handler_scene.instantiate() as RelicHandler
	add_child(handler)
	await get_tree().process_frame
	# Simulate carrying one boss relic through defeat legacy before a new run.
	handler.add_relic(load("res://relics/demon_wraith_banner.tres") as Relic)
	for chapter in range(1, 4):
		var choices := pool.get_random_available_choices(
			character, handler, 3, chapter, RelicRewardPool.RewardContext.BOSS
		)
		_check(choices.size() == 3, "chapter %s offers three boss relic choices after legacy carryover" % chapter)
		var unique_ids := {}
		for relic: Relic in choices:
			unique_ids[relic.id] = true
			_check(relic.rarity == Relic.Rarity.BOSS, "chapter %s choice is boss rarity" % chapter)
		_check(unique_ids.size() == 3, "chapter %s boss choices are unique" % chapter)
		if not choices.is_empty():
			handler.add_relic(choices[0])
	handler.queue_free()
	await get_tree().process_frame


func _check_price_ladder() -> void:
	var common := ShopRelic.get_price_range(Relic.Rarity.COMMON)
	var uncommon := ShopRelic.get_price_range(Relic.Rarity.UNCOMMON)
	var rare := ShopRelic.get_price_range(Relic.Rarity.RARE)
	var boss := ShopRelic.get_price_range(Relic.Rarity.BOSS)
	_check(common.x < common.y, "common relic price range is valid")
	_check(common.y < uncommon.x, "uncommon relics cost more than common relics")
	_check(uncommon.y < rare.x, "rare relics cost more than uncommon relics")
	_check(rare.y < boss.x, "boss relics retain a separate premium price tier")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("RELIC_ECONOMY_SMOKE_OK")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error("RELIC_ECONOMY_SMOKE: %s" % failure)
	get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("RELIC_ECONOMY_SMOKE: timed out")
	get_tree().quit(1)
