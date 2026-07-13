extends EnemyAction

@export var damage := 14
@export var healing := 10


func perform_action() -> void:
	if not enemy or not target:
		return

	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var start := enemy.global_position
	var end := target.global_position + Vector2.RIGHT * 32
	var damage_effect := DamageEffect.new()
	damage_effect.amount = _get_final_damage()
	damage_effect.sound = sound
	var targets: Array[Node] = [target]
	tween.tween_property(enemy, "global_position", end, 0.4)
	tween.tween_callback(damage_effect.execute.bind(targets))
	tween.tween_callback(_heal_enemy)
	tween.tween_interval(0.25)
	tween.tween_property(enemy, "global_position", start, 0.4)
	complete_action_when_tween_finishes(tween)


func update_intent_text() -> void:
	intent.current_text = intent.base_text % [_get_final_damage(), healing]


func _heal_enemy() -> void:
	if is_instance_valid(enemy) and enemy.stats and enemy.stats.health > 0:
		enemy.stats.heal(healing)


func _get_final_damage() -> int:
	var final_damage := damage
	if enemy and enemy.modifier_handler:
		final_damage = enemy.modifier_handler.get_modified_value(final_damage, Modifier.Type.DMG_DEALT)
	var player := target as Player
	if player and player.modifier_handler:
		final_damage = player.modifier_handler.get_modified_value(final_damage, Modifier.Type.DMG_TAKEN)
	return maxi(final_damage, 0)
