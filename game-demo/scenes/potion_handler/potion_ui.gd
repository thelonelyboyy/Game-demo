class_name PotionUI
extends Control

signal use_requested(potion_ui: PotionUI)
signal discard_requested(potion_ui: PotionUI)

@export var potion: Potion : set = set_potion

@onready var icon: TextureRect = $Icon
@onready var slot_frame: TextureRect = $SlotFrame


func set_potion(new_potion: Potion) -> void:
	if not is_node_ready():
		await ready

	potion = new_potion
	if not potion:
		icon.texture = null
		icon.modulate = Color(1, 1, 1, 0.0)
		slot_frame.modulate = Color(0.65, 0.55, 0.52, 0.76)
		tooltip_text = ""
		return
	icon.texture = potion.icon
	icon.modulate = Color.WHITE
	slot_frame.modulate = Color.WHITE
	tooltip_text = _format_tooltip()


func clear_potion() -> void:
	set_potion(null)


func _format_tooltip() -> String:
	if not potion:
		return ""
	var label := "符箓" if potion.category == Potion.Category.TALISMAN else "丹药"
	return "%s（%s）\n%s\n左键使用 · 右键丢弃" % [potion.potion_name, label, potion.get_tooltip()]


func _on_gui_input(event: InputEvent) -> void:
	if potion and event.is_action_pressed("left_mouse"):
		use_requested.emit(self)
		accept_event()
	elif potion and event.is_action_pressed("right_mouse"):
		discard_requested.emit(self)
		accept_event()
