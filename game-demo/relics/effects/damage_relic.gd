class_name TimingDamageRelic
extends Relic

enum TargetMode {ALL_ENEMIES, RANDOM_ENEMY}

@export var damage_amount := 3
@export var target_mode := TargetMode.ALL_ENEMIES


func activate_relic(owner: RelicUI) -> void:
	var targets := _get_targets(owner)
	if targets.is_empty():
		return

	var damage_effect := DamageEffect.new()
	damage_effect.amount = damage_amount
	damage_effect.execute(targets)
	owner.flash()


func _get_targets(owner: RelicUI) -> Array[Node]:
	var enemies: Array[Node] = owner.get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return []
	if target_mode == TargetMode.RANDOM_ENEMY:
		var random_targets: Array[Node] = []
		var enemy := RNG.array_pick_random(enemies) as Node
		if enemy:
			random_targets.append(enemy)
		return random_targets
	return enemies
