class_name Player
extends Node2D

const WHITE_SPRITE_MATERIAL := preload("res://art/white_sprite_material.tres")
const MAX_BATTLE_ART_HEIGHT := 102.0
const HEALTH_BAR_HALF_WIDTH := 88.0
const STATUS_ROW_HALF_WIDTH := 20.0

@export var stats: CharacterStats : set = set_character_stats

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var stats_ui: StatsUI = $StatsUI
@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler

var sprite_visible_size := Vector2.ZERO


func _ready() -> void:
	status_handler.status_owner = self


func set_character_stats(value: CharacterStats) -> void:
	stats = value
	
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)

	update_player()


func update_player() -> void:
	if not stats is CharacterStats: 
		return
	if not is_inside_tree(): 
		await ready

	sprite_2d.texture = stats.art
	_fit_sprite_to_battle_height()
	update_stats()


func _fit_sprite_to_battle_height() -> void:
	sprite_2d.scale = Vector2.ONE
	if not sprite_2d.texture:
		return

	var texture_size := sprite_2d.texture.get_size()
	if texture_size.y <= MAX_BATTLE_ART_HEIGHT:
		sprite_visible_size = texture_size
		refresh_battle_overlays()
		return

	var art_scale := MAX_BATTLE_ART_HEIGHT / texture_size.y
	sprite_2d.scale = Vector2.ONE * art_scale
	sprite_visible_size = texture_size * art_scale
	refresh_battle_overlays()


func refresh_battle_overlays() -> void:
	if sprite_visible_size == Vector2.ZERO:
		return

	var stats_scale := _control_scale(stats_ui)
	var status_scale := _control_scale(status_handler)
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


func update_stats() -> void:
	stats_ui.update_stats(stats)


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
				Events.player_died.emit()
				queue_free()
	)
