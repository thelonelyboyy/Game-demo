class_name RelicTooltip
extends Control

const MOUSE_OFFSET := Vector2(20, 18)
const VIEWPORT_PADDING := Vector2(18, 18)

@onready var panel: PanelContainer = %Panel
@onready var relic_icon: TextureRect = %RelicIcon
@onready var relic_tooltip: RichTextLabel = %RelicTooltip


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	hide_tooltip()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		hide_tooltip()


func _process(_delta: float) -> void:
	_position_near_mouse()


func show_tooltip(relic: Relic) -> void:
	relic_icon.texture = relic.icon
	relic_tooltip.text = "[b]%s[/b]\n%s" % [relic.relic_name, relic.get_tooltip()]
	show()
	set_process(true)
	_position_near_mouse()


func hide_tooltip() -> void:
	hide()
	set_process(false)


func _position_near_mouse() -> void:
	if not panel:
		return

	var viewport_size := get_viewport_rect().size
	var panel_size := panel.size
	if panel_size == Vector2.ZERO:
		panel_size = panel.get_combined_minimum_size()

	var target_position := get_viewport().get_mouse_position() + MOUSE_OFFSET
	target_position.x = clampf(
		target_position.x,
		VIEWPORT_PADDING.x,
		viewport_size.x - panel_size.x - VIEWPORT_PADDING.x
	)
	target_position.y = clampf(
		target_position.y,
		VIEWPORT_PADDING.y,
		viewport_size.y - panel_size.y - VIEWPORT_PADDING.y
	)
	panel.position = target_position
