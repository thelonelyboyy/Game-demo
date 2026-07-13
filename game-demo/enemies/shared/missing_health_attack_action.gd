extends EnemyAction

@export var base_damage := 10
@export var max_bonus_damage := 16


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
	tween.tween_interval(0.25)
	tween.tween_property(enemy, "global_position", start, 0.4)
	complete_action_when_tween_finishes(tween)


func update_intent_text() -> void:
	intent.current_text = intent.base_text % _get_final_damage()


func _get_final_damage() -> int:
	var bonus := 0
	var player := target as Player
	if player and player.stats:
		var missing_health := maxi(player.stats.max_health - player.stats.health, 0)
		bonus = floori(float(missing_health) / float(maxi(player.stats.max_health, 1)) * max_bonus_damage)
	var final_damage := base_damage + bonus
	if enemy and enemy.modifier_handler:
		final_damage = enemy.modifier_handler.get_modified_value(final_damage, Modifier.Type.DMG_DEALT)
	if player and player.modifier_handler:
		final_damage = player.modifier_handler.get_modified_value(final_damage, Modifier.Type.DMG_TAKEN)
	return maxi(final_damage, 0)
