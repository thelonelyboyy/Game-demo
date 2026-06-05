class_name Shop
extends Control

const SHOP_CARD = preload("res://scenes/shop/shop_card.tscn")
const SHOP_RELIC = preload("res://scenes/shop/shop_relic.tscn")
const CARD_REMOVE_SCENE := preload("res://scenes/card_remove/card_remove.tscn")
const RELIC_REWARD_POOL := preload("res://relics/relic_reward_pool.tres")
const COMMON_SHOP_CARDS := [
	preload("res://common_cards/strike.tres"),
	preload("res://common_cards/defend.tres"),
	preload("res://common_cards/toxin.tres"),
]

const SHOP_CARD_COUNT := 6
const SHOP_RELIC_COUNT := 4
const MYTHIC_SHOP_CHANCE := 0.02

@export var shop_relics: Array[Relic]
@export var char_stats: CharacterStats
@export var run_stats: RunStats
@export var relic_handler: RelicHandler

@onready var ui_layer: CanvasLayer = $UILayer
@onready var cards: HBoxContainer = %Cards
@onready var relics: HBoxContainer = %Relics
@onready var remove_card_button: Button = %RemoveCardButton
@onready var shop_keeper_animation: AnimationPlayer = %ShopkeeperAnimation
@onready var blink_timer: Timer = %BlinkTimer
@onready var card_tooltip_popup: CardTooltipPopup = %CardTooltipPopup
@onready var modifier_handler: ModifierHandler = $ModifierHandler

var active_card_remove: CardRemove
var active_remove_cost := 0
var remove_service_used := false


func _ready() -> void:
	for shop_card: ShopCard in cards.get_children():
		shop_card.queue_free()

	for shop_relic: ShopRelic in relics.get_children():
		shop_relic.queue_free()

	Events.shop_card_bought.connect(_on_shop_card_bought)
	Events.shop_relic_bought.connect(_on_shop_relic_bought)
	remove_card_button.pressed.connect(_on_remove_card_button_pressed)

	_blink_timer_setup()
	blink_timer.timeout.connect(_on_blink_timer_timeout)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and card_tooltip_popup.visible:
		card_tooltip_popup.hide_tooltip()


func populate_shop() -> void:
	_generate_shop_cards()
	_generate_shop_relics()
	_update_remove_card_service()


func _blink_timer_setup() -> void:
	blink_timer.wait_time = randf_range(1.0, 5.0)
	blink_timer.start()


func _generate_shop_cards() -> void:
	var available_cards := _get_available_shop_cards()
	var shop_card_array := _pick_shop_cards(available_cards)

	for card: Card in shop_card_array:
		card.bind_spirit_root_owner(char_stats)
		var new_shop_card := SHOP_CARD.instantiate() as ShopCard
		cards.add_child(new_shop_card)
		new_shop_card.card = card
		new_shop_card.current_card_ui.tooltip_requested.connect(card_tooltip_popup.show_tooltip)
		new_shop_card.gold_cost = _get_updated_shop_cost(new_shop_card.gold_cost)
		new_shop_card.update(run_stats)


func _pick_shop_cards(available_cards: Array[Card]) -> Array[Card]:
	RNG.array_shuffle(available_cards)
	var picked: Array[Card] = []

	var rare_cards := available_cards.filter(func(card: Card): return card.rarity == Card.Rarity.RARE)
	var guaranteed_rare := RNG.array_pick_random(rare_cards) as Card
	if guaranteed_rare:
		picked.append(guaranteed_rare)
		available_cards.erase(guaranteed_rare)

	var mythic_cards := available_cards.filter(func(card: Card): return card.rarity == Card.Rarity.MYTHIC)
	if not mythic_cards.is_empty() and RNG.instance.randf() < MYTHIC_SHOP_CHANCE:
		var mythic_card := RNG.array_pick_random(mythic_cards) as Card
		picked.append(mythic_card)
		available_cards.erase(mythic_card)

	var non_mythic_cards := available_cards.filter(func(card: Card): return card.rarity != Card.Rarity.MYTHIC)
	RNG.array_shuffle(non_mythic_cards)
	while picked.size() < SHOP_CARD_COUNT and not non_mythic_cards.is_empty():
		picked.append(non_mythic_cards.pop_front())

	return picked


func _get_available_shop_cards() -> Array[Card]:
	var result := _dedupe_cards_by_id(char_stats.draftable_cards.duplicate_cards())

	for common_card: Card in COMMON_SHOP_CARDS:
		var duplicate := common_card.duplicate() as Card
		if duplicate:
			result.append(duplicate)

	return _dedupe_cards_by_id(result)


func _dedupe_cards_by_id(source_cards: Array[Card]) -> Array[Card]:
	var result: Array[Card] = []
	var seen_ids := {}
	for card: Card in source_cards:
		if not card or seen_ids.has(card.id):
			continue
		seen_ids[card.id] = true
		result.append(card)
	return result


