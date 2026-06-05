class_name QingfengSwordBoxRelic
extends Relic

const FORGE_SWORD_STATUS = preload("res://statuses/forge_sword.tres")

var relic_ui: RelicUI
var extra_draws_this_turn := 0
var triggered_this_combat := false


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.connect(_on_player_turn_started)
	if not Events.card_extra_drawn.is_connected(_on_card_extra_drawn):
		Events.card_extra_drawn.connect(_on_card_extra_drawn)


func activate_relic(_owner: RelicUI) -> void:
	extra_draws_this_turn = 0
	triggered_this_combat = false


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)
	if Events.card_extra_drawn.is_connected(_on_card_extra_drawn):
		Events.card_extra_drawn.disconnect(_on_card_extra_drawn)


func _on_player_turn_started() -> void:
	extra_draws_this_turn = 0


func _on_card_extra_drawn(_card: Card) -> void:
	if triggered_this_combat:
		return

	extra_draws_this_turn += 1
	if extra_draws_this_turn < 3:
		return

	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if not player:
		return

	var forge := FORGE_SWORD_STATUS.duplicate() as Status
	forge.stacks = 1
	player.status_handler.add_status(forge)
	triggered_this_combat = true
	relic_ui.flash()
