class_name SpiritBeastStatus
extends Status

const DAMAGE_PER_STACK := 2


func get_tooltip() -> String:
	return tooltip % stacks


func apply_status(target: Node) -> void:
	if not target:
		status_applied.emit(self)
		return

	var enemies: Array[Node] = target.get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		status_applied.emit(self)
		return

	var picked_enemy := RNG.array_pick_random(enemies) as Node
	var damage_effect := DamageEffect.new()
	damage_effect.amount = stacks * DAMAGE_PER_STACK
	damage_effect.execute([picked_enemy])
	status_applied.emit(self)
