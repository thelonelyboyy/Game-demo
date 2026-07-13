class_name EnemyEmpowerManaBossRelic
extends Relic

@export var mana_amount := 1
@export var enemy_status: Status
@export var enemy_stacks := 2

var relic_ui: RelicUI


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.connect(_on_player_turn_started)


func activate_relic(owner: RelicUI) -> void:
	if not enemy_status or enemy_stacks <= 0:
		return
	var targets: Array[Node] = []
	for node: Node in owner.get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and not enemy.is_queued_for_deletion():
			targets.append(enemy)
	if targets.is_empty():
		return

	var status_copy := enemy_status.duplicate() as Status
	status_copy.stacks = enemy_stacks
	var status_effect := StatusEffect.new()
	status_effect.status = status_copy
	status_effect.execute(targets)
	owner.flash()


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)


func _on_player_turn_started() -> void:
	var player := _get_player()
	if not player or not player.stats is CharacterStats:
		return
	(player.stats as CharacterStats).mana += mana_amount
	if relic_ui and is_instance_valid(relic_ui):
		relic_ui.flash()


func _get_player() -> Player:
	if not relic_ui or not is_instance_valid(relic_ui):
		return null
	return relic_ui.get_tree().get_first_node_in_group("player") as Player
