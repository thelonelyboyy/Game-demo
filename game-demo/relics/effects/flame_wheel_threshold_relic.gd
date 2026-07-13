class_name FlameWheelThresholdRelic
extends Relic

@export var color_threshold := 3
@export var mana_amount := 1
@export var draw_amount := 0

var relic_ui: RelicUI
var triggered_this_turn := false


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.flame_wheel_changed.is_connected(_on_flame_wheel_changed):
		Events.flame_wheel_changed.connect(_on_flame_wheel_changed)
	if not Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.connect(_on_player_turn_started)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.flame_wheel_changed.is_connected(_on_flame_wheel_changed):
		Events.flame_wheel_changed.disconnect(_on_flame_wheel_changed)
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)


func _on_player_turn_started() -> void:
	triggered_this_turn = false


func _on_flame_wheel_changed(colors: Array) -> void:
	if triggered_this_turn or colors.size() < maxi(color_threshold, 1):
		return
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
