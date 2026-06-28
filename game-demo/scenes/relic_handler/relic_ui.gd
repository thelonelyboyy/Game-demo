class_name RelicUI
extends Control

@export var relic: Relic : set = set_relic

@onready var icon: TextureRect = $Icon
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _hovering := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func set_relic(new_relic: Relic) -> void:
	if not is_node_ready():
		await ready

	relic = new_relic
	icon.texture = relic.icon
	tooltip_text = relic.get_tooltip()
	if _hovering:
		Events.relic_tooltip_requested.emit(relic)


func flash() -> void:
	animation_player.play("flash")


func _on_gui_input(_event: InputEvent) -> void:
	pass


func _on_mouse_entered() -> void:
	_hovering = true
	if relic:
		Events.relic_tooltip_requested.emit(relic)


func _on_mouse_exited() -> void:
	_hovering = false
	Events.relic_tooltip_hide_requested.emit()
