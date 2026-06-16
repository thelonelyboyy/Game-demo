extends EnemyAction

const TOXIN = preload("res://common_cards/toxin.tres")

@export var damage := 8


func perform_action() -> void:
	if not enemy or not target:
		return
	
	var player := target as Player
	if not player:
		return
	
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var start := enemy.global_position
	var end := target.global_position + Vector2.RIGHT * 32
	var damage_effect := DamageEffect.new()
	var target_array: Array[Node] = [target]
	var modified_dmg := enemy.modifier_handler.get_modified_value(damage, Modifier.Type.DMG_DEALT)
	
	damage_effect.amount = modified_dmg
	damage_effect.sound = sound
	
	tween.tween_property(enemy, "global_position", end, 0.4)
	tween.tween_callback(damage_effect.execute.bind(target_array))
	tween.tween_callback(_add_toxin_to_draw_pile.bind(player))
	tween.tween_interval(0.25)
	tween.tween_property(enemy, "global_position", start, 0.4)
	
	# 捕获 instance_id 而非节点：补间未完成前敌人/战斗可能被释放，捕获节点会触发「Lambda capture freed」
	var enemy_id := enemy.get_instance_id()
	tween.finished.connect(
		func():
			var acting_enemy := instance_from_id(enemy_id) as Enemy
			if is_instance_valid(acting_enemy):
				Events.enemy_action_completed.emit(acting_enemy)
	)


func update_intent_text() -> void:
	var player := target as Player
	if not player:
		return
	
	var modified_dmg := player.modifier_handler.get_modified_value(damage, Modifier.Type.DMG_TAKEN)
	var final_dmg := enemy.modifier_handler.get_modified_value(modified_dmg, Modifier.Type.DMG_DEALT)
	intent.current_text = intent.base_text % final_dmg


func _add_toxin_to_draw_pile(player: Player) -> void:
	if not player or not player.stats or not player.stats.draw_pile:
		return

	player.stats.draw_pile.add_card(TOXIN.duplicate())

