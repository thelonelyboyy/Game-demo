class_name CardPile
extends Resource

signal card_pile_size_changed(cards_amount)

@export var cards: Array[Card] = []

var owner_stats: CharacterStats


func empty() -> bool:
	return cards.is_empty()


func draw_card() -> Card:
	var card = cards.pop_front()
	card_pile_size_changed.emit(cards.size())
	return card


func add_card(card: Card) -> void:
	if owner_stats and card:
		card.bind_spirit_root_owner(owner_stats)
	cards.append(card)
	card_pile_size_changed.emit(cards.size())


func remove_card(card: Card) -> bool:
	var index := cards.find(card)
	if index == -1:
		return false

	cards.remove_at(index)
	card_pile_size_changed.emit(cards.size())
	return true


func shuffle() -> void:
	RNG.array_shuffle(cards)


func clear() -> void:
	cards.clear()
	card_pile_size_changed.emit(cards.size())


# We need this method because of a Godot issue
# reported here: 
# https://github.com/godotengine/godot/issues/74918
func duplicate_cards() -> Array[Card]:
	var new_array: Array[Card] = []
	
	for card: Card in cards:
		new_array.append(card.duplicate())
	
	return new_array


# We need this method because of a Godot issue
# reported here: 
# https://github.com/godotengine/godot/issues/74918
func custom_duplicate() -> CardPile:
	var new_card_pile := CardPile.new()
	new_card_pile.cards = duplicate_cards()
	
	return new_card_pile


func bind_cards_to_owner(stats: CharacterStats) -> void:
	owner_stats = stats
	for card: Card in cards:
		if card:
			card.bind_spirit_root_owner(stats)


func reset_temporary_card_costs() -> void:
	for card: Card in cards:
		if card:
			card.reset_temporary_cost()


func _to_string() -> String:
	var _card_strings: PackedStringArray = []
	for i in range(cards.size()):
		_card_strings.append("%s: %s" % [i+1, cards[i].id])
	return "\n".join(_card_strings)
