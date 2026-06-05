class_name BlockRelic
extends Relic

@export var block_amount := 5


func activate_relic(owner: RelicUI) -> void:
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if not player:
		return

	var block_effect := BlockEffect.new()
	block_effect.amount = block_amount
	block_effect.execute([player])
	owner.flash()
