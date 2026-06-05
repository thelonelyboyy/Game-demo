class_name PlayerHitBlockRelic
extends Relic

@export var block_amount := 4
@export var once_per_turn := true

var relic_ui: RelicUI
var triggered_this_turn := false


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.player_hit.is_connected(_on_player_hit):
		Events.player_hit.connect(_on_player_hit)
	if not Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.connect(_on_player_turn_started)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_hit.is_connected(_on_player_hit):
		Events.player_hit.disconnect(_on_player_hit)
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)


func _on_player_turn_started() -> void:
	triggered_this_turn = false


func _on_player_hit() -> void:
	if once_per_turn and triggered_this_turn:
		return

	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if not player:
		return

	var block_effect := BlockEffect.new()
	block_effect.amount = block_amount
	block_effect.execute([player])
	triggered_this_turn = true
	relic_ui.flash()
