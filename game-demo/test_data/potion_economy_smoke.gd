extends Node

const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const POTION_HANDLER_SCENE_PATH := "res://scenes/potion_handler/potion_handler.tscn"
const BATTLE_REWARD_SCENE_PATH := "res://scenes/battle_reward/battle_reward.tscn"

var failures: PackedStringArray = []


func _ready() -> void:
	get_tree().create_timer(10.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var character := load(CHARACTER_PATH) as CharacterStats
	_check(character != null, "potion economy character loads")
	if not character:
		_finish()
		return

	_check(PotionRewardPool.POTION_PATHS.size() == 26, "shared catalog contains twenty-six consumables")
	var reward_paths := {}
	for path: String in PotionRewardPool.POTION_PATHS:
		reward_paths[path] = true
	_check(reward_paths.size() == 26, "reward catalog paths are unique")

	var available: Array[Potion] = []
	var rarity_counts := [0, 0, 0, 0]
	for path: String in PotionRewardPool.POTION_PATHS:
		var potion := load(path) as Potion
		_check(potion != null, "%s loads" % path)
		if not potion:
			continue
		rarity_counts[potion.rarity] += 1
		if potion.can_appear_as_reward(character):
			available.append(potion)
	_check(rarity_counts[Card.Rarity.COMMON] == 5, "catalog has five common consumables")
	_check(rarity_counts[Card.Rarity.UNCOMMON] == 13, "catalog has thirteen uncommon consumables")
	_check(rarity_counts[Card.Rarity.RARE] == 8, "catalog has eight rare consumables")
	_check(not available.is_empty(), "demonic character has available consumables")

	for _i in 80:
		var boss_drop := PotionRewardPool.pick(available, 3, PotionRewardPool.RewardContext.BOSS)
		_check(boss_drop != null and boss_drop.rarity != Card.Rarity.COMMON, "chapter three boss drops exclude common consumables")
		var regular_drop := PotionRewardPool.pick(available, 1, PotionRewardPool.RewardContext.STANDARD)
		_check(regular_drop != null and regular_drop.rarity != Card.Rarity.MYTHIC, "regular drops exclude mythic consumables")

	var choices := PotionRewardPool.pick_choices(available, 2, 3, PotionRewardPool.RewardContext.SHOP)
	_check(choices.size() == 2, "shop produces two consumable choices")
	_check(choices[0].id != choices[1].id, "shop consumable choices do not repeat")
	_check_weight_curves()
	_check_standard_drop_pity()
	await _check_potion_discard(available[0])
	await _check_full_inventory_reward(available[0])
	_finish()


func _check_weight_curves() -> void:
	for context in PotionRewardPool.CONTEXT_WEIGHTS:
		var previous_rare := -1.0
		for chapter_index in 3:
			var weights: Array = PotionRewardPool.CONTEXT_WEIGHTS[context][chapter_index]
			var total := 0.0
			for weight in weights:
				total += float(weight)
			_check(is_equal_approx(total, 100.0), "potion context %s chapter %s weights total 100" % [context, chapter_index + 1])
			_check(float(weights[Card.Rarity.RARE]) >= previous_rare, "potion context %s rare chance does not fall by chapter" % context)
			previous_rare = float(weights[Card.Rarity.RARE])


func _check_standard_drop_pity() -> void:
	var stats := RunStats.new()
	_check(is_equal_approx(stats.get_standard_potion_drop_chance(), 0.40), "standard consumable drop starts at forty percent")
	_check(not stats.roll_standard_potion_drop(0.40), "roll at the base boundary misses")
	_check(stats.potion_drop_miss_streak == 1 and is_equal_approx(stats.get_standard_potion_drop_chance(), 0.55), "first miss raises drop chance to fifty-five percent")
	_check(stats.roll_standard_potion_drop(0.54), "raised chance can produce a drop")
	_check(stats.potion_drop_miss_streak == 0, "successful drop resets pity")
	for _i in RunStats.POTION_DROP_HARD_PITY:
		_check(not stats.roll_standard_potion_drop(1.0), "eligible misses advance hard pity")
	_check(is_equal_approx(stats.get_standard_potion_drop_chance(), 1.0), "three misses arm guaranteed drop")
	_check(stats.roll_standard_potion_drop(1.0), "hard pity ignores even a maximum forced roll")
	_check(stats.potion_drop_miss_streak == 0, "hard pity drop resets miss streak")


func _check_potion_discard(potion: Potion) -> void:
	var handler_scene := load(POTION_HANDLER_SCENE_PATH) as PackedScene
	var handler := handler_scene.instantiate() as PotionHandler if handler_scene else null
	_check(handler != null, "potion handler scene loads for discard check")
	if not handler:
		return
	add_child(handler)
	await get_tree().process_frame
	_check(handler.add_potion(potion), "potion can enter an empty slot")
	var occupied_ui: PotionUI = null
	for ui: PotionUI in handler.get_children():
		if ui.potion:
			occupied_ui = ui
			break
	_check(occupied_ui != null, "occupied potion slot is available for discard")
	if occupied_ui:
		handler._aiming_ui = occupied_ui
		handler._on_discard_requested(occupied_ui)
		_check(handler.count() == 1 and handler._aiming_ui == null, "right-click while aiming cancels targeting without discarding")
		handler._on_discard_requested(occupied_ui)
		_check(handler.count() == 0 and occupied_ui.potion == null, "right-click discard clears the occupied slot")
	handler.queue_free()
	await get_tree().process_frame


func _check_full_inventory_reward(potion: Potion) -> void:
	var handler_scene := load(POTION_HANDLER_SCENE_PATH) as PackedScene
	var reward_scene := load(BATTLE_REWARD_SCENE_PATH) as PackedScene
	var handler := handler_scene.instantiate() as PotionHandler
	var reward := reward_scene.instantiate() as BattleReward
	add_child(handler)
	add_child(reward)
	await get_tree().process_frame
	reward.potion_handler = handler
	for _i in PotionHandler.MAX_SLOTS:
		_check(handler.add_potion(potion), "test inventory can be filled")
	_check(handler.is_full(), "test inventory reaches its slot cap")

	reward.add_potion_reward(potion)
	await get_tree().process_frame
	await get_tree().process_frame
	var reward_button: RewardButton
	for child: Node in reward.rewards.get_children():
		if child is RewardButton and child.has_meta("potion_reward"):
			reward_button = child
			break
	_check(reward_button != null and not reward_button.auto_consume, "full inventory keeps the consumable reward claimable")
	_check(reward_button != null and reward_button.reward_subtext.contains("药囊已满"), "full inventory reward explains how to make room")

	if reward_button:
		reward._on_potion_reward_taken(potion, reward_button)
		_check(handler.count() == PotionHandler.MAX_SLOTS and not reward_button.is_queued_for_deletion(), "failed full-inventory claim does not consume the reward")

	var occupied_ui := handler.get_child(0) as PotionUI
	handler._on_discard_requested(occupied_ui)
	await get_tree().process_frame
	_check(reward_button != null and not reward_button.reward_subtext.contains("药囊已满"), "discarding refreshes the pending reward state")
	if reward_button:
		reward._on_potion_reward_taken(potion, reward_button)
		_check(handler.is_full() and reward_button.is_queued_for_deletion(), "reward is consumed only after the potion enters an open slot")

	reward.queue_free()
	handler.queue_free()
	await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("POTION_ECONOMY_SMOKE_OK")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error("POTION_ECONOMY_SMOKE: %s" % failure)
	get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("POTION_ECONOMY_SMOKE: timed out")
	get_tree().quit(1)
