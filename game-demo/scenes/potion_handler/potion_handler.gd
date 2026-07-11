class_name PotionHandler
extends HBoxContainer

signal potion_used(potion: Potion)

const MAX_SLOTS := 3
const POTION_UI := preload("res://scenes/potion_handler/potion_ui.tscn")

## 战斗外使用（地图回血）时把效果落到角色数值上。由 Run 设置。
var character_stats: CharacterStats

## 单体攻击丹药的瞄准状态：非空表示正等待玩家点选目标。
var _aiming_ui: PotionUI = null


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	for child in get_children():
		child.queue_free()
	for i in range(MAX_SLOTS):
		_add_empty_slot()


func count() -> int:
	var occupied := 0
	for ui: PotionUI in get_children():
		if ui.potion:
			occupied += 1
	return occupied


func is_full() -> bool:
	return count() >= MAX_SLOTS


func add_potion(potion: Potion) -> bool:
	if not potion or is_full():
		return false
	for ui: PotionUI in get_children():
		if not ui.potion:
			ui.potion = potion
			return true
	return false


func get_potions() -> Array[Potion]:
	var result: Array[Potion] = []
	for ui: PotionUI in get_children():
		if ui.potion:
			result.append(ui.potion)
	return result


func load_potions(potions: Array) -> void:
	_ensure_slots()
	for ui: PotionUI in get_children():
		ui.clear_potion()
	for potion: Potion in potions:
		add_potion(potion)


func can_use(potion: Potion) -> bool:
	if _player():
		return true
	return potion.usable_out_of_combat


func _player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func _on_use_requested(ui: PotionUI) -> void:
	if not is_instance_valid(ui) or not ui.potion or not can_use(ui.potion):
		return

	# 单体攻击丹药且场上多于一个敌人：进入瞄准模式，点谁打谁；
	# 单敌时保持直接使用，不加多余操作。
	if ui.potion.target_kind == Potion.TargetKind.SINGLE_ENEMY and _alive_enemies().size() > 1:
		_begin_aiming(ui)
		return

	var potion := ui.potion
	_apply(potion)
	ui.clear_potion()
	potion_used.emit(potion)


func _alive_enemies() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and not enemy.is_queued_for_deletion() and enemy.stats and enemy.stats.health > 0:
			result.append(enemy)
	return result


func _begin_aiming(ui: PotionUI) -> void:
	_aiming_ui = ui
	Events.ui_notice_requested.emit("点击敌人以使用「%s」（右键取消）" % ui.potion.potion_name)


func _unhandled_input(event: InputEvent) -> void:
	if not _aiming_ui:
		return

	# 悬停高亮：借用敌人的四角目标框反馈"会打到谁"。
	if event is InputEventMouseMotion:
		var hovered := _enemy_under_mouse()
		for enemy in _alive_enemies():
			if enemy.target_highlight:
				enemy.target_highlight.visible = enemy == hovered
		return

	if event.is_action_pressed("right_mouse"):
		_cancel_aiming()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("left_mouse"):
		var target := _enemy_under_mouse()
		if target:
			_use_on_target(target)
		else:
			_cancel_aiming()
		get_viewport().set_input_as_handled()


# 命中测试用敌人信息卡的画布矩形（世界节点已由 battle_ui 对齐到信息卡中心）。
func _enemy_under_mouse() -> Enemy:
	var mouse := get_viewport().get_mouse_position()
	for enemy in _alive_enemies():
		var center: Vector2 = enemy.get_global_transform_with_canvas().origin
		var extents: Vector2 = enemy.aligned_feedback_extents
		if extents == Vector2.ZERO:
			extents = Vector2(160.0, 160.0)
		if Rect2(center - extents * 0.5, extents).has_point(mouse):
			return enemy
	return null


func _use_on_target(target: Enemy) -> void:
	var ui := _aiming_ui
	_clear_aim_highlights()
	_aiming_ui = null
	if not is_instance_valid(ui) or not ui.potion or not is_instance_valid(target):
		return
	var player := _player()
	if not player:
		return

	var potion := ui.potion
	for effect in potion.configured_effects:
		if effect:
			effect.execute(null, [target], player.modifier_handler)
	ui.clear_potion()
	potion_used.emit(potion)


func _cancel_aiming() -> void:
	_clear_aim_highlights()
	_aiming_ui = null


func _clear_aim_highlights() -> void:
	for enemy in _alive_enemies():
		if enemy.target_highlight:
			enemy.target_highlight.hide()


func _add_empty_slot() -> PotionUI:
	var ui := POTION_UI.instantiate() as PotionUI
	add_child(ui)
	ui.use_requested.connect(_on_use_requested)
	ui.potion = null
	return ui


func _ensure_slots() -> void:
	while get_child_count() < MAX_SLOTS:
		_add_empty_slot()


func _apply(potion: Potion) -> void:
	var player := _player()
	if player:
		var targets := _resolve_targets(potion, player)
		var modifiers: ModifierHandler = player.modifier_handler
		for effect in potion.configured_effects:
			if effect:
				effect.execute(null, targets, modifiers)
	else:
		# 战斗外：只把"回血"类效果落到角色数值上。
		for effect in potion.configured_effects:
			if effect is ConfiguredHealEffect and character_stats:
				character_stats.heal(effect.amount)


func _resolve_targets(potion: Potion, player: Player) -> Array[Node]:
	if potion.target_kind == Potion.TargetKind.SINGLE_ENEMY:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
				return [enemy]
		return []
	# SELF / ALL_ENEMIES：传入玩家作为场景上下文，效果按各自 target_mode 取组。
	return [player]
