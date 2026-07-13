extends EnemyAction

@export var damage := 8
@export var block := 8


func perform_action() -> void:
	if not enemy or not target:
		return

	var block_effect := BlockEffect.new()
	block_effect.amount = block
	var block_targets: Array[Node] = [enemy]
	block_effect.execute(block_targets)

	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var start := enemy.global_position
	var end := target.global_position + Vector2.RIGHT * 32
	var damage_effect := DamageEffect.new()
	damage_effect.amount = _get_final_damage()
	damage_effect.receiver_modifier_type = Modifier.Type.NO_MODIFIER
	damage_effect.sound = sound
	var targets: Array[Node] = [target]
	tween.tween_property(enemy, "global_position", end, 0.4)
	tween.tween_callback(damage_effect.execute.bind(targets))
	tween.tween_interval(0.25)
	tween.tween_property(enemy, "global_position", start, 0.4)
	complete_action_when_tween_finishes(tween)


func update_intent_text() -> void:
	intent.current_text = intent.base_text % [_get_final_damage(), block]


func _get_final_damage() -> int:
	var final_damage := damage
	if enemy and enemy.modifier_handler:
		final_damage = enemy.modifier_handler.get_modified_value(final_damage, Modifier.Type.DMG_DEALT)
	var player := target as Player
	if player and player.modifier_handler:
		final_damage = player.modifier_handler.get_modified_value(final_damage, Modifier.Type.DMG_TAKEN)
	return maxi(final_damage, 0)
