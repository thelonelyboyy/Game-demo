class_name DiscoveryAssistRelic
extends Relic

@export var extra_picks := 0
@export var bonus_upgrades := 0
@export var once_per_turn := true

var relic_ui: RelicUI
var triggered_this_turn := false


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.card_discovery_prepared.is_connected(_on_discovery_prepared):
		Events.card_discovery_prepared.connect(_on_discovery_prepared)
	if not Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.connect(_on_player_turn_started)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.card_discovery_prepared.is_connected(_on_discovery_prepared):
		Events.card_discovery_prepared.disconnect(_on_discovery_prepared)
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)


func _on_player_turn_started() -> void:
	triggered_this_turn = false


func _on_discovery_prepared(request: CardDiscoveryRequest) -> void:
	if not request or request.choices.is_empty():
		return
	if once_per_turn and triggered_this_turn:
		return
	var changed := false
	if extra_picks > 0:
		var previous_picks := request.picks
		request.picks = clampi(request.picks + extra_picks, 1, request.choices.size())
		changed = request.picks != previous_picks
	if bonus_upgrades > 0:
		request.bonus_upgrade_count += bonus_upgrades
		changed = true
	if not changed:
		return
	triggered_this_turn = true
	if relic_ui and is_instance_valid(relic_ui):
		relic_ui.flash()
