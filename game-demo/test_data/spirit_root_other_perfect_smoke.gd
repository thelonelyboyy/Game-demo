extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const BATTLE_PATH := "res://battles/demo_n_mist_wolf.tres"

var failures: PackedStringArray = []
var current_step := "startup"


func _ready() -> void:
	get_tree().create_timer(12.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	current_step = "load_support"
	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	var battle_stats := load(BATTLE_PATH) as BattleStats
	_check(battle_scene != null and relic_handler_scene != null and character_resource != null and battle_stats != null, "other spirit-root support resources load")
	if not battle_scene or not relic_handler_scene or not character_resource or not battle_stats:
		_finish()
		return

	var character := character_resource.create_instance(Card.Element.METAL)
	var relic_handler := relic_handler_scene.instantiate() as RelicHandler
	add_child(relic_handler)
	await get_tree().process_frame
	var battle := battle_scene.instantiate() as Battle
	add_child(battle)
	battle.char_stats = character
	battle.battle_stats = battle_stats
	battle.relics = relic_handler
	battle.start_battle()
	current_step = "wait_for_battle"
	await get_tree().create_timer(1.5).timeout

	current_step = "metal"
	_check_metal(battle)
	current_step = "earth"
	_check_earth(battle)
	current_step = "water"
	await _check_water(battle)
	current_step = "wood"
	_check_wood(battle)

	current_step = "cleanup"
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame
	_finish()


func _check_metal(battle: Battle) -> void:
	var character := battle.char_stats
	_set_complete_root(character, Card.Element.METAL)
	var before := battle.player.status_handler.get_status_stacks("muscle")
	battle.spirit_root_handler._on_card_played(_matching_card(Card.Element.METAL))
	_check(battle.player.status_handler.get_status_stacks("muscle") == before + 1, "metal completion grants one muscle stack")
	battle.spirit_root_handler._on_card_played(_matching_card(Card.Element.METAL))
	_check(battle.player.status_handler.get_status_stacks("muscle") == before + 1, "metal completion triggers only once per turn")
	battle.spirit_root_handler._on_player_turn_started()
	battle.spirit_root_handler._on_card_played(_matching_card(Card.Element.METAL))
	_check(battle.player.status_handler.get_status_stacks("muscle") == before + 2, "metal completion resets next turn")


func _check_earth(battle: Battle) -> void:
	var character := battle.char_stats
	_set_complete_root(character, Card.Element.EARTH)
	var before := battle.player.status_handler.get_status_stacks("true_essence")
	battle.spirit_root_handler._on_card_played(_matching_card(Card.Element.EARTH))
	_check(battle.player.status_handler.get_status_stacks("true_essence") == before + 1, "earth completion grants one true essence stack")
	battle.spirit_root_handler._on_card_played(_matching_card(Card.Element.EARTH))
	_check(battle.player.status_handler.get_status_stacks("true_essence") == before + 1, "earth completion triggers only once per turn")
	battle.spirit_root_handler._on_player_turn_started()
	battle.spirit_root_handler._on_card_played(_matching_card(Card.Element.EARTH))
	_check(battle.player.status_handler.get_status_stacks("true_essence") == before + 2, "earth completion resets next turn")


func _check_water(battle: Battle) -> void:
	var character := battle.char_stats
	_set_complete_root(character, Card.Element.WATER)
	character.draw_pile.clear()
	character.discard.clear()
	var drawn := Card.new()
	drawn.id = "water_completion_draw"
	drawn.display_name = "水灵测试牌"
	drawn.type = Card.Type.SKILL
	drawn.target = Card.Target.SELF
	drawn.cost = 2
	character.draw_pile.add_card(drawn)
	var hand_before := battle.player_handler.hand.get_child_count()
	battle.spirit_root_handler._on_card_played(_matching_card(Card.Element.WATER))
	await get_tree().create_timer(0.35).timeout
	_check(battle.player_handler.hand.get_child_count() == hand_before + 1, "water completion draws one card")
	_check(drawn.cost == 1, "water completion reduces the drawn card cost by one for the turn")
	_check(battle.spirit_root_handler.water_discount_pending == 0, "water discount is consumed by that draw")

	var second := Card.new()
	second.id = "water_completion_second"
	second.display_name = "水灵第二张测试牌"
	second.type = Card.Type.SKILL
	second.target = Card.Target.SELF
	second.cost = 2
	character.draw_pile.add_card(second)
	battle.spirit_root_handler._on_card_played(_matching_card(Card.Element.WATER))
	await get_tree().create_timer(0.35).timeout
	_check(second.cost == 2 and character.draw_pile.cards.has(second), "water completion does not trigger twice in one turn")

	battle.spirit_root_handler._on_player_turn_started()
	battle.spirit_root_handler._on_card_played(_matching_card(Card.Element.WATER))
	await get_tree().create_timer(0.35).timeout
	_check(second.cost == 1 and not character.draw_pile.cards.has(second), "water completion resets and discounts the next turn draw")


func _check_wood(battle: Battle) -> void:
	var character := battle.char_stats
	battle.player.status_handler.remove_status("true_essence")
	_set_complete_root(character, Card.Element.WOOD)
	character.health = character.max_health - 10
	character.block = 0
	battle.spirit_root_handler._on_card_played(_matching_card(Card.Element.WOOD))
	_check(character.spirit_root_wood_played_this_turn and not character.spirit_root_perfect_triggered_this_turn, "wood completion waits until turn end")
	battle.spirit_root_handler._on_player_turn_ended()
	_check(character.health == character.max_health - 7, "wood completion heals three when injured")
	_check(character.spirit_root_perfect_triggered_this_turn, "wood completion marks the turn settled")

	battle.spirit_root_handler._on_player_turn_started()
	character.health = character.max_health
	character.block = 0
	battle.spirit_root_handler._on_card_played(_matching_card(Card.Element.WOOD))
	battle.spirit_root_handler._on_player_turn_ended()
	_check(character.block == 3, "wood completion grants three block at full health")

	battle.spirit_root_handler._on_player_turn_started()
	character.health = character.max_health - 10
	var before := character.health
	battle.spirit_root_handler._on_player_turn_ended()
	_check(character.health == before and not character.spirit_root_perfect_triggered_this_turn, "wood completion does nothing without a wood card")


func _set_complete_root(character: CharacterStats, element: Card.Element) -> void:
	character.spirit_root = element
	for card: Card in character.deck.cards:
		if card:
			card.element = Card.Element.NONE
	for index in mini(7, character.deck.cards.size()):
		character.deck.cards[index].element = element
	character.reset_spirit_root_turn_flags()
	_check(character.is_spirit_root_complete(), "%s root reaches completion for its regression setup" % element)


func _matching_card(element: Card.Element) -> Card:
	var card := Card.new()
	card.id = "spirit_root_trigger_%s" % element
	card.display_name = "灵根触发牌"
	card.type = Card.Type.SKILL
	card.target = Card.Target.SELF
	card.element = element
	return card


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("SPIRIT_ROOT_OTHER_PERFECT_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("SPIRIT_ROOT_OTHER_PERFECT_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("SPIRIT_ROOT_OTHER_PERFECT_SMOKE_TIMEOUT: %s" % current_step)
	get_tree().paused = false
	get_tree().quit(2)
