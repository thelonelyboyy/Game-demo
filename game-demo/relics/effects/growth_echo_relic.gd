class_name GrowthEchoRelic
extends Relic

@export var extra_growth_triggers := 1
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
	var growth_card := card as CultivationCard
	if not growth_card or not growth_card.is_growth_card():
		return
	var growth_before := growth_card.growth_accumulated
	for _index in maxi(extra_growth_triggers, 0):
		growth_card.handle_lifecycle_trigger(Card.LifecycleTrigger.PLAYED, [], null)
	if growth_card.growth_accumulated <= growth_before:
		return
	triggered_this_turn = true
	if relic_ui and is_instance_valid(relic_ui):
		relic_ui.flash()
