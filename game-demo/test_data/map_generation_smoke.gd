extends Node

const BATTLE_POOL_PATH := "res://battles/battle_stats_pool.tres"
const EVENT_POOL_PATH := "res://scenes/event_rooms/event_room_pool.tres"
const MAPS_PER_CHAPTER := 12

var failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var generator := MapGenerator.new()
	generator.map_mode = MapGenerator.MapMode.ROGUELIKE
	generator.battle_stats_pool = (load(BATTLE_POOL_PATH) as BattleStatsPool).duplicate(true)
	generator.event_room_pool = (load(EVENT_POOL_PATH) as EventRoomPool).duplicate(true)
	_check(generator.battle_stats_pool != null and generator.event_room_pool != null, "map support pools load")
	if not generator.battle_stats_pool or not generator.event_room_pool:
		generator.free()
		_finish()
		return

	for chapter in range(1, 4):
		generator.current_chapter = chapter
		for sample in range(MAPS_PER_CHAPTER):
			var sample_seed := chapter * 1000 + sample
			seed(sample_seed)
			RNG.instance.seed = sample_seed
			var map_data := generator.generate_map()
			_check_map(map_data, "chapter %s seed %s" % [chapter, sample_seed])

	generator.free()
	_finish()


func _check_map(map_data: Array[Array], label: String) -> void:
	_check(map_data.size() == 20, "%s has twenty visible floors" % label)
	if map_data.size() != 20:
		return

	var blessing_rooms := _rooms_of_type(map_data, Room.Type.BLESSING)
	var boss_rooms := _rooms_of_type(map_data, Room.Type.BOSS)
	_check(blessing_rooms.size() == 1, "%s has one starting blessing" % label)
	_check(boss_rooms.size() == 1, "%s has one boss" % label)
	_check(_rooms_of_type(map_data, Room.Type.SHOP).size() >= MapGenerator.MIN_SHOP_ROOMS, "%s guarantees shops" % label)
	_check(_rooms_of_type(map_data, Room.Type.CAMPFIRE).size() >= MapGenerator.MIN_CAMPFIRE_ROOMS, "%s guarantees campfires" % label)
	_check(_rooms_of_type(map_data, Room.Type.ELITE).size() >= 1, "%s guarantees an elite" % label)
	_check(_rooms_of_type(map_data, Room.Type.TREASURE).size() >= 1, "%s guarantees treasure" % label)

	var pre_boss_row := map_data[map_data.size() - 2]
	for room: Room in pre_boss_row:
		if not room.next_rooms.is_empty():
			_check(room.type == Room.Type.CAMPFIRE, "%s makes every boss approach a campfire" % label)

	if blessing_rooms.is_empty():
		return
	var visited := {}
	_check(_walk_to_boss(blessing_rooms[0], 0, visited, label), "%s has a route from blessing to boss" % label)


func _walk_to_boss(room: Room, combat_streak: int, visited: Dictionary, label: String) -> bool:
	var next_streak := combat_streak + 1 if _is_combat(room.type) else 0
	_check(next_streak <= 2, "%s has no three-fight route segment at row %s" % [label, room.row])
	var key := "%s:%s:%s" % [room.row, room.column, next_streak]
	if visited.has(key):
		return bool(visited[key])
	if room.type == Room.Type.BOSS:
		visited[key] = true
		return true

	visited[key] = false
	_check(not room.next_rooms.is_empty(), "%s has no reachable dead-end at row %s" % [label, room.row])
	var reaches_boss := false
	for next_room: Room in room.next_rooms:
		reaches_boss = _walk_to_boss(next_room, next_streak, visited, label) or reaches_boss
	visited[key] = reaches_boss
	return reaches_boss


func _rooms_of_type(map_data: Array[Array], type: Room.Type) -> Array[Room]:
	var rooms: Array[Room] = []
	for row: Array in map_data:
		for room: Room in row:
			if room.type == type:
				rooms.append(room)
	return rooms


func _is_combat(type: Room.Type) -> bool:
	return type == Room.Type.MONSTER or type == Room.Type.ELITE


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("MAP_GENERATION_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("MAP_GENERATION_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)
