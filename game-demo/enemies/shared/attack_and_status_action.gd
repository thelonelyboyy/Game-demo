class_name AttackAndStatusAction
extends EnemyAction

@export var damage := 10
@export var status: Status
@export var notice_name := "减益"


func perform_action() -> void:
	if not enemy or not target:
		Events.enemy_action_completed.emit(enemy)
		return

	var target_array: Array[Node] = [target]
	var damage_effect := DamageEffect.new()
	damage_effect.amount = _get_final_damage()
	damage_effect.receiver_modifier_type = Modifier.Type.NO_MODIFIER
	damage_effect.sound = sound
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var start := enemy.global_position
	var end := target.global_position + Vector2.RIGHT * 32
	tween.tween_property(enemy, "global_position", end, 0.4)
	tween.tween_callback(damage_effect.execute.bind(target_array))
	if status:
		tween.tween_callback(_apply_status.bind(target_array))
	tween.tween_interval(0.25)
	tween.tween_property(enemy, "global_position", start, 0.4)
	complete_action_when_tween_finishes(tween)


func update_intent_text() -> void:
	intent.current_text = intent.base_text % _get_final_damage()


func _apply_status(targets: Array[Node]) -> void:
	var effect := StatusEffect.new()
	effect.status = status
	effect.execute(targets)
	if enemy and enemy.stats:
		Events.ui_notice_requested.emit("%s 施加了「%s」" % [enemy.stats.display_name, notice_name])


func _get_final_damage() -> int:
	var final_damage := damage
	if enemy and enemy.modifier_handler:
		final_damage = enemy.modifier_handler.get_modified_value(final_damage, Modifier.Type.DMG_DEALT)
	var player := target as Player
	if player and player.modifier_handler:
		final_damage = player.modifier_handler.get_modified_value(final_damage, Modifier.Type.DMG_TAKEN)
	return final_damage
