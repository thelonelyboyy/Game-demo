class_name HealRelic
extends Relic

@export var heal_amount := 3


func activate_relic(owner: RelicUI) -> void:
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if not player:
		return

	player.stats.heal(heal_amount)
	owner.flash()
