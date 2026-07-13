class_name CardLifecycleBlockRelic
extends Relic

enum Trigger {DISCARDED_FROM_HAND, EXHAUSTED}

@export var trigger := Trigger.DISCARDED_FROM_HAND
@export var block_amount := 4
@export var once_per_turn := true

var relic_ui: RelicUI
var triggered_this_turn := false


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	_connect_lifecycle_signal()
	if not Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.connect(_on_player_turn_started)


func deactivate_relic(_owner: RelicUI) -> void:
	_disconnect_lifecycle_signal()
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)


func _connect_lifecycle_signal() -> void:
	var lifecycle_signal := _get_lifecycle_signal()
	if not lifecycle_signal.is_connected(_on_card_lifecycle):
		lifecycle_signal.connect(_on_card_lifecycle)


func _disconnect_lifecycle_signal() -> void:
	var lifecycle_signal := _get_lifecycle_signal()
	if lifecycle_signal.is_connected(_on_card_lifecycle):
		lifecycle_signal.disconnect(_on_card_lifecycle)


func _get_lifecycle_signal() -> Signal:
	if trigger == Trigger.EXHAUSTED:
		return Events.card_exhausted
	return Events.card_discarded_from_hand


func _on_player_turn_started() -> void:
	triggered_this_turn = false


func _on_card_lifecycle(_card: Card) -> void:
	if once_per_turn and triggered_this_turn:
		return
	if not relic_ui or not is_instance_valid(relic_ui):
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
