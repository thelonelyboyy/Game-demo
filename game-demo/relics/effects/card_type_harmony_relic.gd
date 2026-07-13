class_name CardTypeHarmonyRelic
extends Relic

@export var mana_amount := 1
@export var block_amount := 6

var relic_ui: RelicUI
var types_played := {}
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
	types_played.clear()
	triggered_this_turn = false


func _on_card_played(card: Card) -> void:
	if triggered_this_turn or not card:
		return
	types_played[card.type] = true
	if types_played.size() < Card.Type.size():
		return
	if not relic_ui or not is_instance_valid(relic_ui):
		return
	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if not player or not player.stats is CharacterStats:
		return

	triggered_this_turn = true
	var character := player.stats as CharacterStats
	character.mana += mana_amount
	if block_amount > 0:
		var block_effect := BlockEffect.new()
		block_effect.amount = block_amount
		block_effect.execute([player])
	relic_ui.flash()
