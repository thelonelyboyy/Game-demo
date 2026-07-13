extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const POTION_HANDLER_SCENE_PATH := "res://scenes/potion_handler/potion_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const BATTLE_PATH := "res://battles/demo_n_paper_wolf.tres"
const RELIC_PATH := "res://relics/clarified_spirit_jade.tres"
const RELIC_POOL_PATH := "res://relics/relic_reward_pool.tres"
const BURN_IMPURITY_PATH := "res://characters/demonic_cultivator/cards/demon_burn_impurity.tres"
const CLARITY_PILL_PATH := "res://potions/clarity_pill.tres"
const WEAK_PATH := "res://statuses/weak.tres"
const FRAIL_PATH := "res://statuses/frail.tres"

var failures: PackedStringArray = []


func _ready() -> void:
	get_tree().create_timer(30.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var potion_handler_scene := load(POTION_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	var battle_stats := load(BATTLE_PATH) as BattleStats
	var relic := load(RELIC_PATH) as Relic
	var pool := load(RELIC_POOL_PATH) as RelicRewardPool
	_check(battle_scene != null and relic_handler_scene != null and potion_handler_scene != null and character_resource != null and battle_stats != null and relic != null and pool != null, "debuff counterplay resources load")
	if not battle_scene or not relic_handler_scene or not potion_handler_scene or not character_resource or not battle_stats or not relic or not pool:
		_finish()
		return

	_check(pool.relics.has(relic), "clarified spirit jade is present in the reward pool")
	_check(relic.rarity == Relic.Rarity.RARE and relic.character_type == Relic.CharacterType.ALL, "clarified spirit jade is a universal rare relic")
	_check(PotionRewardPool.POTION_PATHS.has(CLARITY_PILL_PATH), "clarity pill remains in the shared consumable pool")

	var relic_handler := relic_handler_scene.instantiate() as RelicHandler
	add_child(relic_handler)
	await get_tree().process_frame
	relic_handler.add_relic(relic)
	var battle := battle_scene.instantiate() as Battle
	add_child(battle)
	battle.char_stats = character_resource.create_instance()
	battle.battle_stats = battle_stats
	battle.relics = relic_handler
	battle.start_battle()
	await get_tree().create_timer(2.4).timeout

	_check(battle.player.status_handler.get_status_stacks("spell_ward") == 1, "clarified spirit jade grants one proactive spell ward")
	_apply_status(battle.player, WEAK_PATH)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(battle.player.status_handler.get_status("weak") == null, "spell ward blocks the first incoming debuff")
	_check(battle.player.status_handler.get_status("spell_ward") == null, "spell ward is consumed after blocking a debuff")

	_apply_status(battle.player, FRAIL_PATH)
	_apply_status(battle.player, WEAK_PATH)
	await get_tree().process_frame
	_check(battle.player.status_handler.get_debuff_count() == 2, "weak and frail coexist before cleansing")
	await _check_burn_impurity(battle)
	await _check_clarity_pill(battle, potion_handler_scene)

	get_tree().paused = false
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame
	_finish()


func _check_burn_impurity(battle: Battle) -> void:
	var card := (load(BURN_IMPURITY_PATH) as CultivationCard).duplicate(true) as CultivationCard
	_check(card != null and card.configured_effects.size() == 3, "burn impurity carries cleanse, block, and affliction purge effects")
	if not card:
		return
	card.apply_effects([battle.player], battle.player.modifier_handler)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(battle.player.status_handler.get_debuff_count() == 1, "base burn impurity removes exactly one debuff")
	_check(battle.char_stats.block == 5, "burn impurity cleanses frail before granting base block")

	_apply_missing_debuffs(battle.player)
	await get_tree().process_frame
	_check(battle.player.status_handler.get_debuff_count() == 2, "counterplay smoke restores both debuffs before upgrade check")
	var upgraded := (load(BURN_IMPURITY_PATH) as CultivationCard).duplicate(true) as CultivationCard
	_check(upgraded.upgrade(), "burn impurity can upgrade for counterplay")
	upgraded.apply_effects([battle.player], battle.player.modifier_handler)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(battle.player.status_handler.get_debuff_count() == 0, "upgraded burn impurity removes two debuffs")
	_check(upgraded.configured_effects[0].amount == 2, "burn impurity upgrade raises cleanse capacity to two")


func _check_clarity_pill(battle: Battle, potion_handler_scene: PackedScene) -> void:
	_apply_status(battle.player, WEAK_PATH)
	_apply_status(battle.player, FRAIL_PATH)
	await get_tree().process_frame
	var potion := load(CLARITY_PILL_PATH) as Potion
	_check(potion != null and potion.configured_effects.size() == 2, "clarity pill combines full cleanse and draw")
	if not potion:
		return

	var potion_handler := potion_handler_scene.instantiate() as PotionHandler
	add_child(potion_handler)
	await get_tree().process_frame
	_check(potion_handler.add_potion(potion), "clarity pill enters a potion slot")
	var occupied_ui: PotionUI
	for ui: PotionUI in potion_handler.get_children():
		if ui.potion:
			occupied_ui = ui
			break
	var hand_before := battle.player_handler.hand.get_child_count()
	if occupied_ui:
		potion_handler._on_use_requested(occupied_ui)
	await get_tree().create_timer(0.8).timeout
	_check(occupied_ui != null and occupied_ui.potion == null, "clarity pill is consumed through the real potion handler")
	_check(battle.player.status_handler.get_debuff_count() == 0, "clarity pill removes all active debuffs")
	_check(battle.player_handler.hand.get_child_count() == hand_before + 2, "clarity pill draws two cards after cleansing")
	potion_handler.queue_free()
	await get_tree().process_frame


func _apply_missing_debuffs(player: Player) -> void:
	if not player.status_handler.get_status("weak"):
		_apply_status(player, WEAK_PATH)
	if not player.status_handler.get_status("frail"):
		_apply_status(player, FRAIL_PATH)


func _apply_status(player: Player, path: String) -> void:
	var effect := StatusEffect.new()
	effect.status = load(path) as Status
	var targets: Array[Node] = [player]
	effect.execute(targets)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("DEBUFF_COUNTERPLAY_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("DEBUFF_COUNTERPLAY_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("DEBUFF_COUNTERPLAY_SMOKE_TIMEOUT")
	get_tree().paused = false
	get_tree().quit(2)
