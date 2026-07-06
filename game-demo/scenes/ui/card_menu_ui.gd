class_name CardMenuUI
extends CenterContainer

signal tooltip_requested(card: Card)

@export var card: Card : set = set_card

@onready var visuals: CardVisuals = $Visuals

var requested_visual_size := Vector2.ZERO
var _hover_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_visuals_gui_input)
	mouse_entered.connect(_on_visuals_mouse_entered)
	mouse_exited.connect(_on_visuals_mouse_exited)
	if requested_visual_size != Vector2.ZERO:
		_apply_visual_size(requested_visual_size)
	_animate_pop_in()


# 错落入场：按容器下标错开延迟（商店/奖励三选一/牌堆网格/删升融通用）。
# 先隐身、等容器完成布局后再弹出，pivot 才是正确的中心。
func _animate_pop_in() -> void:
	modulate = Color(1, 1, 1, 0.0)
	_start_pop_in.call_deferred()


func _start_pop_in() -> void:
	if not is_inside_tree():
		return
	pivot_offset = size * 0.5
	scale = Vector2.ONE * 0.9
	var delay: float = minf(float(get_index()), 20.0) * 0.045
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	tween.tween_property(self, "scale", Vector2.ONE, 0.28) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_visuals_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		tooltip_requested.emit(card)


func _on_visuals_mouse_entered() -> void:
	visuals.apply_hover_style()
	_animate_hover(1.05)


func _on_visuals_mouse_exited() -> void:
	visuals.apply_normal_style()
	_animate_hover(1.0)


# hover 浮起：只缩放视觉不动容器布局；抬高 z_index 防止被邻卡压住。
func _animate_hover(target: float) -> void:
	pivot_offset = size * 0.5
	z_index = 10 if target > 1.0 else 0
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", Vector2.ONE * target, 0.15)


func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready

	card = value
	if not card:
		visuals.card = null
		return

	visuals.card = card


func set_visual_size(value: Vector2) -> void:
	requested_visual_size = value
	if not is_node_ready():
		custom_minimum_size = value
		size = value
		return
	_apply_visual_size(value)


func _apply_visual_size(value: Vector2) -> void:
	custom_minimum_size = value
	size = value
	visuals.custom_minimum_size = value
	visuals.size = value
