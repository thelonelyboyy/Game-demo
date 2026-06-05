class_name TimingStatusRelic
extends Relic

enum TargetMode {PLAYER, ALL_ENEMIES, RANDOM_ENEMY}

@export var status: Status
@export var stacks := 1
@export var target_mode := TargetMode.PLAYER


func activate_relic(owner: RelicUI) -> void:
	if not status:
		return

	var targets := _get_targets(owner)
	if targets.is_empty():
		return

	var status_copy := status.duplicate() as Status
	status_copy.stacks = stacks
	var status_effect := StatusEffect.new()
	status_effect.status = status_copy
	status_effect.execute(targets)
	owner.flash()


func _get_targets(owner: RelicUI) -> Array[Node]:
	match target_mode:
		TargetMode.PLAYER:
			var player_targets: Array[Node] = []
			var player := owner.get_tree().get_first_node_in_group("player") as Player
			if player:
				player_targets.append(player)
			return player_targets
		TargetMode.RANDOM_ENEMY:
			var enemies: Array[Node] = owner.get_tree().get_nodes_in_group("enemies")
			var enemy_targets: Array[Node] = []
			var enemy := RNG.array_pick_random(enemies) as Node
			if enemy:
				enemy_targets.append(enemy)
			return enemy_targets
		_:
			return owner.get_tree().get_nodes_in_group("enemies")
