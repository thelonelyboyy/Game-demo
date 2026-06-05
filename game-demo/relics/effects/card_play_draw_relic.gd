class_name CardPlayDrawRelic
extends Relic

@export var match_tags := PackedStringArray()
@export var match_element := Card.Element.NONE
@export var draw_amount := 1
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
	if once_per_turn and triggered_this_turn:
		return
	if not _matches_card(card):
		return

	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if not player:
		return

	var draw_effect := CardDrawEffect.new()
	draw_effect.cards_to_draw = draw_amount
	draw_effect.execute([player])
	triggered_this_turn = true
	relic_ui.flash()


func _matches_card(card: Card) -> bool:
	if not card:
		return false
	if match_element != Card.Element.NONE and card.element == match_element:
		return true
	for tag: String in match_tags:
		if card.mechanic_tags.has(tag):
			return true
	return match_element == Card.Element.NONE and match_tags.is_empty()
