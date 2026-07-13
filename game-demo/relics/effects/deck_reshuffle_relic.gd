class_name DeckReshuffleRelic
extends Relic

@export var block_amount := 6
@export var mana_amount := 1
@export var once_per_turn := true

var relic_ui: RelicUI
var triggered_this_turn := false


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.deck_reshuffled.is_connected(_on_deck_reshuffled):
		Events.deck_reshuffled.connect(_on_deck_reshuffled)
	if not Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.connect(_on_player_turn_started)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.deck_reshuffled.is_connected(_on_deck_reshuffled):
		Events.deck_reshuffled.disconnect(_on_deck_reshuffled)
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)


func _on_player_turn_started() -> void:
	triggered_this_turn = false


func _on_deck_reshuffled(card_count: int) -> void:
	if card_count <= 0 or (once_per_turn and triggered_this_turn):
		return
	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if not player or not player.stats is CharacterStats:
		return
	var character := player.stats as CharacterStats
	character.mana += mana_amount
	if block_amount > 0:
		var block_effect := BlockEffect.new()
		block_effect.amount = block_amount
		var targets: Array[Node] = [player]
		block_effect.execute(targets)
	triggered_this_turn = true
	relic_ui.flash()
