class_name EnergyChargeStatus
extends Status


func get_tooltip() -> String:
	return tooltip % stacks


const MAX_MANA_PER_TURN := 2


func apply_status(target: Node) -> void:
	if target is Player:
		var char_stats: CharacterStats = target.stats
		char_stats.mana += mini(stacks, MAX_MANA_PER_TURN)
	status_applied.emit(self)
