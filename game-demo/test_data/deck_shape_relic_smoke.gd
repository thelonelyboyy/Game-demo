extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const OTHER_CHARACTER_PATH := "res://characters/sword_cultivator/sword_cultivator.tres"
const BATTLE_PATH := "res://battles/demo_n_paper_wolf.tres"
const RELIC_POOL_PATH := "res://relics/relic_reward_pool.tres"
const SMALL_DECK_RELIC_PATH := "res://relics/empty_mind_jade_slip.tres"
const LARGE_DECK_RELIC_PATH := "res://relics/myriad_scroll_case.tres"
const RELIC_PATHS := [
	SMALL_DECK_RELIC_PATH,
	LARGE_DECK_RELIC_PATH,
	"res://relics/three_forms_crucible.tres",
	"res://relics/light_step_abacus.tres",
	"res://relics/tempered_scripture_seal.tres",
]

var failures: PackedStringArray = []


func _ready() -> void:
	get_tree().create_timer(40.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	var other_character := load(OTHER_CHARACTER_PATH) as CharacterStats
	var battle_stats := load(BATTLE_PATH) as BattleStats
	var pool := load(RELIC_POOL_PATH) as RelicRewardPool
	_check(
		battle_scene != null
		and relic_handler_scene != null
		and character_resource != null
		and other_character != null
		and battle_stats != null
		and pool != null,
		"deck shape relic support resources load"
	)
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

	relic_handler.add_relic(load(SMALL_DECK_RELIC_PATH) as Relic)
	for path: String in RELIC_PATHS.slice(2):
		relic_handler.add_relic(load(path) as Relic)
	relic_handler.add_relic(load(LARGE_DECK_RELIC_PATH) as Relic)
	_check(not relic_handler.has_relic("myriad_scroll_case"), "small and large deck relics are mutually exclusive")

	var character := character_resource.create_instance() as CharacterStats
	while character.deck.cards.size() > 12:
		character.deck.cards.pop_back()
	_check(character.deck.cards.size() == 12, "small deck battle starts with twelve permanent cards")
	var battle := battle_scene.instantiate() as Battle
	add_child(battle)
	battle.char_stats = character
	battle.battle_stats = battle_stats
	battle.relics = relic_handler
	battle.start_battle()
	await get_tree().create_timer(3.0).timeout

	_check(battle.player.status_handler.get_status_stacks("spell_ward") == 2, "empty mind jade slip grants two spell ward to a small deck")
	await _check_large_deck_relic(battle, relic_handler)
	await _check_type_harmony_relic(battle)
	await _check_zero_cost_relic(battle)
	await _check_upgraded_card_relic(battle)

	get_tree().paused = false
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame
	_finish()


func _check_large_deck_relic(battle: Battle, relic_handler: RelicHandler) -> void:
	relic_handler.remove_relic("empty_mind_jade_slip")
	await get_tree().process_frame
	relic_handler.add_relic(load(LARGE_DECK_RELIC_PATH) as Relic)
	_check(relic_handler.has_relic("myriad_scroll_case"), "large deck relic equips after removing its counterpart")
	while battle.char_stats.deck.cards.size() < 20:
		var card := Card.new()
		card.id = "large_deck_%s" % battle.char_stats.deck.cards.size()
		battle.char_stats.deck.add_card(card)
	battle.char_stats.block = 0
	var relic_ui := _find_relic_ui(relic_handler, "myriad_scroll_case")
	relic_ui.relic.activate_relic(relic_ui)
	_check(battle.char_stats.block == 15, "myriad scroll case grants fifteen block to a large deck")


func _check_type_harmony_relic(battle: Battle) -> void:
	Events.player_turn_started.emit()
	battle.char_stats.mana = 0
	battle.char_stats.block = 0
	for type in [Card.Type.ATTACK, Card.Type.SKILL, Card.Type.POWER]:
		var card := Card.new()
		card.id = "harmony_%s" % type
		card.type = type
		card.cost = 1
		Events.card_played.emit(card)
	await get_tree().process_frame
	_check(battle.char_stats.mana == 1 and battle.char_stats.block == 6, "three forms crucible rewards all three card types")
	for type in [Card.Type.ATTACK, Card.Type.SKILL, Card.Type.POWER]:
		var card := Card.new()
		card.type = type
		card.cost = 1
		Events.card_played.emit(card)
	_check(battle.char_stats.mana == 1 and battle.char_stats.block == 6, "three forms crucible triggers once per turn")
	Events.player_turn_started.emit()
	for type in [Card.Type.ATTACK, Card.Type.SKILL, Card.Type.POWER]:
		var card := Card.new()
		card.type = type
		card.cost = 1
		Events.card_played.emit(card)
	_check(battle.char_stats.mana == 2 and battle.char_stats.block == 12, "three forms crucible resets next turn")


func _check_zero_cost_relic(battle: Battle) -> void:
	Events.player_turn_started.emit()
	_add_draw_cards(battle, 4)
	var hand_before := battle.player_handler.hand.get_child_count()
	for index in 3:
		Events.card_played.emit(_make_card("zero_%s" % index, Card.Type.SKILL, 0))
	await get_tree().create_timer(0.6).timeout
	_check(battle.player_handler.hand.get_child_count() == hand_before + 1, "light step abacus draws on the third zero-cost card")
	Events.card_played.emit(_make_card("zero_fourth", Card.Type.SKILL, 0))
	await get_tree().create_timer(0.6).timeout
	_check(battle.player_handler.hand.get_child_count() == hand_before + 1, "light step abacus triggers once per turn")
	Events.player_turn_started.emit()
	for index in 3:
		Events.card_played.emit(_make_card("zero_reset_%s" % index, Card.Type.SKILL, 0))
	await get_tree().create_timer(0.6).timeout
	_check(battle.player_handler.hand.get_child_count() == hand_before + 2, "light step abacus resets next turn")


func _check_upgraded_card_relic(battle: Battle) -> void:
	Events.player_turn_started.emit()
	battle.char_stats.block = 0
	var upgraded := _make_card("upgraded_first", Card.Type.SKILL, 1)
	upgraded.upgraded = true
	Events.card_played.emit(upgraded)
	_check(battle.char_stats.block == 6, "tempered scripture seal grants six block for an upgraded card")
	Events.card_played.emit(upgraded)
	_check(battle.char_stats.block == 6, "tempered scripture seal triggers once per turn")
	Events.player_turn_started.emit()
	Events.card_played.emit(upgraded)
	_check(battle.char_stats.block == 12, "tempered scripture seal resets next turn")


func _make_card(id: String, type: Card.Type, cost: int) -> Card:
	var card := Card.new()
	card.id = id
	card.type = type
	card.cost = cost
	return card


func _add_draw_cards(battle: Battle, amount: int) -> void:
	for index in amount:
		var card := Card.new()
		card.id = "deck_shape_draw_%s" % index
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
		print("DECK_SHAPE_RELIC_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("DECK_SHAPE_RELIC_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("DECK_SHAPE_RELIC_SMOKE_TIMEOUT")
	get_tree().paused = false
	get_tree().quit(2)
