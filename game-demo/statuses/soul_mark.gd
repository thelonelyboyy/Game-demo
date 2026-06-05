class_name SoulMarkStatus
extends Status

const DAMAGE_PER_STACK := 2


func get_tooltip() -> String:
	return tooltip % stacks


func apply_status(target: Node) -> void:
	var damage_effect := DamageEffect.new()
	damage_effect.amount = stacks * DAMAGE_PER_STACK
	damage_effect.execute([target])
	status_applied.emit(self)