func _generate_shop_relics() -> void:
	var available_relics: Array = []
	var seen_ids := {}
	for pool_relic in RELIC_REWARD_POOL.relics:
		_append_available_relic(pool_relic, available_relics, seen_ids)

	for configured_relic in shop_relics:
		_append_available_relic(configured_relic, available_relics, seen_ids)

	RNG.array_shuffle(available_relics)
	var shop_relics_array: Array = []
	var relic_count: int = mini(SHOP_RELIC_COUNT, available_relics.size())
	for i: int in range(relic_count):
		shop_relics_array.append(available_relics[i])

	for relic in shop_relics_array:
		var new_shop_relic := SHOP_RELIC.instantiate() as ShopRelic
		relics.add_child(new_shop_relic)
		new_shop_relic.relic = relic
		new_shop_relic.gold_cost = _get_updated_shop_cost(new_shop_relic.gold_cost)
		new_shop_relic.update(run_stats)


func _append_available_relic(relic, available_relics: Array, seen_ids: Dictionary) -> void:
	if not relic or seen_ids.has(relic.id):
		return

	seen_ids[relic.id] = true
	var can_appear: bool = relic.can_appear_as_reward(char_stats)
	var already_had_it: bool = relic_handler and relic_handler.has_relic(relic.id)
	if can_appear and not already_had_it:
		available_relics.append(relic)


func _update_items() -> void:
	for shop_card: ShopCard in cards.get_children():
		shop_card.update(run_stats)

	for shop_relic: ShopRelic in relics.get_children():
		shop_relic.update(run_stats)

	_update_remove_card_service()


func _update_item_costs() -> void:
	for shop_card: ShopCard in cards.get_children():
		shop_card.gold_cost = _get_updated_shop_cost(shop_card.gold_cost)
		shop_card.update(run_stats)

	for shop_relic: ShopRelic in relics.get_children():
		shop_relic.gold_cost = _get_updated_shop_cost(shop_relic.gold_cost)
		shop_relic.update(run_stats)

	_update_remove_card_service()


func _get_updated_shop_cost(original_cost: int) -> int:
	return modifier_handler.get_modified_value(original_cost, Modifier.Type.SHOP_COST)


func _get_remove_card_cost() -> int:
	if not run_stats:
		return RunStats.BASE_CARD_REMOVE_COST
	return _get_updated_shop_cost(run_stats.card_remove_cost)


func _update_remove_card_service() -> void:
	if not remove_card_button or not run_stats or not char_stats:
		return

	var cost := _get_remove_card_cost()
	var can_remove := char_stats.deck and char_stats.deck.cards.size() > 1
	remove_card_button.text = "净化术法 %s 灵石" % cost
	remove_card_button.disabled = (
		remove_service_used
		or active_card_remove != null
		or run_stats.gold < cost
		or not can_remove
	)


func _on_remove_card_button_pressed() -> void:
	if active_card_remove or remove_service_used or not char_stats or not char_stats.deck:
		return

	active_remove_cost = _get_remove_card_cost()
	if run_stats.gold < active_remove_cost or char_stats.deck.cards.size() <= 1:
		_update_remove_card_service()
		return

	active_card_remove = CARD_REMOVE_SCENE.instantiate() as CardRemove
	ui_layer.add_child(active_card_remove)
	active_card_remove.card_pile = char_stats.deck
	active_card_remove.closed.connect(_on_card_remove_closed)
	active_card_remove.card_removed.connect(_on_card_removed)
	_update_remove_card_service()


func _on_card_removed(_card: Card) -> void:
	run_stats.gold -= active_remove_cost
	run_stats.card_remove_cost += RunStats.CARD_REMOVE_COST_INCREMENT
	active_remove_cost = 0
	remove_service_used = true

	if active_card_remove:
		active_card_remove.queue_free()
		active_card_remove = null

	_update_items()


func _on_card_remove_closed() -> void:
	active_card_remove = null
	active_remove_cost = 0
	_update_remove_card_service()


func _on_back_button_pressed() -> void:
	Events.shop_exited.emit()


func _on_shop_card_bought(card: Card, gold_cost: int) -> void:
	char_stats.deck.add_card(card)
	run_stats.gold -= gold_cost
	_update_items()


func _on_shop_relic_bought(relic: Relic, gold_cost: int) -> void:
	relic_handler.add_relic(relic)
	run_stats.gold -= gold_cost

	if relic is CouponsRelic:
		var coupons_relic := relic as CouponsRelic
		coupons_relic.add_shop_modifier(self)
		_update_item_costs()
	else:
		_update_items()


func _on_blink_timer_timeout() -> void:
	shop_keeper_animation.play("blink")
	_blink_timer_setup()
