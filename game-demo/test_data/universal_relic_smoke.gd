extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const OTHER_CHARACTER_PATH := "res://characters/sword_cultivator/sword_cultivator.tres"
const BATTLE_PATH := "res://battles/demo_n_paper_wolf.tres"
const RELIC_POOL_PATH := "res://relics/relic_reward_pool.tres"
const RELIC_PATHS := [
	"res://relics/war_pattern_bracer.tres",
	"res://relics/inkflow_jade_clasp.tres",
	"res://relics/stored_breath_furnace.tres",
	"res://relics/waning_moon_ring.tres",
	"res://relics/samsara_star_sand.tres",
	"res://relics/spirit_cleaver_talisman.tres",
	"res://relics/nirvana_ember.tres",
	"res://relics/formation_breaker_drum.tres",
]

var failures: PackedStringArray = []


func _ready() -> void:
	get_tree().create_timer(30.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	var other_character := load(OTHER_CHARACTER_PATH) as CharacterStats
	var battle_stats := load(BATTLE_PATH) as BattleStats
	var pool := load(RELIC_POOL_PATH) as RelicRewardPool
	_check(battle_scene != null and relic_handler_scene != null and character_resource != null and other_character != null and battle_stats != null and pool != null, "universal relic support resources load")
	if not battle_scene or not relic_handler_scene or not character_resource or not other_character or not battle_stats or not pool:
		_finish()
		return

	var relic_handler := relic_handler_scene.instantiate() as RelicHandler
	add_child(relic_handler)
	await get_tree().process_frame
	for path: String in RELIC_PATHS:
		var relic := load(path) as Relic
		_check(relic != null and pool.relics.has(relic), "%s is present in the reward pool" % path)
		_check(relic != null and relic.can_appear_as_reward(character_resource), "%s supports demonic cultivator" % path)
		_check(relic != null and relic.can_appear_as_reward(other_character), "%s supports other professions" % path)
		relic_handler.add_relic(relic)

	var battle := battle_scene.instantiate() as Battle
	add_child(battle)
	battle.char_stats = character_resource.create_instance()
	battle.battle_stats = battle_stats
	battle.relics = relic_handler
	battle.start_battle()
	await get_tree().create_timer(2.4).timeout

	_check(battle.player.status_handler.get_status_stacks("muscle") == 1, "formation breaker drum grants one muscle at combat start")
	_add_draw_cards(battle, 12)
	await _check_card_type_relics(battle)
	_check_timing_relics(battle, relic_handler)
	await _check_reshuffle_relic(battle)
	await _check_kill_relics(battle)

	get_tree().paused = false
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame
	_finish()


func _check_card_type_relics(battle: Battle) -> void:
	battle.player.stats.block = 0
	var attack := Card.new()
	attack.id = "universal_relic_attack"
	attack.type = Card.Type.ATTACK
	Events.card_played.emit(attack)
	await get_tree().process_frame
	_check(battle.player.stats.block == 4, "war pattern bracer grants four block on the first attack")
	Events.card_played.emit(attack)
	await get_tree().process_frame
	_check(battle.player.stats.block == 4, "war pattern bracer triggers once per turn")

	var hand_before := battle.player_handler.hand.get_child_count()
	var skill := Card.new()
	skill.id = "universal_relic_skill"
	skill.type = Card.Type.SKILL
	Events.card_played.emit(skill)
	await get_tree().create_timer(0.4).timeout
	_check(battle.player_handler.hand.get_child_count() == hand_before + 1, "inkflow jade clasp draws on the first skill")
	Events.card_played.emit(skill)
	await get_tree().create_timer(0.4).timeout
	_check(battle.player_handler.hand.get_child_count() == hand_before + 1, "inkflow jade clasp triggers once per turn")


func _check_timing_relics(battle: Battle, relic_handler: RelicHandler) -> void:
	var furnace_ui := _find_relic_ui(relic_handler, "stored_breath_furnace")
	var moon_ui := _find_relic_ui(relic_handler, "waning_moon_ring")
	_check(furnace_ui != null and moon_ui != null, "timing relic UIs are available")
	if not furnace_ui or not moon_ui:
		return

	battle.player.stats.block = 0
	battle.char_stats.mana = 2
	furnace_ui.relic.activate_relic(furnace_ui)
	_check(battle.player.stats.block == 6, "stored breath furnace converts unspent mana to block")
	_check(battle.char_stats.mana == 2, "stored breath furnace does not consume retained mana before turn end")
	battle.player.stats.block = 0
	battle.char_stats.mana = 5
	furnace_ui.relic.activate_relic(furnace_ui)
	_check(battle.player.stats.block == 9, "stored breath furnace caps block at three mana")

	battle.char_stats.mana = 0
	battle.char_stats.health = battle.char_stats.max_health
	moon_ui.relic.activate_relic(moon_ui)
	_check(battle.char_stats.mana == 0, "waning moon ring stays dormant above half health")
	battle.char_stats.health = battle.char_stats.max_health / 2
	moon_ui.relic.activate_relic(moon_ui)
	_check(battle.char_stats.mana == 1, "waning moon ring grants mana at half health")


func _check_reshuffle_relic(battle: Battle) -> void:
	Events.player_turn_started.emit()
	battle.player.stats.block = 0
	battle.char_stats.mana = 0
	Events.deck_reshuffled.emit(5)
	await get_tree().process_frame
	_check(battle.player.stats.block == 6 and battle.char_stats.mana == 1, "samsara star sand grants block and mana on reshuffle")
	Events.deck_reshuffled.emit(5)
	await get_tree().process_frame
	_check(battle.player.stats.block == 6 and battle.char_stats.mana == 1, "samsara star sand triggers once per turn")
	Events.player_turn_started.emit()
	Events.deck_reshuffled.emit(5)
	await get_tree().process_frame
	_check(battle.player.stats.block == 12 and battle.char_stats.mana == 2, "samsara star sand resets next turn")


func _check_kill_relics(battle: Battle) -> void:
	Events.player_turn_started.emit()
	var enemies := battle.enemy_handler.get_live_enemies()
	_check(not enemies.is_empty(), "kill relic smoke has an enemy source")
	if enemies.is_empty():
		return
	battle.char_stats.health = battle.char_stats.max_health - 10
	var health_before := battle.char_stats.health
	var hand_before := battle.player_handler.hand.get_child_count()
	Events.enemy_died.emit(enemies[0])
	await get_tree().create_timer(0.4).timeout
	_check(battle.char_stats.health == health_before + 2, "nirvana ember heals two on kill")
	_check(battle.player_handler.hand.get_child_count() == hand_before + 1, "spirit cleaver talisman draws on the first kill")
	Events.enemy_died.emit(enemies[0])
	await get_tree().create_timer(0.4).timeout
	_check(battle.char_stats.health == health_before + 4, "nirvana ember triggers for every kill")
	_check(battle.player_handler.hand.get_child_count() == hand_before + 1, "spirit cleaver talisman triggers once per turn")


func _add_draw_cards(battle: Battle, amount: int) -> void:
	for index in amount:
		var card := Card.new()
		card.id = "universal_relic_draw_%s" % index
		battle.char_stats.draw_pile.add_card(card)


func _find_relic_ui(handler: RelicHandler, relic_id: String) -> RelicUI:
	for child: Node in handler.relics.get_children():
		var relic_ui := child as RelicUI
		if relic_ui and relic_ui.relic and relic_ui.relic.id == relic_id:
			return relic_ui
	return null


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("UNIVERSAL_RELIC_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("UNIVERSAL_RELIC_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("UNIVERSAL_RELIC_SMOKE_TIMEOUT")
	get_tree().paused = false
	get_tree().quit(2)
