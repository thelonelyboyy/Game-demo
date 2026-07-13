class_name UpgradedCardBlockRelic
extends Relic

@export var block_amount := 5

var relic_ui: RelicUI
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
	triggered_this_turn = false


func _on_card_played(card: Card) -> void:
	if triggered_this_turn or not card or not card.upgraded:
		return
	if not relic_ui or not is_instance_valid(relic_ui):
		return
	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if not player:
		return

	var block_effect := BlockEffect.new()
	block_effect.amount = block_amount
	block_effect.execute([player])
	triggered_this_turn = true
	relic_ui.flash()
