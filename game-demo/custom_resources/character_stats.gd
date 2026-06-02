class_name CharacterStats
extends Stats

@export_group("Visuals")
@export var character_name: String
@export_multiline var description: String
@export var portrait: Texture

@export_group("Gameplay Data")
@export var starting_deck: CardPile
@export var draftable_cards: CardPile
@export var cards_per_turn: int
@export var max_mana: int
@export var starting_relic: Relic
@export var spirit_root: Card.Element = Card.Element.NONE

var mana: int : set = set_mana
var deck: CardPile
var discard: CardPile
var draw_pile: CardPile


func set_mana(value: int) -> void:
	mana = value
	stats_changed.emit()


func reset_mana() -> void:
	mana = max_mana


func take_damage(damage: int) -> void:
	var initial_health := health
	super.take_damage(damage)
	if initial_health > health:
		Events.player_hit.emit()


func can_play_card(card: Card) -> bool:
	return mana >= card.cost


func create_instance(selected_spirit_root: Card.Element = Card.Element.NONE) -> Resource:
	var instance: CharacterStats = self.duplicate()
	instance.health = max_health
	instance.block = 0
	instance.reset_mana()
	instance.deck = instance.starting_deck.custom_duplicate()
	instance.spirit_root = selected_spirit_root
	instance.deck.bind_cards_to_owner(instance)
	instance.convert_random_starter_to_spirit_root()
	instance.draw_pile = CardPile.new()
	instance.draw_pile.bind_cards_to_owner(instance)
	instance.discard = CardPile.new()
	instance.discard.bind_cards_to_owner(instance)
	return instance


func has_spirit_root() -> bool:
	return spirit_root != Card.Element.NONE


func convert_random_starter_to_spirit_root() -> void:
	if not has_spirit_root() or not deck:
		return

	var candidates: Array[Card] = []
	for card: Card in deck.cards:
		if card and (card.id == "strike" or card.id == "defend"):
			candidates.append(card)

	var picked := RNG.array_pick_random(candidates) as Card
	if picked:
		picked.element = spirit_root


func count_spirit_root_cards() -> int:
	return count_cards_of_element(spirit_root)


func count_cards_of_element(element: Card.Element) -> int:
	if not has_spirit_root() or not deck:
		return 0

	var count := 0
	for card: Card in deck.cards:
		if card and card.element == element:
			count += 1
	return count


func get_spirit_root_stage() -> int:
	var count := count_spirit_root_cards()
	if count >= 10:
		return 3
	if count >= 5:
		return 2
	if count >= 3:
		return 1
	return 0


func get_spirit_root_stage_name() -> String:
	match get_spirit_root_stage():
		1:
			return "小成"
		2:
			return "大成"
		3:
			return "圆满"
		_:
			return "初悟"


func is_spirit_root_complete() -> bool:
	return has_spirit_root() and get_spirit_root_stage() >= 3


func get_spirit_root_modified_value(value: int) -> int:
	if value <= 0:
		return value

	match get_spirit_root_stage():
		1:
			return ceili(value * 1.2) + 2
		2:
			return ceili(value * 1.5) + 2
		3:
			return value * 2 + 2
		_:
			return value + 2


func bind_all_card_piles_to_owner() -> void:
	if deck:
		deck.bind_cards_to_owner(self)
	if draw_pile:
		draw_pile.bind_cards_to_owner(self)
	if discard:
		discard.bind_cards_to_owner(self)


func reset_temporary_card_costs() -> void:
	if deck:
		deck.reset_temporary_card_costs()
	if draw_pile:
		draw_pile.reset_temporary_card_costs()
	if discard:
		discard.reset_temporary_card_costs()
