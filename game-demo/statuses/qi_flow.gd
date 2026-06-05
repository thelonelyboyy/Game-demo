class_name QiFlowStatus
extends Status

const MUSCLE_STATUS = preload("res://statuses/muscle.tres")


func get_tooltip() -> String:
	return tooltip % stacks


func apply_status(target: Node) -> void:
	var status_effect := StatusEffect.new()
	var muscle := MUSCLE_STATUS.duplicate() as Status
	muscle.stacks = stacks
	status_effect.status = muscle
	status_effect.execute([target])
	status_applied.emit(self)
