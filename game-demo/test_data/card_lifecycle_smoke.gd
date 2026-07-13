extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const BATTLE_PATH := "res://battles/demo_n_paper_wolf.tres"
const DISCARD_CARD_PATH := "res://characters/demonic_cultivator/cards/demon_blood_repay.tres"
const EXHAUST_CARD_PATH := "res://characters/demonic_cultivator/cards/engines/demon_sha_return.tres"
const GROWTH_CARD_PATH := "res://characters/demonic_cultivator/cards/demon_blood_rite_slash.tres"
const DISCOVER_CARD_PATH := "res://characters/demonic_cultivator/cards/demon_forbidden_archive.tres"

var failures: PackedStringArray = []
var discovered_cards: Array[Card] = []


func _ready() -> void:
	get_tree().create_timer(40.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	var battle_stats := load(BATTLE_PATH) as BattleStats
	_check(
		battle_scene != null
		and relic_handler_scene != null
		and character_resource != null
		and battle_stats != null,
		"card lifecycle battle resources load"
	)
	if not battle_scene or not relic_handler_scene or not character_resource or not battle_stats:
		_finish()
		return

	var relic_handler := relic_handler_scene.instantiate() as RelicHandler
	add_child(relic_handler)
	await get_tree().process_frame
	var battle := battle_scene.instantiate() as Battle
	add_child(battle)
	battle.char_stats = character_resource.create_instance()
	battle.battle_stats = battle_stats
	battle.relics = relic_handler
	battle.start_battle()
	await get_tree().create_timer(3.0).timeout

	_check(battle.player_handler.player_actions_enabled, "real battle reaches the playable player turn")
	await _check_discard_trigger(battle)
	await _check_exhaust_trigger(battle)
	await _check_growth_cycle(battle)
	await _check_discovery_cycle(battle)

	get_tree().paused = false
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame
	_finish()


func _check_discard_trigger(battle: Battle) -> void:
	var card := (load(DISCARD_CARD_PATH) as Card).duplicate(true) as CultivationCard
	_check(card != null and card.has_discard_trigger(), "discard trigger card loads in battle")
	if not card:
		return

	battle.char_stats.block = 0
	_check(battle.player_handler.hand.add_card(card, false), "discard trigger card enters the real hand")
	await get_tree().process_frame
	var card_ui := _find_card_ui(battle.player_handler.hand, card)
	battle.player_handler.discard_card_from_hand(card_ui, false)
	await get_tree().process_frame
	_check(battle.char_stats.block == 4, "discarding blood recompense grants four block")
	_check(battle.char_stats.discard.cards.has(card), "discard trigger card enters the discard pile")


func _check_exhaust_trigger(battle: Battle) -> void:
	var card := (load(EXHAUST_CARD_PATH) as Card).duplicate(true) as CultivationCard
	_check(card != null and card.has_exhaust_trigger(), "exhaust trigger card loads in battle")
	if not card:
		return

	battle.char_stats.mana = 0
	_check(battle.player_handler.hand.add_card(card, false), "exhaust trigger card enters the real hand")
	await get_tree().process_frame
	var card_ui := _find_card_ui(battle.player_handler.hand, card)
	battle.player_handler.exhaust_card_from_hand(card_ui)
	await get_tree().process_frame
	_check(battle.char_stats.mana == 1, "exhausting returning sha grants one mana")
	_check(battle.char_stats.exhaust_pile.cards.has(card), "exhaust trigger card enters the exhaust pile")
	_check(not battle.char_stats.discard.cards.has(card), "exhaust trigger card stays out of the discard pile")


func _check_growth_cycle(battle: Battle) -> void:
	var card := (load(GROWTH_CARD_PATH) as Card).duplicate(true) as CultivationCard
	_check(card != null and card.is_growth_card(), "growth card loads in battle")
	if not card or card.configured_effects.size() < 2:
		return

	_check(battle.player_handler.hand.add_card(card, false), "growth card enters the real hand")
	await get_tree().process_frame
	var card_ui := _find_card_ui(battle.player_handler.hand, card)
	var targets: Array[Node] = [battle.player]
	card.handle_lifecycle_trigger(Card.LifecycleTrigger.PLAYED, targets, battle.player.modifier_handler)
	battle.player_handler._on_card_played(card)
	if card_ui:
		battle.player_handler.hand.discard_card(card_ui, false)
	await get_tree().process_frame
	_check(card.configured_effects[1].amount == 9, "growth increases blood rite slash after play")
	_check(battle.char_stats.discard.cards.has(card), "played growth card enters the discard pile")

	battle.char_stats.draw_pile.clear()
	battle.player_handler.reshuffle_deck_from_discard()
	_check(battle.char_stats.draw_pile.cards.has(card), "growth card reshuffles into the draw pile")
	battle.char_stats.draw_pile.remove_card(card)
	battle.char_stats.draw_pile.add_card_to_top(card)
	battle.player_handler.draw_card()
	await get_tree().process_frame
	_check(_find_card_ui(battle.player_handler.hand, card) != null, "growth card can be drawn again")
	_check(card.configured_effects[1].amount == 9, "growth value survives discard and reshuffle")
	card.handle_lifecycle_trigger(Card.LifecycleTrigger.PLAYED, targets, battle.player.modifier_handler)
	_check(card.configured_effects[1].amount == 11, "growth continues on the same combat copy")

	var fresh := (load(GROWTH_CARD_PATH) as Card).duplicate(true) as CultivationCard
	_check(
		fresh != null and fresh.growth_accumulated == 0 and fresh.configured_effects[1].amount == 7,
		"growth does not mutate the permanent card resource"
	)
	var grown_ui := _find_card_ui(battle.player_handler.hand, card)
	if grown_ui:
		battle.player_handler.remove_card_from_hand(grown_ui)
	await get_tree().process_frame


func _check_discovery_cycle(battle: Battle) -> void:
	var card := (load(DISCOVER_CARD_PATH) as Card).duplicate(true) as CultivationCard
	_check(card != null and not card.configured_effects.is_empty(), "discover card loads in battle")
	if not card or card.configured_effects.is_empty():
		return

	_check(card.upgrade(), "discover card upgrades to a two-card choice")
	var effect = card.configured_effects[0]
	_check(effect.card_pool != null and effect.card_pool.cards.size() == 7, "discover uses its fixed seven-card pool")

	var battle_ui_listener := Callable(battle.battle_ui, "_on_card_discovery_requested")
	var restore_battle_ui_listener := Events.card_discovery_requested.is_connected(battle_ui_listener)
	if restore_battle_ui_listener:
		Events.card_discovery_requested.disconnect(battle_ui_listener)
	if not Events.card_discovery_requested.is_connected(_auto_resolve_discovery):
		Events.card_discovery_requested.connect(_auto_resolve_discovery)

	discovered_cards.clear()
	var targets: Array[Node] = [battle.player]
	effect.execute(card, targets, battle.player.modifier_handler)
	await get_tree().process_frame
	if Events.card_discovery_requested.is_connected(_auto_resolve_discovery):
		Events.card_discovery_requested.disconnect(_auto_resolve_discovery)
	if restore_battle_ui_listener and is_instance_valid(battle.battle_ui):
		Events.card_discovery_requested.connect(battle_ui_listener)

	_check(discovered_cards.size() == 2, "upgraded discover selects two cards")
	for discovered: Card in discovered_cards:
		_check(not discovered.is_temporary_card(), "discovered card is a persistent combat copy")
		_check(_find_card_ui(battle.player_handler.hand, discovered) != null, "discovered card enters the real hand")

	for discovered: Card in discovered_cards:
		var card_ui := _find_card_ui(battle.player_handler.hand, discovered)
		battle.player_handler.discard_card_from_hand(card_ui, false)
	await get_tree().process_frame
	for discovered: Card in discovered_cards:
		_check(battle.char_stats.discard.cards.has(discovered), "discovered card enters the discard pile")

	battle.char_stats.draw_pile.clear()
	battle.player_handler.reshuffle_deck_from_discard()
	for discovered: Card in discovered_cards:
		_check(battle.char_stats.draw_pile.cards.has(discovered), "discovered card reshuffles into the draw pile")
	for index in range(discovered_cards.size() - 1, -1, -1):
		var discovered := discovered_cards[index]
		battle.char_stats.draw_pile.remove_card(discovered)
		battle.char_stats.draw_pile.add_card_to_top(discovered)
	for _index in discovered_cards.size():
		battle.player_handler.draw_card()
	await get_tree().process_frame
	for discovered: Card in discovered_cards:
		_check(_find_card_ui(battle.player_handler.hand, discovered) != null, "discovered card can be drawn again")


func _auto_resolve_discovery(request) -> void:
	var selected: Array[Card] = []
	for index in range(mini(request.picks, request.choices.size())):
		selected.append(request.choices[index])
	discovered_cards.assign(selected)
	request.resolve(selected)


func _find_card_ui(hand: Hand, card: Card) -> CardUI:
	if not hand or not card:
		return null
	for child: Node in hand.get_children():
		var card_ui := child as CardUI
		if card_ui and card_ui.card == card:
			return card_ui
	return null


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("CARD_LIFECYCLE_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("CARD_LIFECYCLE_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("CARD_LIFECYCLE_SMOKE_TIMEOUT")
	get_tree().paused = false
	get_tree().quit(2)
