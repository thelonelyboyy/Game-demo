class_name Enemy
extends Area2D

const ARROW_OFFSET := 5
const WHITE_SPRITE_MATERIAL := preload("res://art/white_sprite_material.tres")
const DEFAULT_ART_MAX_SIZE := 44.0
const ELITE_ART_MAX_SIZE := 58.0
const BOSS_ART_MAX_SIZE := 70.0

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


func _ready() -> void:
	if collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate()
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
	arrow.position = Vector2.RIGHT * (visible_size.x * 0.5 + ARROW_OFFSET)
	intent_ui.position = Vector2(-20.0, -visible_size.y * 0.5 - 18.0)
	stats_ui.position = Vector2(-45.0, visible_size.y * 0.5 + 5.0)
	status_handler.position = Vector2(-27.0, visible_size.y * 0.5 + 24.0)

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
		"bull_demon":
			return ELITE_ART_MAX_SIZE
		"bone_dragon":
			return BOSS_ART_MAX_SIZE
		_:
			return DEFAULT_ART_MAX_SIZE


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
	arrow.show()


func _on_area_exited(_area: Area2D) -> void:
	arrow.hide()
