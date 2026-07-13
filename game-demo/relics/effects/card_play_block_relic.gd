class_name CardPlayBlockRelic
extends Relic

@export_range(0, 2) var match_type := Card.Type.ATTACK
@export var block_amount := 4
@export var once_per_turn := true

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
	if not card or card.type != match_type:
		return
	if once_per_turn and triggered_this_turn:
		return
	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if not player:
		return
	var block_effect := BlockEffect.new()
	block_effect.amount = block_amount
	var targets: Array[Node] = [player]
	block_effect.execute(targets)
	triggered_this_turn = true
	relic_ui.flash()
