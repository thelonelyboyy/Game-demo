class_name EnergyChargeStatus
extends Status


func get_tooltip() -> String:
	return tooltip % stacks


func apply_status(target: Node) -> void:
	if target is Player:
		var char_stats: CharacterStats = target.stats
		char_stats.mana += stacks
	status_applied.emit(self)
