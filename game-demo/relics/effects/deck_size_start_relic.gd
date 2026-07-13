class_name DeckSizeStartRelic
extends Relic

@export var minimum_deck_size := 0
@export var maximum_deck_size := 0
@export var block_amount := 0
@export var status: Status
@export var status_stacks := 0


func activate_relic(owner: RelicUI) -> void:
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if not player or not player.stats is CharacterStats:
		return
	var character := player.stats as CharacterStats
	if not character.deck:
		return
	var deck_size := character.deck.cards.size()
	if minimum_deck_size > 0 and deck_size < minimum_deck_size:
		return
	if maximum_deck_size > 0 and deck_size > maximum_deck_size:
		return

	var activated := false
	if block_amount > 0:
		var block_effect := BlockEffect.new()
		block_effect.amount = block_amount
		block_effect.execute([player])
		activated = true
	if status and status_stacks > 0:
		var status_copy := status.duplicate() as Status
		status_copy.stacks = status_stacks
		var status_effect := StatusEffect.new()
		status_effect.status = status_copy
		status_effect.execute([player])
		activated = true
	if activated:
		owner.flash()
