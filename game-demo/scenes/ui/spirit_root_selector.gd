extends Control

const RUN_SCENE := preload("res://scenes/run/run.tscn")

@export var run_startup: RunStartup

@onready var title: Label = %Title
@onready var description: Label = %Description
@onready var buttons: HBoxContainer = %Buttons

var offered_roots: Array = []


func _ready() -> void:
	_polish_scene()
	_roll_spirit_roots()
	_setup_buttons()


func _roll_spirit_roots() -> void:
	offered_roots = [
		Card.Element.METAL,
		Card.Element.WOOD,
		Card.Element.WATER,
		Card.Element.FIRE,
		Card.Element.EARTH,
	]
	RNG.array_shuffle(offered_roots)
	offered_roots = offered_roots.slice(0, 3)


func _setup_buttons() -> void:
	title.text = "选择灵根"
	description.text = "从三种灵根中选择一种。开局会随机将一张打击或防御转化为所选元素。"

	for child: Node in buttons.get_children():
		child.queue_free()

	for root in offered_roots:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(250, 220)
		InkTheme.apply_panel(panel)
		buttons.add_child(panel)

		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 14)
		panel.add_child(content)

		var button := Button.new()
		button.custom_minimum_size = Vector2(210, 72)
		button.text = "%s灵根" % SpiritRootText.element_name(root)
		InkTheme.apply_button(button, true)
		button.add_theme_color_override("font_color", SpiritRootText.element_color(root))
		button.pressed.connect(_on_root_selected.bind(root))
		content.add_child(button)

		var effect := Label.new()
		effect.text = SpiritRootText.perfect_effect(root)
		effect.custom_minimum_size = Vector2(210, 104)
		effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect.add_theme_font_size_override("font_size", 18)
		effect.add_theme_color_override("font_color", Color("eee7d2"))
		content.add_child(effect)


func _on_root_selected(root: Card.Element) -> void:
	run_startup.type = RunStartup.Type.NEW_RUN
	run_startup.selected_spirit_root = root
	get_tree().change_scene_to_packed(RUN_SCENE)


func _polish_scene() -> void:
	InkTheme.add_backdrop(self, "character")
	$Background.hide()
	InkTheme.apply_title(title, 56)
	InkTheme.apply_body_label(description, 22)
