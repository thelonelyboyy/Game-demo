class_name EndTurnHandBlockRelic
extends Relic

enum CardFilter {RETAINED, AFFLICTION}

@export var card_filter := CardFilter.RETAINED
@export var block_per_card := 3
@export var maximum_cards_counted := 3


func activate_relic(owner: RelicUI) -> void:
	var tree := owner.get_tree()
	var player := tree.get_first_node_in_group("player") as Player
	var player_handler := tree.get_first_node_in_group("player_handler") as PlayerHandler
	if not player or not player_handler or not player_handler.hand:
		return

	var matching_cards := 0
	for child: Node in player_handler.hand.get_children():
		var card_ui := child as CardUI
		if card_ui and _matches(card_ui.card):
			matching_cards += 1
	var counted_cards := mini(matching_cards, maxi(maximum_cards_counted, 0))
	if counted_cards <= 0:
		return

	var block_effect := BlockEffect.new()
	block_effect.amount = counted_cards * block_per_card
	var targets: Array[Node] = [player]
	block_effect.execute(targets)
	owner.flash()


func _matches(card: Card) -> bool:
	if not card:
		return false
	if card_filter == CardFilter.AFFLICTION:
		return card.is_status_card() or card.is_curse_card()
	return card.is_retained_card()
