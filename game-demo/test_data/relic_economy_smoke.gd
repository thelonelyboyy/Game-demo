extends Node

const RELIC_POOL_PATH := "res://relics/relic_reward_pool.tres"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const PACT_PATHS := [
	"res://relics/demon_blood_pact_crown.tres",
	"res://relics/demon_flame_pact_wheel.tres",
	"res://relics/demon_ash_pact_scripture.tres",
]
const FOREIGN_PROFESSION_RELIC_PATHS := [
	"res://relics/beast_jade_whistle.tres",
	"res://relics/pack_banner.tres",
	"res://relics/sword_grindstone.tres",
	"res://relics/wind_sword_tassel.tres",
	"res://relics/blood_jade.tres",
	"res://relics/golden_bone_bead.tres",
]

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
	_check(pool.relics.size() == 80, "reward pool contains eighty relics")
	for rarity in Relic.Rarity.values():
		_check(rarity_counts[rarity] > 0, "rarity %s has at least one relic" % rarity)
	_check(rarity_counts[Relic.Rarity.BOSS] == 12, "reward pool contains twelve boss relics")

	_check_context(pool, character, RelicRewardPool.RewardContext.STANDARD, false, true)
	_check_context(pool, character, RelicRewardPool.RewardContext.SHOP, false, true)
	_check_context(pool, character, RelicRewardPool.RewardContext.BOSS, true, false)
	_check_demonic_profession_filter(character)
	await _check_three_chapter_boss_choices(pool, character)
	await _check_pact_exclusivity(pool, character)

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


func _check_demonic_profession_filter(character: CharacterStats) -> void:
	for path: String in FOREIGN_PROFESSION_RELIC_PATHS:
		var relic := load(path) as Relic
		_check(relic != null, "%s loads for profession filtering" % path)
		if relic:
			_check(not relic.can_appear_as_reward(character), "%s is excluded from the demonic relic pool" % relic.id)
	for path: String in ["res://relics/ghost_contract.tres", "res://relics/sacrifice_blade.tres"]:
		var relic := load(path) as Relic
		_check(relic != null and relic.can_appear_as_reward(character), "%s remains in the demonic relic pool" % path)


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


func _check_pact_exclusivity(pool: RelicRewardPool, character: CharacterStats) -> void:
	var handler_scene := load("res://scenes/relic_handler/relic_handler.tscn") as PackedScene
	var handler := handler_scene.instantiate() as RelicHandler
	add_child(handler)
	await get_tree().process_frame

	for _sample in 80:
		var choices := pool.get_random_available_choices(
			character, handler, 3, 3, RelicRewardPool.RewardContext.BOSS
		)
		var seen_groups := {}
		for relic: Relic in choices:
			if relic.exclusive_group.is_empty():
				continue
			_check(not seen_groups.has(relic.exclusive_group), "one reward set never repeats an exclusive relic group")
			seen_groups[relic.exclusive_group] = true

	var first_pact := load(PACT_PATHS[0]) as Relic
	handler.add_relic(first_pact)
	_check(handler.has_relic(first_pact.id), "the first pact can be equipped")
	handler.add_relic(load(PACT_PATHS[1]) as Relic)
	_check(not handler.has_relic((load(PACT_PATHS[1]) as Relic).id), "direct relic grants respect pact exclusivity")
	for _sample in 80:
		var choices := pool.get_random_available_choices(
			character, handler, 3, 3, RelicRewardPool.RewardContext.BOSS
		)
		for relic: Relic in choices:
			_check(relic.exclusive_group != first_pact.exclusive_group, "owned pact group is removed from later rewards")

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
