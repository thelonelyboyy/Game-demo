class_name StatusUI
extends Control

@export var status: Status : set = set_status

@onready var icon: TextureRect = $Icon
@onready var duration: Label = $Duration
@onready var stacks: Label = $Stacks


func set_status(new_status: Status) -> void:
	if not is_node_ready():
		await ready
	
	status = new_status
	icon.texture = status.icon
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tooltip_text = _format_tooltip()
	duration.visible = status.stack_type == Status.StackType.DURATION
	stacks.visible = status.stack_type == Status.StackType.INTENSITY
	custom_minimum_size = icon.custom_minimum_size
	
	if duration.visible:
		custom_minimum_size = Vector2(
			maxf(custom_minimum_size.x, duration.position.x + duration.size.x),
			maxf(custom_minimum_size.y, duration.position.y + duration.size.y)
		)
	elif stacks.visible:
		custom_minimum_size = Vector2(
			maxf(custom_minimum_size.x, stacks.position.x + stacks.size.x),
			maxf(custom_minimum_size.y, stacks.position.y + stacks.size.y)
		)
	
	if not status.status_changed.is_connected(_on_status_changed):
		status.status_changed.connect(_on_status_changed)
	
	_on_status_changed()


func _on_status_changed() -> void:
	if not status:
		return

	if status.can_expire and status.duration <= 0:
		queue_free()
		
	if status.stack_type == Status.StackType.INTENSITY and status.stacks == 0:
		queue_free()

	duration.text = str(status.duration)
	stacks.text = str(status.stacks)
	tooltip_text = _format_tooltip()


func _format_tooltip() -> String:
	if not status:
		return ""
	var text := status.get_tooltip()
	if text.is_empty():
		return ""
	# Many status tooltips embed a "%s" placeholder for their magnitude.
	if text.contains("%s"):
		var magnitude := status.stacks if status.stack_type == Status.StackType.INTENSITY else status.duration
		text = text.replace("%s", str(magnitude))
	# "%%" is the escaped percent sign used for the format operator; show it literally.
	text = text.replace("%%", "%")
	return text
