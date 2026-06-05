class_name BeastBellRelic
extends Relic

const SPIRIT_BEAST_STATUS = preload("res://statuses/spirit_beast.tres")


func activate_relic(owner: RelicUI) -> void:
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if not player:
		return

	var beast := SPIRIT_BEAST_STATUS.duplicate() as Status
	beast.stacks = 1
	player.status_handler.add_status(beast)
	owner.flash()
