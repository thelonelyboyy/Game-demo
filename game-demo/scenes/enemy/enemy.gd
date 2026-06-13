class_name Enemy
extends Area2D

const ARROW_OFFSET := 5
const WHITE_SPRITE_MATERIAL := preload("res://art/shaders/white_sprite_material.tres")
const DEFAULT_ART_MAX_SIZE := 88.0
const ELITE_ART_MAX_SIZE := 116.0
const BOSS_ART_MAX_SIZE := 140.0
const TARGET_HIGHLIGHT_PADDING := Vector2(5.0, 4.0)
const TARGET_CORNER_MIN_LENGTH := 6.0
const TARGET_CORNER_MAX_LENGTH := 13.0
const HEALTH_BAR_HALF_WIDTH := 88.0
const STATUS_ROW_HALF_WIDTH := 20.0
const INTENT_HALF_WIDTH := 34.0

@export var stats: EnemyStats : set = set_enemy_stats

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var arrow: Sprite2D = $Arrow
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var stats_ui: StatsUI = $StatsUI
@onready var intent_ui: IntentUI = $IntentUI
@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler

var enemy_action_picker: EnemyActionPicker
var current_action: EnemyAction : set = set_current_action
var target_highlight: Node2D
var target_highlight_lines: Array[Line2D] = []
var sprite_visible_size := Vector2.ZERO


func _ready() -> void:
	if collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate()
	_setup_target_highlight()
	status_handler.status_owner = self


func set_current_action(value: EnemyAction) -> void:
	current_action = value
	update_intent()


func set_enemy_stats(value: EnemyStats) -> void:
	stats = value.create_instance()
	
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)
		stats.stats_changed.connect(update_action)
	
	update_enemy()


func setup_ai() -> void:
	if enemy_action_picker:
		enemy_action_picker.queue_free()
		
	var new_action_picker := stats.ai.instantiate() as EnemyActionPicker
	add_child(new_action_picker)
	enemy_action_picker = new_action_picker
	enemy_action_picker.enemy = self


func update_stats() -> void:
	stats_ui.update_stats(stats)


func update_action() -> void:
	if not enemy_action_picker:
		return
	
	if not current_action:
		current_action = enemy_action_picker.get_action()
		return
	
	var new_conditional_action := enemy_action_picker.get_first_conditional_action()
	if new_conditional_action and current_action != new_conditional_action:
		current_action = new_conditional_action


func update_enemy() -> void:
	if not stats is Stats: 
		return
	if not is_inside_tree(): 
		await ready
	
	sprite_2d.texture = stats.art
	_fit_sprite_and_overlays()
	setup_ai()
	update_stats()


func update_intent() -> void:
	if current_action:
		current_action.update_intent_text()
		intent_ui.update_intent(current_action.intent)


func _fit_sprite_and_overlays() -> void:
	if not sprite_2d.texture:
		return

	var texture_size := sprite_2d.texture.get_size()
	var max_side := maxf(texture_size.x, texture_size.y)
	if max_side <= 0.0:
		return

	var target_size := _get_target_art_max_size()
	var sprite_scale := target_size / max_side
	sprite_2d.scale = Vector2.ONE * sprite_scale

	var visible_size := texture_size * sprite_scale
	sprite_visible_size = visible_size
	arrow.position = Vector2.RIGHT * (visible_size.x * 0.5 + ARROW_OFFSET)
	refresh_battle_overlays()
	_update_target_highlight(visible_size)

	var rectangle := collision_shape.shape as RectangleShape2D
	if rectangle:
		rectangle.size = Vector2(
			maxf(18.0, visible_size.x * 0.75),
			maxf(18.0, visible_size.y * 0.78)
		)


func _get_target_art_max_size() -> float:
	if not stats:
		return DEFAULT_ART_MAX_SIZE

	match stats.id:
		"bone_dragon", "black_lotus_matriarch", "sky_palace_guardian", "abyssal_sword_soul", "eclipse_tyrant":
			return BOSS_ART_MAX_SIZE
		"bull_demon", "iron_golem", "blood_tiger", "thunder_roc", "shadow_reaper", "jade_wyrm":
			return ELITE_ART_MAX_SIZE
		_:
			return DEFAULT_ART_MAX_SIZE


