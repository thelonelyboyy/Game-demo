class_name TimingManaRelic
extends Relic

@export var mana_amount := 1


func activate_relic(owner: RelicUI) -> void:
	Events.player_hand_drawn.connect(_add_mana.bind(owner), CONNECT_ONE_SHOT)


func _add_mana(owner: RelicUI) -> void:
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if not player:
		return

	player.stats.mana += mana_amount
	owner.flash()
