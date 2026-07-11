extends EnemyAction

@export var block := 26
@export var hp_threshold := 6

var already_used := false


func is_performable() -> bool:
	if not enemy or already_used:
		return false
	
	return enemy.stats.health <= hp_threshold


func perform_action() -> void:
	if not enemy or not target:
		return
	
	var block_effect := BlockEffect.new()
	block_effect.amount = block
	block_effect.sound = sound
	block_effect.execute([enemy])
	already_used = true
	
	complete_action_after_delay(0.6)
