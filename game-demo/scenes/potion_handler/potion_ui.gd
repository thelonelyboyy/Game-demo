class_name PotionUI
extends Control

signal use_requested(potion_ui: PotionUI)

@export var potion: Potion : set = set_potion

@onready var icon: TextureRect = $Icon


func set_potion(new_potion: Potion) -> void:
	if not is_node_ready():
		await ready

	potion = new_potion
	if not potion:
		return
	icon.texture = potion.icon
	tooltip_text = _format_tooltip()


func _format_tooltip() -> String:
	if not potion:
		return ""
	var label := "符箓" if potion.category == Potion.Category.TALISMAN else "丹药"
	return "%s（%s）\n%s" % [potion.potion_name, label, potion.get_tooltip()]


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		use_requested.emit(self)
