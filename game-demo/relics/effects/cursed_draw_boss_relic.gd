class_name CursedDrawBossRelic
extends Relic

@export var draw_amount := 1
@export var card_to_add: Card
@export var copies_per_combat := 2

var relic_ui: RelicUI
var _cards_pending := false


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.player_hand_drawn.is_connected(_on_player_hand_drawn):
		Events.player_hand_drawn.connect(_on_player_hand_drawn)


func activate_relic(_owner: RelicUI) -> void:
	_cards_pending = true


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_hand_drawn.is_connected(_on_player_hand_drawn):
		Events.player_hand_drawn.disconnect(_on_player_hand_drawn)
	_cards_pending = false


func _on_player_hand_drawn() -> void:
	var player_handler := _get_player_handler()
	if not player_handler or not player_handler.battle_running or not player_handler.character:
		return

	if _cards_pending:
		_cards_pending = false
		for _copy_index in maxi(copies_per_combat, 0):
			if card_to_add:
				player_handler.character.draw_pile.add_card(card_to_add.duplicate(true) as Card)

	if draw_amount > 0:
		player_handler.draw_cards(draw_amount)
		if relic_ui and is_instance_valid(relic_ui):
			relic_ui.flash()


func _get_player_handler() -> PlayerHandler:
	if not relic_ui or not is_instance_valid(relic_ui):
		return null
	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if not player:
		return null
	var ancestor := player.get_parent()
	while ancestor and not ancestor is Battle:
		ancestor = ancestor.get_parent()
	if not ancestor:
		return null
	return (ancestor as Battle).player_handler
