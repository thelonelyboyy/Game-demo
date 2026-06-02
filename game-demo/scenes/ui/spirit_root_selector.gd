extends Control

const RUN_SCENE := preload("res://scenes/run/run.tscn")

@export var run_startup: RunStartup

@onready var title: Label = %Title
@onready var description: Label = %Description
@onready var buttons: HBoxContainer = %Buttons

var offered_roots: Array = []


func _ready() -> void:
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
		var button := Button.new()
		button.custom_minimum_size = Vector2(180, 96)
		button.text = "%s灵根" % _get_element_name(root)
		button.pressed.connect(_on_root_selected.bind(root))
		buttons.add_child(button)


func _on_root_selected(root: Card.Element) -> void:
	run_startup.type = RunStartup.Type.NEW_RUN
	run_startup.selected_spirit_root = root
	get_tree().change_scene_to_packed(RUN_SCENE)


func _get_element_name(root: Card.Element) -> String:
	match root:
		Card.Element.METAL:
			return "金"
		Card.Element.WOOD:
			return "木"
		Card.Element.WATER:
			return "水"
		Card.Element.FIRE:
			return "火"
		Card.Element.EARTH:
			return "土"
		_:
			return "无"