func refresh_battle_overlays() -> void:
	if sprite_visible_size == Vector2.ZERO:
		return

	var stats_scale := _control_scale(stats_ui)
	var status_scale := _control_scale(status_handler)
	var intent_scale := _control_scale(intent_ui)

	intent_ui.position = Vector2(
		-INTENT_HALF_WIDTH * intent_scale,
		-sprite_visible_size.y * 0.33 - 24.0 * intent_scale
	)
	stats_ui.position = Vector2(
		-HEALTH_BAR_HALF_WIDTH * stats_scale,
		sprite_visible_size.y * 0.5 + 8.0 * stats_scale
	)
	status_handler.position = Vector2(
		-STATUS_ROW_HALF_WIDTH * status_scale,
		stats_ui.position.y + 27.0 * status_scale
	)


func _control_scale(control: Control) -> float:
	if not control:
		return 1.0
	return maxf(control.scale.x, 0.001)


func do_turn() -> void:
	stats.block = 0
	
	if not current_action:
		return
	
	current_action.perform_action()


func take_damage(damage: int, which_modifier: Modifier.Type) -> void:
	if stats.health <= 0:
		return
	
	sprite_2d.material = WHITE_SPRITE_MATERIAL
	var modified_damage := maxi(0, modifier_handler.get_modified_value(damage, which_modifier))
	
	var tween := create_tween()
	tween.tween_callback(Shaker.shake.bind(self, 16, 0.15))
	tween.tween_callback(stats.take_damage.bind(modified_damage))
	tween.tween_interval(0.17)

	tween.finished.connect(
		func():
			sprite_2d.material = null
			
			if stats.health <= 0:
				Events.enemy_died.emit(self)
				queue_free()
	)


func _on_area_entered(_area: Area2D) -> void:
	if target_highlight:
		target_highlight.show()


func _on_area_exited(_area: Area2D) -> void:
	if target_highlight:
		target_highlight.hide()


func _setup_target_highlight() -> void:
	target_highlight = Node2D.new()
	target_highlight.name = "TargetHighlight"
	target_highlight.z_index = 20
	target_highlight.hide()
	add_child(target_highlight)

	for i in range(8):
		var corner_line := Line2D.new()
		corner_line.width = 0.85
		corner_line.default_color = Color(1.0, 0.86, 0.34, 0.50)
		corner_line.antialiased = true
		target_highlight.add_child(corner_line)
		target_highlight_lines.append(corner_line)


func _update_target_highlight(visible_size: Vector2) -> void:
	if not target_highlight or target_highlight_lines.size() < 8:
		return

	var half_size := visible_size * 0.5 + TARGET_HIGHLIGHT_PADDING
	var corner_length := clampf(
		minf(visible_size.x, visible_size.y) * 0.18,
		TARGET_CORNER_MIN_LENGTH,
		TARGET_CORNER_MAX_LENGTH
	)
	var left := -half_size.x
	var right := half_size.x
	var top := -half_size.y
	var bottom := half_size.y

	_set_corner_line(0, Vector2(left, top), Vector2(left + corner_length, top))
	_set_corner_line(1, Vector2(left, top), Vector2(left, top + corner_length))
	_set_corner_line(2, Vector2(right, top), Vector2(right - corner_length, top))
	_set_corner_line(3, Vector2(right, top), Vector2(right, top + corner_length))
	_set_corner_line(4, Vector2(right, bottom), Vector2(right - corner_length, bottom))
	_set_corner_line(5, Vector2(right, bottom), Vector2(right, bottom - corner_length))
	_set_corner_line(6, Vector2(left, bottom), Vector2(left + corner_length, bottom))
	_set_corner_line(7, Vector2(left, bottom), Vector2(left, bottom - corner_length))


func _set_corner_line(index: int, from: Vector2, to: Vector2) -> void:
	target_highlight_lines[index].points = PackedVector2Array([from, to])


func get_target_anchor_global_position() -> Vector2:
	if sprite_2d:
		return sprite_2d.global_position
	return global_position
