class_name ZeroCostThresholdRelic
extends Relic

@export var card_threshold := 3
@export var draw_amount := 1

var relic_ui: RelicUI
var zero_cost_cards_played := 0
var triggered_this_turn := false


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.card_played.is_connected(_on_card_played):
		Events.card_played.connect(_on_card_played)
	if not Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.connect(_on_player_turn_started)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.card_played.is_connected(_on_card_played):
		Events.card_played.disconnect(_on_card_played)
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)


func _on_player_turn_started() -> void:
	zero_cost_cards_played = 0
	triggered_this_turn = false


func _on_card_played(card: Card) -> void:
	if triggered_this_turn or not card or card.cost != 0:
		return
	zero_cost_cards_played += 1
	if zero_cost_cards_played < maxi(card_threshold, 1):
		return
	if not relic_ui or not is_instance_valid(relic_ui):
		return
	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if not player:
		return

	triggered_this_turn = true
	var draw_effect := CardDrawEffect.new()
	draw_effect.cards_to_draw = draw_amount
	draw_effect.execute([player])
	relic_ui.flash()
