class_name CardMenuUI
extends CenterContainer

signal tooltip_requested(card: Card)

@export var card: Card : set = set_card

@onready var visuals: CardVisuals = $Visuals


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_visuals_gui_input)
	mouse_entered.connect(_on_visuals_mouse_entered)
	mouse_exited.connect(_on_visuals_mouse_exited)


func _on_visuals_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		tooltip_requested.emit(card)


func _on_visuals_mouse_entered() -> void:
	visuals.apply_hover_style()


func _on_visuals_mouse_exited() -> void:
	visuals.apply_normal_style()


func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready

	card = value
	if not card:
		visuals.card = null
		return

	visuals.card = card
