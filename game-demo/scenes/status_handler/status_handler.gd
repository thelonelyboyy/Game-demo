class_name StatusHandler
extends GridContainer

signal statuses_applied(type: Status.Type)
signal status_blocked(status: Status)

const STATUS_APPLY_INTERVAL := 0.25
const STATUS_UI = preload("res://scenes/status_handler/status_ui.tscn")
const SPELL_WARD_ID := "spell_ward"

@export var status_owner: Node2D


func apply_statuses_by_type(type: Status.Type) -> void:
	if type == Status.Type.EVENT_BASED:
		return
		
	var status_queue: Array[Status] = _get_all_statuses().filter(
		func(status: Status):
			return status.type == type
	)
	if status_queue.is_empty():
		statuses_applied.emit(type)
		return
	
	var tween := create_tween()
	for status: Status in status_queue:
		tween.tween_callback(status.apply_status.bind(status_owner))
		tween.tween_interval(STATUS_APPLY_INTERVAL)
	
	tween.finished.connect(_emit_statuses_applied.bind(type))


func add_status(status: Status) -> void:
	if not status:
		return
	if status.is_debuff and _consume_spell_ward(status):
		return
	var stackable := status.stack_type != Status.StackType.NONE
	
	# Add it if it's new
	if not _has_status(status.id):
		var new_status_ui := STATUS_UI.instantiate() as StatusUI
		add_child(new_status_ui)
		new_status_ui.status = status
		new_status_ui.status.status_applied.connect(_on_status_applied)
		new_status_ui.status.initialize_status(status_owner)
		return

	# If it's unique and we already have it, we can return
	if not status.can_expire and not stackable:
		return
	
	# If it's duration-stackable, expand it
	if status.can_expire and status.stack_type == Status.StackType.DURATION:
		_get_status(status.id).duration += status.duration
		return
	
	# If it's stackable, stack it
	if status.stack_type == Status.StackType.INTENSITY:
		_get_status(status.id).stacks += status.stacks


func _consume_spell_ward(blocked_status: Status) -> bool:
	var spell_ward := _get_status(SPELL_WARD_ID)
	if not spell_ward or spell_ward.stacks <= 0:
		return false
	spell_ward.stacks -= 1
	status_blocked.emit(blocked_status)
	Events.ui_notice_requested.emit("%s 的法障抵消了一项负面状态" % _get_owner_name())
	return true


func _get_owner_name() -> String:
	var enemy := status_owner as Enemy
	if enemy and enemy.stats:
		return enemy.stats.display_name
	var player := status_owner as Player
	if player and player.stats:
		return player.stats.character_name
	return "目标"


func get_status(id: String) -> Status:
	return _get_status(id)


func get_status_stacks(id: String) -> int:
	var status := _get_status(id)
	return status.stacks if status else 0


func get_debuff_count() -> int:
	var count := 0
	for status: Status in _get_all_statuses():
		if status and status.is_debuff:
			count += 1
	return count


func remove_debuffs(max_count := 0) -> Array[Status]:
	var removed: Array[Status] = []
	for status_ui: StatusUI in get_children():
		if max_count > 0 and removed.size() >= max_count:
			break
		if not status_ui or status_ui.is_queued_for_deletion():
			continue
		var status := status_ui.status
		if not status or not status.is_debuff:
			continue
		removed.append(status)
		_remove_status_ui(status_ui)
	return removed


func remove_status(id: String) -> bool:
	for status_ui: StatusUI in get_children():
		if status_ui and status_ui.status and status_ui.status.id == id:
			_remove_status_ui(status_ui)
			return true
	return false
	

func _has_status(id: String) -> bool:
	for status_ui: StatusUI in get_children():
		if status_ui.status.id == id:
			return true
			
	return false


func _get_status(id: String) -> Status:
	for status_ui: StatusUI in get_children():
		if status_ui.status.id == id:
			return status_ui.status
	
	return null


func _get_all_statuses() -> Array[Status]:
	var statuses: Array[Status] = []
	for status_ui: StatusUI in get_children():
		statuses.append(status_ui.status)
		
	return statuses


func _remove_status_ui(status_ui: StatusUI) -> void:
	if not status_ui or not status_ui.status:
		return
	var status := status_ui.status
	if status.can_expire:
		status.duration = 0
	elif status.stack_type == Status.StackType.INTENSITY:
		status.stacks = 0
	else:
		status_ui.queue_free()


func _on_status_applied(status: Status) -> void:
	if status.can_expire:
		status.duration -= 1


func _emit_statuses_applied(type: Status.Type) -> void:
	statuses_applied.emit(type)


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		Events.status_tooltip_requested.emit(_get_all_statuses())
