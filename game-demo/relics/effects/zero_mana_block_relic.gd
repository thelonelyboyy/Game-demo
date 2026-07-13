class_name ZeroManaBlockRelic
extends Relic

@export var block_amount := 5


func activate_relic(owner: RelicUI) -> void:
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if not player or not player.stats is CharacterStats:
		return
	if (player.stats as CharacterStats).mana > 0:
		return

	var block_effect := BlockEffect.new()
	block_effect.amount = block_amount
	var targets: Array[Node] = [player]
	block_effect.execute(targets)
	owner.flash()
