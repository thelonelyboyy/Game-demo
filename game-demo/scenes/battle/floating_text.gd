class_name FloatingCombatText
extends Label

## 战斗飘字：伤害/格挡/自损数字。
## 世界节点（玩家/敌人是缩放过的 Node2D）通过 get_global_transform_with_canvas
## 换算成画布坐标，飘字挂在 BattleUI（组 "ui_layer"）上，字号不受世界缩放影响。

const FLOAT_DISTANCE := 62.0
const POP_IN_DURATION := 0.38
const HOLD_DURATION := 0.76
const FADE_DURATION := 0.96

const COLOR_DAMAGE := Color("ff5a4a")
const COLOR_BLOCK := Color("6fc3ff")
const COLOR_SELF_DAMAGE := Color("c04a86")
const COLOR_HEAL := Color("7ade8a")


static func spawn_damage(world_node: Node2D, amount: int, canvas_offset := Vector2.ZERO) -> void:
	_spawn(world_node, "-%d" % amount, COLOR_DAMAGE, 38, canvas_offset)


static func spawn_block(world_node: Node2D, amount: int, canvas_offset := Vector2.ZERO) -> void:
	_spawn(world_node, "盾 %d" % amount, COLOR_BLOCK, 30, canvas_offset)


static func spawn_self_damage(world_node: Node2D, amount: int, canvas_offset := Vector2.ZERO) -> void:
	_spawn(world_node, "-%d" % amount, COLOR_SELF_DAMAGE, 32, canvas_offset)


static func spawn_heal(world_node: Node2D, amount: int, canvas_offset := Vector2.ZERO) -> void:
	_spawn(world_node, "+%d" % amount, COLOR_HEAL, 32, canvas_offset)


static func _spawn(world_node: Node2D, text_value: String, color: Color, font_size: int, canvas_offset: Vector2) -> void:
	if not world_node or not world_node.is_inside_tree():
		return

	var ui_layer := world_node.get_tree().get_first_node_in_group("ui_layer")
	if not ui_layer:
		return

	var canvas_pos := world_node.get_global_transform_with_canvas().origin + canvas_offset
	canvas_pos.x += randf_range(-14.0, 14.0)

	var label := FloatingCombatText.new()
	label.text = text_value
	label.z_index = 3000
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.05, 0.92))
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 3)

	var box := Vector2(180.0, 48.0)
	label.size = box
	label.position = canvas_pos - box * 0.5
	label.pivot_offset = box * 0.5
	label.scale = Vector2.ONE * 0.4
	label.modulate = Color(1, 1, 1, 0.0)
	ui_layer.add_child(label)

	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2.ONE, POP_IN_DURATION) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 1.0, POP_IN_DURATION * 0.7)
	tween.set_parallel(false)
	tween.tween_interval(HOLD_DURATION)
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - FLOAT_DISTANCE, FADE_DURATION) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, FADE_DURATION)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)
