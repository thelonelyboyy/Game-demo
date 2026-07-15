extends Node

const MAP_SCENE_PATH := "res://scenes/map/map.tscn"

var failures := PackedStringArray()


func _ready() -> void:
	get_tree().create_timer(30.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var map_scene := load(MAP_SCENE_PATH) as PackedScene
	_check(map_scene != null, "地图场景可加载")
	if not map_scene:
		_finish()
		return

	var map := map_scene.instantiate() as Map
	add_child(map)
	await get_tree().process_frame
	map.generate_new_map(1)
	await get_tree().process_frame

	var elite_rooms := _rooms_of_type(map, Room.Type.ELITE)
	var shop_rooms := _rooms_of_type(map, Room.Type.SHOP)
	_check(not elite_rooms.is_empty(), "地图包含精英节点")
	_check(not shop_rooms.is_empty(), "地图包含商店节点")
	_check(map.legend_rows.has(Room.Type.ELITE), "天路图例包含精英交互行")
	if elite_rooms.is_empty() or not map.legend_rows.has(Room.Type.ELITE):
		map.queue_free()
		_finish()
		return

	var elite_row := map.legend_rows[Room.Type.ELITE] as Control
	_check(elite_row.mouse_filter == Control.MOUSE_FILTER_STOP, "图例行具有鼠标命中区域")
	_check(elite_row.get_global_rect().has_area(), "精英图例行具有实际屏幕尺寸")
	elite_row.mouse_entered.emit()
	await get_tree().process_frame
	_check(_all_highlighted(elite_rooms), "悬停精英图例时全部精英节点高亮")
	_check(_no_other_type_highlighted(map, Room.Type.ELITE), "悬停精英图例不会高亮其他节点")
	_check(map._legend_highlighted_type == Room.Type.ELITE, "地图记录当前精英图例筛选")

	await get_tree().create_timer(0.20, true).timeout
	var elite_visuals := elite_rooms[0].get_node("Visuals") as Node2D
	_check(elite_visuals.position.y < -0.5, "高亮精英节点开始上下跳动")

	elite_row.mouse_exited.emit()
	await get_tree().process_frame
	_check(_no_room_highlighted(map), "移出图例后清除所有节点高亮")
	_check(elite_visuals.position == Vector2.ZERO, "移出图例后节点回到原位")

	if not shop_rooms.is_empty() and map.legend_rows.has(Room.Type.SHOP):
		var shop_row := map.legend_rows[Room.Type.SHOP] as Control
		shop_row.mouse_entered.emit()
		await get_tree().process_frame
		_check(_all_highlighted(shop_rooms), "其他图例类型复用同一高亮机制")
		map.hide_map()
		await get_tree().process_frame
		_check(_no_room_highlighted(map), "关闭地图会清理图例高亮状态")

	map.queue_free()
	await get_tree().process_frame
	_finish()


func _rooms_of_type(map: Map, room_type: int) -> Array[MapRoom]:
	var result: Array[MapRoom] = []
	for child: Node in map.rooms.get_children():
		var map_room := child as MapRoom
		if map_room and map_room.room and map_room.room.type == room_type:
			result.append(map_room)
	return result


func _all_highlighted(map_rooms: Array[MapRoom]) -> bool:
	for map_room: MapRoom in map_rooms:
		if not map_room.legend_highlighted:
			return false
	return not map_rooms.is_empty()


func _no_other_type_highlighted(map: Map, active_type: int) -> bool:
	for child: Node in map.rooms.get_children():
		var map_room := child as MapRoom
		if map_room and map_room.room and map_room.room.type != active_type and map_room.legend_highlighted:
			return false
	return true


func _no_room_highlighted(map: Map) -> bool:
	for child: Node in map.rooms.get_children():
		var map_room := child as MapRoom
		if map_room and map_room.legend_highlighted:
			return false
	return true


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("MAP_LEGEND_INTERACTION_SMOKE_OK")
		get_tree().quit(0)
		return
	for failure: String in failures:
		push_error("MAP_LEGEND_INTERACTION_SMOKE_FAIL: %s" % failure)
	get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("MAP_LEGEND_INTERACTION_SMOKE_TIMEOUT")
	get_tree().quit(2)
