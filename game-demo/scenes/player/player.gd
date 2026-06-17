class_name Player
extends Node2D

const MAX_BATTLE_ART_HEIGHT := 82.0
const HEALTH_BAR_HALF_WIDTH := 88.0
const STATUS_ROW_HALF_WIDTH := 20.0

const ANIM_ROOT := "res://art/frame_animation/"
# 各动画的帧率与是否循环
const ANIM_DEFS := {
	"standby": {"fps": 20.0, "loop": true},
	"attack": {"fps": 20.0, "loop": false},
	"attacked": {"fps": 20.0, "loop": false},
	"Spellcasting": {"fps": 20.0, "loop": false},
	"death": {"fps": 20.0, "loop": false},
}

@export var stats: CharacterStats : set = set_character_stats

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var stats_ui: StatsUI = $StatsUI
@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler

var sprite_visible_size := Vector2.ZERO
var animated_sprite: AnimatedSprite2D


func _ready() -> void:
	status_handler.status_owner = self
	if not Events.card_played.is_connected(_on_card_played):
		Events.card_played.connect(_on_card_played)


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

	if _setup_battle_animation():
		sprite_2d.hide()
	else:
		sprite_2d.show()
		sprite_2d.texture = stats.art
		_fit_sprite_to_battle_height()
	update_stats()


func _setup_battle_animation() -> bool:
	if stats.battle_anim_id.is_empty():
		return false

	var frames := _build_sprite_frames(stats.battle_anim_id)
	if not frames:
		return false

	if not animated_sprite:
		animated_sprite = AnimatedSprite2D.new()
		add_child(animated_sprite)
		move_child(animated_sprite, sprite_2d.get_index() + 1)
		animated_sprite.animation_finished.connect(_on_animation_finished)

	animated_sprite.sprite_frames = frames
	animated_sprite.play("standby")
	_fit_animated_to_battle_height()
	return true


func _build_sprite_frames(anim_id: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var has_any := false

	for anim_name: String in ANIM_DEFS:
		var textures := _load_anim_frames("%s%s_%s/" % [ANIM_ROOT, anim_id, anim_name])
		if textures.is_empty():
			continue
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, ANIM_DEFS[anim_name].loop)
		frames.set_animation_speed(anim_name, ANIM_DEFS[anim_name].fps)
		for texture: Texture2D in textures:
			frames.add_frame(anim_name, texture)
		has_any = true

	return frames if has_any else null


func _load_anim_frames(folder: String) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for i in range(1, 100):
		var path := "%sframe_%03d.png" % [folder, i]
		if not ResourceLoader.exists(path):
			break
		var texture := load(path) as Texture2D
		if texture:
			textures.append(texture)
	return textures


func _fit_animated_to_battle_height() -> void:
	animated_sprite.scale = Vector2.ONE
	var texture := animated_sprite.sprite_frames.get_frame_texture("standby", 0)
	if not texture:
		return

	var texture_size := texture.get_size()
	var art_scale := 1.0
	if texture_size.y > MAX_BATTLE_ART_HEIGHT:
		art_scale = MAX_BATTLE_ART_HEIGHT / texture_size.y
	animated_sprite.scale = Vector2.ONE * art_scale
	sprite_visible_size = texture_size * art_scale
	refresh_battle_overlays()


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
		stats_ui.position.y + 46.0 * status_scale
	)


func _control_scale(control: Control) -> float:
	if not control:
		return 1.0
	return maxf(control.scale.x, 0.001)


func update_stats() -> void:
	stats_ui.update_stats(stats)


func _on_card_played(card: Card) -> void:
	if not card:
		return

	if card.type == Card.Type.ATTACK:
		# Play the attack swing, then signal so the card's damage lands at the
		# end of the animation. If there is no attack animation, resolve the
		# gate immediately so the attack still deals damage.
		if _has_anim("attack"):
			_play_oneshot("attack")
		else:
			Events.attack_animation_finished.emit.call_deferred()
	elif _has_anim("Spellcasting"):
		_play_oneshot("Spellcasting")


func _has_anim(anim_name: String) -> bool:
	return animated_sprite != null and animated_sprite.sprite_frames.has_animation(anim_name)


func _play_oneshot(anim_name: String) -> void:
	if not _has_anim(anim_name):
		return
	animated_sprite.play(anim_name)


func _on_animation_finished() -> void:
	if not animated_sprite:
		return

	var finished_anim := animated_sprite.animation
	# 非循环动画（attack/attacked/Spellcasting）播完回到待机；死亡动画保持最后一帧。
	if finished_anim != "death":
		animated_sprite.play("standby")

	if finished_anim == "attack":
		Events.attack_animation_finished.emit()


func take_damage(damage: int, which_modifier: Modifier.Type) -> void:
	if stats.health <= 0:
		return

	var modified_damage := maxi(0, modifier_handler.get_modified_value(damage, which_modifier))

	# 受击动画播完后再扣血，与攻击节奏保持一致：怪物攻击 -> 角色受击动画 -> 扣血。
	var hit_delay := 0.0
	if _has_anim("attacked"):
		animated_sprite.play("attacked")
		hit_delay = _anim_duration("attacked")

	var tween := create_tween()
	if hit_delay > 0.0:
		tween.tween_interval(hit_delay)
	tween.tween_callback(stats.take_damage.bind(modified_damage))
	tween.tween_interval(0.17)

	tween.finished.connect(
		func():
			if stats.health <= 0:
				_play_death_and_die()
	)


func _anim_duration(anim_name: String) -> float:
	if not _has_anim(anim_name):
		return 0.0
	var fps: float = ANIM_DEFS.get(anim_name, {}).get("fps", 10.0)
	if fps <= 0.0:
		return 0.0
	return float(animated_sprite.sprite_frames.get_frame_count(anim_name)) / fps


func _play_death_and_die() -> void:
	# 播放死亡动画后再结算死亡（无死亡动画则立即结算）。
	if _has_anim("death"):
		animated_sprite.play("death")
		await animated_sprite.animation_finished
	Events.player_died.emit()
	queue_free()
