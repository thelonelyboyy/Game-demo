class_name CardExhaustDrawRelic
extends Relic

@export var draw_amount := 1
@export var once_per_turn := true

var relic_ui: RelicUI
var triggered_this_turn := false


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.card_exhausted.is_connected(_on_card_exhausted):
		Events.card_exhausted.connect(_on_card_exhausted)
	if not Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.connect(_on_player_turn_started)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.card_exhausted.is_connected(_on_card_exhausted):
		Events.card_exhausted.disconnect(_on_card_exhausted)
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)


func _on_player_turn_started() -> void:
	triggered_this_turn = false


func _on_card_exhausted(_card: Card) -> void:
	if once_per_turn and triggered_this_turn:
		return
	if not relic_ui or not is_instance_valid(relic_ui):
		return

	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if not player:
		return

	var draw_effect := CardDrawEffect.new()
	draw_effect.cards_to_draw = draw_amount
	draw_effect.execute([player])
	triggered_this_turn = true
	relic_ui.flash()
