class_name SwordGuardStatus
extends Status

const BLOCK_PER_STACK := 2


func get_tooltip() -> String:
	return tooltip % stacks


func apply_status(target: Node) -> void:
	var block_effect := BlockEffect.new()
	block_effect.amount = stacks * BLOCK_PER_STACK
	block_effect.execute([target])
	status_applied.emit(self)
