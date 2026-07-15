class_name FloatingCombatText
extends Label

## 战斗飘字：伤害/格挡/自损数字。
## 世界节点（玩家/敌人是缩放过的 Node2D）通过 get_global_transform_with_canvas
## 换算成画布坐标，飘字挂在 BattleUI（组 "ui_layer"）上，字号不受世界缩放影响。

const FLOAT_DISTANCE := 72.0
const POP_IN_DURATION := 0.45
const HOLD_DURATION := 1.30
const FADE_DURATION := 1.20
const FEEDBACK_STAGGER := 0.34

const COLOR_DAMAGE := Color("ff5a4a")
const COLOR_BLOCK := Color("6fc3ff")
const COLOR_SELF_DAMAGE := Color("c04a86")
const COLOR_HEAL := Color("7ade8a")

static var _next_feedback_start_msec: Dictionary = {}


static func spawn_damage(world_node: Node2D, amount: int, canvas_offset := Vector2.ZERO) -> float:
	return _spawn(world_node, "-%d" % amount, COLOR_DAMAGE, 52, canvas_offset)


static func spawn_block(world_node: Node2D, amount: int, canvas_offset := Vector2.ZERO) -> float:
	return _spawn(world_node, "护体 -%d" % amount, COLOR_BLOCK, 42, canvas_offset)


static func spawn_self_damage(world_node: Node2D, amount: int, canvas_offset := Vector2.ZERO) -> float:
	return _spawn(world_node, "-%d" % amount, COLOR_SELF_DAMAGE, 44, canvas_offset)


static func spawn_heal(world_node: Node2D, amount: int, canvas_offset := Vector2.ZERO) -> float:
	return _spawn(world_node, "+%d" % amount, COLOR_HEAL, 42, canvas_offset)


static func _spawn(world_node: Node2D, text_value: String, color: Color, font_size: int, canvas_offset: Vector2) -> float:
	if not world_node or not world_node.is_inside_tree():
		return 0.0

	var ui_layer := world_node.get_tree().get_first_node_in_group("ui_layer")
	if not ui_layer:
		return 0.0

	# 同一角色的护体、生命、自损、治疗反馈共用一条短队列。数值结算仍然立即
	# 完成，只有表现按触发先后错开，避免多层飘字同帧叠在一起看不清。
	var instance_id := world_node.get_instance_id()
	var now_msec := Time.get_ticks_msec()
	var reserved_msec := maxi(now_msec, int(_next_feedback_start_msec.get(instance_id, now_msec)))
	var delay := float(reserved_msec - now_msec) / 1000.0
	_next_feedback_start_msec[instance_id] = reserved_msec + int(FEEDBACK_STAGGER * 1000.0)

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
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.05, 0.95))
	label.add_theme_constant_override("outline_size", 9)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 4)

	var box := Vector2(280.0, 80.0)
	label.size = box
	label.position = canvas_pos - box * 0.5
	label.pivot_offset = box * 0.5
	label.scale = Vector2.ONE * 0.35
	label.modulate = Color(1, 1, 1, 0.0)
	label.set_meta("feedback_delay", delay)
	label.set_meta("feedback_text", text_value)
	ui_layer.add_child(label)

	# 弹出时先过冲到 1.25 倍再回落到 1.0，配合放大的字号更抓眼。
	var tween := label.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2.ONE * 1.25, POP_IN_DURATION * 0.55) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 1.0, POP_IN_DURATION * 0.6)
	tween.set_parallel(false)
	tween.tween_property(label, "scale", Vector2.ONE, POP_IN_DURATION * 0.45) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(HOLD_DURATION)
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - FLOAT_DISTANCE, FADE_DURATION) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, FADE_DURATION)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)
	return delay
