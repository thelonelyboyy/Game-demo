extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const OTHER_CHARACTER_PATH := "res://characters/sword_cultivator/sword_cultivator.tres"
const BATTLE_PATH := "res://battles/demo_n_paper_wolf.tres"
const RELIC_POOL_PATH := "res://relics/relic_reward_pool.tres"
const RELIC_PATHS := [
	"res://relics/retained_edge_tassel.tres",
	"res://relics/affliction_binding_clip.tres",
	"res://relics/empty_breath_seal.tres",
	"res://relics/cleansing_jade_page.tres",
	"res://relics/phantom_bookmark.tres",
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
		"hand state relic support resources load"
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
		relic_handler.add_relic(relic)

	var battle := battle_scene.instantiate() as Battle
	add_child(battle)
	battle.char_stats = character_resource.create_instance()
	battle.battle_stats = battle_stats
	battle.relics = relic_handler
	battle.start_battle()
	await get_tree().create_timer(3.0).timeout

	_check(battle.player_handler.player_actions_enabled, "hand state relic battle reaches a playable turn")
	await _check_end_turn_hand_relics(battle, relic_handler)
	_check_zero_mana_relic(battle, relic_handler)
	await _check_affliction_draw_relic(battle)
	await _check_temporary_draw_relic(battle)

	get_tree().paused = false
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame
	_finish()


func _check_end_turn_hand_relics(battle: Battle, relic_handler: RelicHandler) -> void:
	var added_cards: Array[Card] = []
	for index in 2:
		var retained := Card.new()
		retained.id = "retained_relic_%s" % index
		retained.ensure_mechanic_tag(Card.RETAIN_MECHANIC_TAG)
		added_cards.append(retained)
		_check(battle.player_handler.hand.add_card(retained, false), "retained relic test card enters the hand")
	var status := Card.new()
	status.id = "affliction_status"
	status.ensure_mechanic_tag(Card.STATUS_MECHANIC_TAG)
	added_cards.append(status)
	_check(battle.player_handler.hand.add_card(status, false), "status relic test card enters the hand")
	var curse := Card.new()
	curse.id = "affliction_curse"
	curse.ensure_mechanic_tag(Card.CURSE_MECHANIC_TAG)
	added_cards.append(curse)
	_check(battle.player_handler.hand.add_card(curse, false), "curse relic test card enters the hand")
	await get_tree().process_frame

	var retained_ui := _find_relic_ui(relic_handler, "retained_edge_tassel")
	var affliction_ui := _find_relic_ui(relic_handler, "affliction_binding_clip")
	_check(retained_ui != null and affliction_ui != null, "end turn hand relic UIs are available")
	battle.char_stats.block = 0
	retained_ui.relic.activate_relic(retained_ui)
	_check(battle.char_stats.block == 8, "retained edge tassel grants four block per retained card")
	battle.char_stats.block = 0
	affliction_ui.relic.activate_relic(affliction_ui)
	_check(battle.char_stats.block == 8, "affliction binding clip counts status and curse cards")

	for card: Card in added_cards:
		var card_ui := _find_card_ui(battle.player_handler.hand, card)
		if card_ui:
			battle.player_handler.remove_card_from_hand(card_ui)
	await get_tree().process_frame


func _check_zero_mana_relic(battle: Battle, relic_handler: RelicHandler) -> void:
	var relic_ui := _find_relic_ui(relic_handler, "empty_breath_seal")
	_check(relic_ui != null, "empty breath seal UI is available")
	if not relic_ui:
		return
	battle.char_stats.block = 0
	battle.char_stats.mana = 1
	relic_ui.relic.activate_relic(relic_ui)
	_check(battle.char_stats.block == 0, "empty breath seal stays dormant with unspent mana")
	battle.char_stats.mana = 0
	relic_ui.relic.activate_relic(relic_ui)
	_check(battle.char_stats.block == 7, "empty breath seal rewards spending all mana")


func _check_affliction_draw_relic(battle: Battle) -> void:
	_add_draw_cards(battle, 6, "affliction_draw")
	var hand_before := battle.player_handler.hand.get_child_count()
	var status := Card.new()
	status.id = "drawn_status"
	status.ensure_mechanic_tag(Card.STATUS_MECHANIC_TAG)
	Events.card_drawn.emit(status)
	await get_tree().create_timer(0.6).timeout
	_check(battle.player_handler.hand.get_child_count() == hand_before + 1, "cleansing jade page replaces the first status draw")
	Events.card_drawn.emit(status)
	await get_tree().create_timer(0.6).timeout
	_check(battle.player_handler.hand.get_child_count() == hand_before + 1, "cleansing jade page triggers once per turn")
	Events.player_turn_started.emit()
	var curse := Card.new()
	curse.id = "drawn_curse"
	curse.ensure_mechanic_tag(Card.CURSE_MECHANIC_TAG)
	Events.card_drawn.emit(curse)
	await get_tree().create_timer(0.6).timeout
	_check(battle.player_handler.hand.get_child_count() == hand_before + 2, "cleansing jade page resets and recognizes curses")


func _check_temporary_draw_relic(battle: Battle) -> void:
	_add_draw_cards(battle, 4, "temporary_draw")
	var hand_before := battle.player_handler.hand.get_child_count()
	var temporary := Card.new()
	temporary.id = "temporary_relic_card"
	temporary.temporary = true
	temporary.ensure_mechanic_tag(Card.TEMPORARY_MECHANIC_TAG)
	Events.card_played.emit(temporary)
	await get_tree().create_timer(0.6).timeout
	_check(battle.player_handler.hand.get_child_count() == hand_before + 1, "phantom bookmark draws for the first temporary card")
	Events.card_played.emit(temporary)
	await get_tree().create_timer(0.6).timeout
	_check(battle.player_handler.hand.get_child_count() == hand_before + 1, "phantom bookmark triggers once per turn")
	Events.player_turn_started.emit()
	Events.card_played.emit(temporary)
	await get_tree().create_timer(0.6).timeout
	_check(battle.player_handler.hand.get_child_count() == hand_before + 2, "phantom bookmark resets next turn")


func _add_draw_cards(battle: Battle, amount: int, prefix: String) -> void:
	for index in amount:
		var card := Card.new()
		card.id = "%s_%s" % [prefix, index]
		battle.char_stats.draw_pile.add_card(card)


func _find_card_ui(hand: Hand, card: Card) -> CardUI:
	for child: Node in hand.get_children():
		var card_ui := child as CardUI
		if card_ui and card_ui.card == card:
			return card_ui
	return null


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
		print("HAND_STATE_RELIC_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("HAND_STATE_RELIC_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("HAND_STATE_RELIC_SMOKE_TIMEOUT")
	get_tree().paused = false
	get_tree().quit(2)
