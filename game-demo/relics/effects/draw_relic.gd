class_name TimingDrawRelic
extends Relic

@export var draw_amount := 1


func activate_relic(owner: RelicUI) -> void:
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if not player:
		return

	var draw_effect := CardDrawEffect.new()
	draw_effect.cards_to_draw = draw_amount
	draw_effect.execute([player])
	owner.flash()
