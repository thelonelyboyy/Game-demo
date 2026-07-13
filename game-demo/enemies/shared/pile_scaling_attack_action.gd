extends EnemyAction

@export var base_damage := 8
@export var damage_per_discard := 2
@export var max_bonus_damage := 16


func perform_action() -> void:
	if not enemy or not target:
		return
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
	intent.current_text = intent.base_text % _get_final_damage()


func _get_final_damage() -> int:
	var discard_count := 0
	var player := target as Player
	if player and player.stats is CharacterStats:
		var character := player.stats as CharacterStats
		discard_count = character.discard.cards.size() if character.discard else 0
	var bonus := mini(discard_count * damage_per_discard, max_bonus_damage)
	var damage := base_damage + bonus
	if enemy and enemy.modifier_handler:
		damage = enemy.modifier_handler.get_modified_value(damage, Modifier.Type.DMG_DEALT)
	if player and player.modifier_handler:
		damage = player.modifier_handler.get_modified_value(damage, Modifier.Type.DMG_TAKEN)
	return maxi(damage, 0)
