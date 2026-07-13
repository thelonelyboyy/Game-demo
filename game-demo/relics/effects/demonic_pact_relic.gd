class_name DemonicPactRelic
extends Relic

enum Requirement {SELF_DAMAGE, FLAME_COLORS, SOUL_MARKS_SPENT, EXHAUSTED_CARDS}

@export var requirement := Requirement.SELF_DAMAGE
@export var requirement_amount := 3
@export var mana_amount := 1
@export var failure_status: Status

var relic_ui: RelicUI
var progress_this_turn := 0


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	_connect_signal(Events.player_turn_started, _on_player_turn_started)
	_connect_signal(Events.player_turn_ended, _on_player_turn_ended)
	_connect_signal(Events.player_self_damaged, _on_player_self_damaged)
	_connect_signal(Events.flame_wheel_changed, _on_flame_wheel_changed)
	_connect_signal(Events.soul_mark_spent, _on_soul_mark_spent)
	_connect_signal(Events.card_exhausted, _on_card_exhausted)


func deactivate_relic(_owner: RelicUI) -> void:
	_disconnect_signal(Events.player_turn_started, _on_player_turn_started)
	_disconnect_signal(Events.player_turn_ended, _on_player_turn_ended)
	_disconnect_signal(Events.player_self_damaged, _on_player_self_damaged)
	_disconnect_signal(Events.flame_wheel_changed, _on_flame_wheel_changed)
	_disconnect_signal(Events.soul_mark_spent, _on_soul_mark_spent)
	_disconnect_signal(Events.card_exhausted, _on_card_exhausted)


func _on_player_turn_started() -> void:
	progress_this_turn = 0
	var player := _get_player()
	if not player or not player.stats is CharacterStats:
		return
	(player.stats as CharacterStats).mana += mana_amount
	if relic_ui and is_instance_valid(relic_ui):
		relic_ui.flash()


func _on_player_turn_ended() -> void:
	if progress_this_turn >= maxi(requirement_amount, 1) or not failure_status:
		return
	var player := _get_player()
	if not player:
		return
	var status_copy := failure_status.duplicate() as Status
	status_copy.duration = 1
	var status_effect := StatusEffect.new()
	status_effect.status = status_copy
	status_effect.execute([player])
	if relic_ui and is_instance_valid(relic_ui):
		relic_ui.flash()


func _on_player_self_damaged(amount: int) -> void:
	if requirement == Requirement.SELF_DAMAGE:
		progress_this_turn += maxi(amount, 0)


func _on_flame_wheel_changed(colors: Array) -> void:
	if requirement == Requirement.FLAME_COLORS:
		progress_this_turn = maxi(progress_this_turn, colors.size())


func _on_soul_mark_spent(consumed: int, _detonated: bool) -> void:
	if requirement == Requirement.SOUL_MARKS_SPENT:
		progress_this_turn += maxi(consumed, 0)


func _on_card_exhausted(_card: Card) -> void:
	if requirement == Requirement.EXHAUSTED_CARDS:
		progress_this_turn += 1


func _get_player() -> Player:
	if not relic_ui or not is_instance_valid(relic_ui):
		return null
	return relic_ui.get_tree().get_first_node_in_group("player") as Player


func _connect_signal(which_signal: Signal, callable: Callable) -> void:
	if not which_signal.is_connected(callable):
		which_signal.connect(callable)


func _disconnect_signal(which_signal: Signal, callable: Callable) -> void:
	if which_signal.is_connected(callable):
		which_signal.disconnect(callable)
