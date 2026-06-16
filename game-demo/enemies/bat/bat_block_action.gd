extends EnemyAction

@export var block := 4


func perform_action() -> void:
	if not enemy or not target:
		return
	
	var block_effect := BlockEffect.new()
	block_effect.amount = block
	block_effect.sound = sound
	block_effect.execute([enemy])
	
	# 捕获 instance_id 而非节点本身：若敌人在延迟期间被释放，定时器仍会触发，
	# 捕获节点会导致「Lambda capture freed」错误；改为 id + 有效性校验。
	var enemy_id := enemy.get_instance_id()
	get_tree().create_timer(0.6, false).timeout.connect(
		func():
			var acting_enemy := instance_from_id(enemy_id) as Enemy
			if is_instance_valid(acting_enemy):
				Events.enemy_action_completed.emit(acting_enemy)
	)

