extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const BATTLE_PATH := "res://battles/demo_n_paper_wolf.tres"
const STRIKE_PATH := "res://characters/demonic_cultivator/cards/demon_strike.tres"
const DEFEND_PATH := "res://characters/demonic_cultivator/cards/demon_defend.tres"
const SPIRIT_LOCK_PATH := "res://common_cards/status/spirit_lock_seal.tres"
const EMBER_BRAND_PATH := "res://common_cards/status/calamity_ember_brand.tres"
const BLOOD_DEBT_PATH := "res://common_cards/status/blood_debt_curse.tres"
const MIND_SIEVE_PATH := "res://characters/demonic_cultivator/cards/demon_mind_sieve.tres"
const BLOOD_CASTOFF_PATH := "res://characters/demonic_cultivator/cards/demon_blood_castoff.tres"
const ASH_RECOLLECTION_PATH := "res://characters/demonic_cultivator/cards/demon_ash_recollection.tres"
const DRAFT_POOL_PATH := "res://characters/demonic_cultivator/demonic_cultivator_draftable_cards.tres"

var failures: PackedStringArray = []


func _ready() -> void:
	get_tree().create_timer(40.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	var battle_stats := load(BATTLE_PATH) as BattleStats
	_check(
		battle_scene and relic_handler_scene and character_resource and battle_stats,
		"pile control battle resources load"
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

	_check(battle.player_handler.player_actions_enabled, "pile control battle reaches playable turn")
	_clear_hand(battle.player_handler)
	await get_tree().process_frame
	_check_filter_order_and_lifecycle(battle)
	await _check_random_discard_reward(battle)
	_check_card_resources_and_pool()

	get_tree().paused = false
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame
	_finish()


func _check_filter_order_and_lifecycle(battle: Battle) -> void:
	battle.char_stats.draw_pile.clear()
	battle.char_stats.discard.clear()
	battle.char_stats.mana = 4
	battle.char_stats.health = 30
	var strike := _copy_card(STRIKE_PATH)
	var seal := _copy_card(SPIRIT_LOCK_PATH)
	var brand := _copy_card(EMBER_BRAND_PATH)
	var defend := _copy_card(DEFEND_PATH)
	for card: Card in [strike, seal, brand, defend]:
		battle.char_stats.draw_pile.add_card(card)

	var filtered := battle.player_handler.filter_afflictions_from_draw_pile(4, 1)
	_check(filtered.size() == 1 and filtered[0] == seal, "limited filter removes the first top-deck affliction")
	_check(
		_card_ids(battle.char_stats.draw_pile.cards) == PackedStringArray(["demon_strike", "calamity_ember_brand", "demon_defend"]),
		"limited filter preserves relative order of unfiltered cards"
	)
	_check(battle.char_stats.discard.cards.has(seal), "filtered affliction moves to discard")
	_check(battle.char_stats.mana == 4, "filtering spirit lock does not trigger its on-draw mana loss")

	filtered = battle.player_handler.filter_afflictions_from_draw_pile(3, 0)
	_check(filtered.size() == 1 and filtered[0] == brand, "unlimited filter removes all inspected afflictions")
	_check(
		_card_ids(battle.char_stats.draw_pile.cards) == PackedStringArray(["demon_strike", "demon_defend"]),
		"second filter keeps normal draw order intact"
	)
	_check(battle.char_stats.health == 30, "filtering ember brand does not trigger its end-turn backlash")


func _check_random_discard_reward(battle: Battle) -> void:
	battle.char_stats.discard.clear()
	battle.char_stats.health = 20
	battle.char_stats.block = 0
	var debt := _copy_card(BLOOD_DEBT_PATH)
	var castoff := _copy_card(BLOOD_CASTOFF_PATH) as CultivationCard
	_check(debt and castoff, "random discard support cards load")
	if not debt or not castoff:
		return
	_check(battle.player_handler.hand.add_card(debt, false), "blood debt enters hand as discard target")
	_check(battle.player_handler.hand.add_card(castoff, false), "blood castoff enters hand as source")
	await get_tree().process_frame
	var targets: Array[Node] = [battle.player]
	castoff.configured_effects[0].execute(castoff, targets, battle.player.modifier_handler)
	await get_tree().process_frame
	_check(battle.char_stats.health == 18, "random discard preserves blood debt discard backlash")
	_check(battle.char_stats.block == 6, "successful random discard grants configured block")
	_check(battle.char_stats.discard.cards.has(debt), "randomly discarded card enters the discard pile")
	_check(_find_card_ui(battle.player_handler.hand, castoff) != null, "discard effect never selects its source card")


func _check_card_resources_and_pool() -> void:
	var mind_sieve := load(MIND_SIEVE_PATH) as CultivationCard
	var blood_castoff := load(BLOOD_CASTOFF_PATH) as CultivationCard
	var ash_recollection := load(ASH_RECOLLECTION_PATH) as CultivationCard
	var pool := load(DRAFT_POOL_PATH) as CardPile
	_check(mind_sieve and blood_castoff and ash_recollection and pool, "pile control card resources load")
	if not mind_sieve or not blood_castoff or not ash_recollection or not pool:
		return
	_check(mind_sieve.configured_effects[0].amount == 4, "mind sieve inspects four cards")
	_check(mind_sieve.configured_effects[0].max_cards == 2, "mind sieve filters at most two afflictions")
	_check(mind_sieve.configured_effects[1].amount == 1, "mind sieve replaces itself with one draw")
	_check(ash_recollection.configured_effects[0].amount == 6, "ash recollection inspects six cards")
	_check(ash_recollection.configured_effects[0].max_cards == 0, "ash recollection filters all inspected afflictions")
	_check(ash_recollection.configured_effects[1].amount == 2, "ash recollection draws two cards")
	var upgraded := blood_castoff.duplicate(true) as CultivationCard
	_check(upgraded.upgrade(), "blood castoff can be upgraded")
	_check(upgraded.configured_effects[0].amount == 9, "blood castoff upgrade raises block from six to nine")
	for card_id: String in ["demon_mind_sieve", "demon_blood_castoff", "demon_ash_recollection"]:
		_check(_pool_has_id(pool, card_id), "%s is in the demonic reward pool" % card_id)


func _copy_card(path: String) -> Card:
	var card := load(path) as Card
	return card.duplicate(true) as Card if card else null


func _card_ids(cards: Array[Card]) -> PackedStringArray:
	var ids := PackedStringArray()
	for card: Card in cards:
		ids.append(card.id if card else "")
	return ids


func _pool_has_id(pool: CardPile, card_id: String) -> bool:
	for card: Card in pool.cards:
		if card and card.id == card_id:
			return true
	return false


func _clear_hand(player_handler: PlayerHandler) -> void:
	if not player_handler or not player_handler.hand:
		return
	for child: Node in player_handler.hand.get_children():
		var card_ui := child as CardUI
		if card_ui:
			player_handler.remove_card_from_hand(card_ui)


func _find_card_ui(hand: Hand, card: Card) -> CardUI:
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
		print("PILE_CONTROL_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("PILE_CONTROL_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("PILE_CONTROL_SMOKE_TIMEOUT")
	get_tree().paused = false
	get_tree().quit(2)
