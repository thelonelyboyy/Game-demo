class_name AfflictionDrawRelic
extends Relic

@export var draw_amount := 1
@export var once_per_turn := true

var relic_ui: RelicUI
var triggered_this_turn := false


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.card_drawn.is_connected(_on_card_drawn):
		Events.card_drawn.connect(_on_card_drawn)
	if not Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.connect(_on_player_turn_started)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.card_drawn.is_connected(_on_card_drawn):
		Events.card_drawn.disconnect(_on_card_drawn)
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)


func _on_player_turn_started() -> void:
	triggered_this_turn = false


func _on_card_drawn(card: Card) -> void:
	if not card or (not card.is_status_card() and not card.is_curse_card()):
		return
	if once_per_turn and triggered_this_turn:
		return
	if not relic_ui or not is_instance_valid(relic_ui):
		return
	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if not player:
		return

	# Set the guard before drawing so a chained affliction cannot recurse.
	triggered_this_turn = true
	var draw_effect := CardDrawEffect.new()
	draw_effect.cards_to_draw = draw_amount
	draw_effect.execute([player])
	relic_ui.flash()
