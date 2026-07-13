extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const OTHER_CHARACTER_PATH := "res://characters/sword_cultivator/sword_cultivator.tres"
const BATTLE_PATH := "res://battles/demo_n_paper_wolf.tres"
const RELIC_POOL_PATH := "res://relics/relic_reward_pool.tres"
const GROWTH_CARD_PATH := "res://characters/demonic_cultivator/cards/demon_blood_rite_slash.tres"
const DISCOVER_CARD_PATH := "res://characters/demonic_cultivator/cards/demon_forbidden_archive.tres"
const DISCARD_RELIC_PATH := "res://relics/discard_guard_ring.tres"
const EXHAUST_RELIC_PATH := "res://relics/ember_ink_measure.tres"
const GROWTH_RELIC_PATH := "res://relics/growth_echo_stone.tres"
const EXTRA_PICK_RELIC_PATH := "res://relics/myriad_archive_tally.tres"
const UPGRADE_RELIC_PATH := "res://relics/gilded_archive_mite.tres"
const RELIC_PATHS := [
	DISCARD_RELIC_PATH,
	EXHAUST_RELIC_PATH,
	GROWTH_RELIC_PATH,
	EXTRA_PICK_RELIC_PATH,
	UPGRADE_RELIC_PATH,
]

var failures: PackedStringArray = []
var last_request_picks := 0
var last_request_bonus_upgrades := 0
var last_selected_cards: Array[Card] = []
var prefer_upgradeable_choice := false


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
		"lifecycle relic support resources load"
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

	for path: String in [DISCARD_RELIC_PATH, EXHAUST_RELIC_PATH, GROWTH_RELIC_PATH, EXTRA_PICK_RELIC_PATH]:
		relic_handler.add_relic(load(path) as Relic)
	relic_handler.add_relic(load(UPGRADE_RELIC_PATH) as Relic)
	_check(not relic_handler.has_relic("gilded_archive_mite"), "discovery assistance relics are mutually exclusive")

	var battle := battle_scene.instantiate() as Battle
	add_child(battle)
	battle.char_stats = character_resource.create_instance()
	battle.battle_stats = battle_stats
	battle.relics = relic_handler
	battle.start_battle()
	await get_tree().create_timer(3.0).timeout

	_check(battle.player_handler.player_actions_enabled, "lifecycle relic battle reaches a playable turn")
	await _check_discard_relic(battle)
	await _check_exhaust_relic(battle)
	await _check_growth_relic(battle)
	await _check_discovery_relics(battle, relic_handler)

	get_tree().paused = false
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame
	_finish()


func _check_discard_relic(battle: Battle) -> void:
	battle.char_stats.block = 0
	await _discard_test_card(battle, "discard_relic_first")
	_check(battle.char_stats.block == 4, "discard guard ring grants four block")
	await _discard_test_card(battle, "discard_relic_second")
	_check(battle.char_stats.block == 4, "discard guard ring triggers once per turn")
	Events.player_turn_started.emit()
	await _discard_test_card(battle, "discard_relic_reset")
	_check(battle.char_stats.block == 8, "discard guard ring resets next turn")


func _check_exhaust_relic(battle: Battle) -> void:
	battle.char_stats.block = 0
	await _exhaust_test_card(battle, "exhaust_relic_first")
	_check(battle.char_stats.block == 6, "ember ink measure grants six block")
	await _exhaust_test_card(battle, "exhaust_relic_second")
	_check(battle.char_stats.block == 6, "ember ink measure triggers once per turn")
	Events.player_turn_started.emit()
	await _exhaust_test_card(battle, "exhaust_relic_reset")
	_check(battle.char_stats.block == 12, "ember ink measure resets next turn")


func _check_growth_relic(_battle: Battle) -> void:
	var first := _fresh_growth_card()
	_check(first != null and first.configured_effects[1].amount == 7, "growth relic test card starts at seven damage")
	Events.card_played.emit(first)
	await get_tree().process_frame
	_check(first.configured_effects[1].amount == 9, "growth echo stone grows the first growth card before resolution")

	var second := _fresh_growth_card()
	Events.card_played.emit(second)
	await get_tree().process_frame
	_check(second.configured_effects[1].amount == 7, "growth echo stone triggers once per turn")
	Events.player_turn_started.emit()
	var third := _fresh_growth_card()
	Events.card_played.emit(third)
	await get_tree().process_frame
	_check(third.configured_effects[1].amount == 9, "growth echo stone resets next turn")


