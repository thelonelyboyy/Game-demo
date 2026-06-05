class_name XuanguTalismanRelic
extends Relic

const BLOCK_AMOUNT := 6

var relic_ui: RelicUI
var triggered_this_combat := false


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.player_hit.is_connected(_on_player_hit):
		Events.player_hit.connect(_on_player_hit)


func activate_relic(_owner: RelicUI) -> void:
	triggered_this_combat = false


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_hit.is_connected(_on_player_hit):
		Events.player_hit.disconnect(_on_player_hit)


func _on_player_hit() -> void:
	if triggered_this_combat:
		return

	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if not player:
		return

	var block_effect := BlockEffect.new()
	block_effect.amount = BLOCK_AMOUNT
	block_effect.execute([player])
	triggered_this_combat = true
	relic_ui.flash()
