class_name SelfDamageThresholdRelic
extends Relic

@export var damage_threshold := 4
@export var mana_amount := 1
@export var draw_amount := 0

var relic_ui: RelicUI
var accumulated_damage := 0
var triggered_this_turn := false


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.player_self_damaged.is_connected(_on_player_self_damaged):
		Events.player_self_damaged.connect(_on_player_self_damaged)
	if not Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.connect(_on_player_turn_started)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_self_damaged.is_connected(_on_player_self_damaged):
		Events.player_self_damaged.disconnect(_on_player_self_damaged)
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)


func _on_player_turn_started() -> void:
	accumulated_damage = 0
	triggered_this_turn = false


func _on_player_self_damaged(damage: int) -> void:
	if triggered_this_turn or damage <= 0:
		return
	accumulated_damage += damage
	if accumulated_damage < maxi(damage_threshold, 1):
		return
	_trigger_reward()


func _trigger_reward() -> void:
	if not relic_ui or not is_instance_valid(relic_ui):
		return
	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if not player or not player.stats is CharacterStats:
		return
	triggered_this_turn = true
	(player.stats as CharacterStats).mana += mana_amount
	if draw_amount > 0:
		var draw_effect := CardDrawEffect.new()
		draw_effect.cards_to_draw = draw_amount
		draw_effect.execute([player])
	relic_ui.flash()