func _check_discovery_relics(battle: Battle, relic_handler: RelicHandler) -> void:
	var battle_ui_listener := Callable(battle.battle_ui, "_on_card_discovery_requested")
	var restore_battle_ui_listener := Events.card_discovery_requested.is_connected(battle_ui_listener)
	if restore_battle_ui_listener:
		Events.card_discovery_requested.disconnect(battle_ui_listener)
	if not Events.card_discovery_requested.is_connected(_auto_resolve_discovery):
		Events.card_discovery_requested.connect(_auto_resolve_discovery)

	prefer_upgradeable_choice = false
	await _execute_discovery(battle)
	_check(last_request_picks == 2 and last_selected_cards.size() == 2, "myriad archive tally adds one discovery pick")
	await _execute_discovery(battle)
	_check(last_request_picks == 1 and last_selected_cards.size() == 1, "myriad archive tally triggers once per turn")
	Events.player_turn_started.emit()
	await _execute_discovery(battle)
	_check(last_request_picks == 2 and last_selected_cards.size() == 2, "myriad archive tally resets next turn")

	relic_handler.remove_relic("myriad_archive_tally")
	await get_tree().process_frame
	relic_handler.add_relic(load(UPGRADE_RELIC_PATH) as Relic)
	_check(relic_handler.has_relic("gilded_archive_mite"), "upgrade discovery relic equips after its exclusive counterpart is removed")
	var upgrade_relic_ui := _find_relic_ui(relic_handler, "gilded_archive_mite")
	_check(
		upgrade_relic_ui != null
		and Events.card_discovery_prepared.is_connected(Callable(upgrade_relic_ui.relic, "_on_discovery_prepared")),
		"upgrade discovery relic connects to discovery requests"
	)
	Events.player_turn_started.emit()
	prefer_upgradeable_choice = true
	await _execute_discovery(battle)
	_check(last_request_picks == 1 and last_selected_cards.size() == 1, "gilded archive mite keeps the normal pick count")
	_check(
		not last_selected_cards.is_empty() and last_selected_cards[0].upgraded,
		"gilded archive mite upgrades the selected discovery card before adding it (bonus=%s, type=%s)" % [
			last_request_bonus_upgrades,
			last_selected_cards[0].upgrade_type if not last_selected_cards.is_empty() else -1,
		]
	)

	if Events.card_discovery_requested.is_connected(_auto_resolve_discovery):
		Events.card_discovery_requested.disconnect(_auto_resolve_discovery)
	if restore_battle_ui_listener and is_instance_valid(battle.battle_ui):
		Events.card_discovery_requested.connect(battle_ui_listener)


func _discard_test_card(battle: Battle, id: String) -> void:
	var card := Card.new()
	card.id = id
	_check(battle.player_handler.hand.add_card(card, false), "%s enters the hand" % id)
	await get_tree().process_frame
	battle.player_handler.discard_card_from_hand(_find_card_ui(battle.player_handler.hand, card), false)
	await get_tree().process_frame


func _exhaust_test_card(battle: Battle, id: String) -> void:
	var card := Card.new()
	card.id = id
	_check(battle.player_handler.hand.add_card(card, false), "%s enters the hand" % id)
	await get_tree().process_frame
	battle.player_handler.exhaust_card_from_hand(_find_card_ui(battle.player_handler.hand, card))
	await get_tree().process_frame


func _fresh_growth_card() -> CultivationCard:
	return (load(GROWTH_CARD_PATH) as Card).duplicate(true) as CultivationCard


func _execute_discovery(battle: Battle) -> void:
	last_request_picks = 0
	last_selected_cards.clear()
	var card := (load(DISCOVER_CARD_PATH) as Card).duplicate(true) as CultivationCard
	var targets: Array[Node] = [battle.player]
	card.configured_effects[0].execute(card, targets, battle.player.modifier_handler)
	await get_tree().process_frame


func _auto_resolve_discovery(request: CardDiscoveryRequest) -> void:
	last_request_picks = request.picks
	last_request_bonus_upgrades = request.bonus_upgrade_count
	var selected: Array[Card] = []
	if prefer_upgradeable_choice:
		for card: Card in request.choices:
			if card.can_upgrade():
				selected.append(card)
				break
	for card: Card in request.choices:
		if selected.size() >= request.picks:
			break
		if not selected.has(card):
			selected.append(card)
	last_selected_cards.assign(selected)
	request.resolve(selected)


func _find_card_ui(hand: Hand, card: Card) -> CardUI:
	if not hand or not card:
		return null
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
		print("LIFECYCLE_RELIC_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("LIFECYCLE_RELIC_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("LIFECYCLE_RELIC_SMOKE_TIMEOUT")
	get_tree().paused = false
	get_tree().quit(2)
