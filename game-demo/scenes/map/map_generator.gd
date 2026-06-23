class_name MapGenerator
extends Node

enum MapMode {TEST_LINEAR, ROGUELIKE, TEST_ELITE_LINEAR}

const X_DIST := 45
const Y_DIST := 40
const PLACEMENT_RANDOMNESS := 4
const FLOORS := 15
const TEST_FLOORS := 7
const TEST_ELITE_FLOORS := 8
const MAP_WIDTH := 7
const PATHS := 6
const MONSTER_ROOM_WEIGHT := 12.0
const ELITE_ROOM_WEIGHT := 2.4
const EVENT_ROOM_WEIGHT := 5.0
const SHOP_ROOM_WEIGHT := 2.5
const CAMPFIRE_ROOM_WEIGHT := 4.0
const ELITE_HEALTH_MULTIPLIER := 1.45
const ELITE_DAMAGE_MULTIPLIER := 1.25
const ELITE_GOLD_MULTIPLIER := 1.55
const ELITE_BATTLE := preload("res://battles/tier_1_bull_demon.tres")
# 测试地图固定战斗：普通=符纸兵+雾隐狼、精英=牛魔、Boss=渊狱剑魂（确定性，便于调试）
const TEST_FIXED_MONSTER_BATTLE := preload("res://battles/demo_n_paper_wolf.tres")
const TEST_FIXED_ELITE_BATTLE := preload("res://battles/demo_e_bull_demon.tres")
const TEST_FIXED_BOSS_BATTLE := preload("res://battles/demo_b_sword_soul.tres")

# 章节难度爬升：按章节号(1~3)取下标，0 号占位不用。
# 越后期的章节敌人血量/伤害越高，金币奖励也相应提升，让三章形成明显梯度。
const CHAPTER_HEALTH_MULTIPLIERS := [1.0, 1.0, 1.30, 1.65]
const CHAPTER_DAMAGE_MULTIPLIERS := [1.0, 1.0, 1.15, 1.30]
const CHAPTER_GOLD_MULTIPLIERS := [1.0, 1.0, 1.20, 1.40]

@export var map_mode: MapMode = MapMode.ROGUELIKE
@export var battle_stats_pool: BattleStatsPool
@export var event_room_pool: EventRoomPool

var random_room_type_weights = {
	Room.Type.MONSTER: 0.0,
	Room.Type.ELITE: 0.0,
	Room.Type.BLESSING: 0.0,
	Room.Type.CAMPFIRE: 0.0,
	Room.Type.SHOP: 0.0,
	Room.Type.EVENT: 0.0
}
var random_room_type_total_weight := 0
var map_data: Array[Array]
var current_chapter := 1


func generate_map() -> Array[Array]:
	battle_stats_pool.setup()

	if map_mode == MapMode.TEST_LINEAR:
		return _generate_test_linear_map()
	if map_mode == MapMode.TEST_ELITE_LINEAR:
		return _generate_test_elite_linear_map()

	map_data = _generate_initial_grid(FLOORS)
	var starting_points := _get_random_starting_points()
	
	for j in starting_points:
		var current_j := j
		for i in FLOORS - 1:
			current_j = _setup_connection(i, current_j)
			
	_setup_boss_room()
	_setup_random_room_weights()
	_setup_room_types()
	_ensure_elite_room_exists()
	_prepend_blessing_room()
	
	return map_data


func _generate_test_linear_map() -> Array[Array]:
	map_data = _generate_initial_grid(TEST_FLOORS, false)
	var middle := floori(MAP_WIDTH * 0.5)
	var room_types := [
		Room.Type.BLESSING,
		Room.Type.MONSTER,
		Room.Type.CAMPFIRE,
		Room.Type.SHOP,
		Room.Type.TREASURE,
		Room.Type.EVENT,
		Room.Type.BOSS,
	]

	for i in TEST_FLOORS:
		var room := map_data[i][middle] as Room
		room.type = room_types[i]
		room.position = Vector2(middle * X_DIST, i * -Y_DIST)

		if room.type == Room.Type.MONSTER:
			room.battle_stats = TEST_FIXED_MONSTER_BATTLE
		elif room.type == Room.Type.BOSS:
			room.battle_stats = TEST_FIXED_BOSS_BATTLE
		elif room.type == Room.Type.EVENT:
			room.event_scene = event_room_pool.get_random()

		if i < TEST_FLOORS - 1:
			var next_room := map_data[i + 1][middle] as Room
			room.next_rooms.append(next_room)

	return map_data


func _generate_test_elite_linear_map() -> Array[Array]:
	map_data = _generate_initial_grid(TEST_ELITE_FLOORS, false)
	var middle := floori(MAP_WIDTH * 0.5)
	var room_types := [
		Room.Type.BLESSING,
		Room.Type.MONSTER,
		Room.Type.ELITE,
		Room.Type.CAMPFIRE,
		Room.Type.SHOP,
		Room.Type.TREASURE,
		Room.Type.EVENT,
		Room.Type.BOSS,
	]

	for i in TEST_ELITE_FLOORS:
		var room := map_data[i][middle] as Room
		room.type = room_types[i]
		room.position = Vector2(middle * X_DIST, i * -Y_DIST)

		if room.type == Room.Type.MONSTER:
			room.battle_stats = TEST_FIXED_MONSTER_BATTLE
		elif room.type == Room.Type.ELITE:
			room.battle_stats = TEST_FIXED_ELITE_BATTLE
		elif room.type == Room.Type.BOSS:
			room.battle_stats = TEST_FIXED_BOSS_BATTLE
		elif room.type == Room.Type.EVENT:
			room.event_scene = event_room_pool.get_random()

		if i < TEST_ELITE_FLOORS - 1:
			var next_room := map_data[i + 1][middle] as Room
			room.next_rooms.append(next_room)

	return map_data


func _generate_initial_grid(floors: int, randomize_position := true) -> Array[Array]:
	var result: Array[Array] = []
	
	for i in floors:
		var adjacent_rooms: Array[Room]= []
		
		for j in MAP_WIDTH:
			var current_room := Room.new()
			var offset := Vector2(randf(), randf()) * PLACEMENT_RANDOMNESS if randomize_position else Vector2.ZERO
			current_room.position = Vector2(j * X_DIST, i * -Y_DIST) + offset
			current_room.row = i
			current_room.column = j
			current_room.next_rooms = []
			
			# Boss room has a non-random Y
			if i == floors - 1:
				current_room.position.y = (i + 1) * -Y_DIST
			
			adjacent_rooms.append(current_room)
			
		result.append(adjacent_rooms)

	return result


func _get_random_starting_points() -> Array[int]:
	var y_coordinates: Array[int]
	var unique_points: int = 0
	
	while unique_points < 2:
		unique_points = 0
		y_coordinates = []

		for i in PATHS:
			var starting_point := randi_range(0, MAP_WIDTH - 1)
			if not y_coordinates.has(starting_point):
				unique_points += 1
			
			y_coordinates.append(starting_point)
		
	return y_coordinates


func _setup_connection(i: int, j: int) -> int:
	var next_room: Room = null
	var current_room := map_data[i][j] as Room
	
	while not next_room or _would_cross_existing_path(i, j, next_room):
		var random_j := clampi(randi_range(j - 1, j + 1), 0, MAP_WIDTH - 1)
		next_room = map_data[i + 1][random_j]
		
	current_room.next_rooms.append(next_room)
	
	return next_room.column


func _would_cross_existing_path(i: int, j: int, room: Room) -> bool:
	var left_neighbour: Room
	var right_neighbour: Room
	
	# if j == 0, there's no left neighbour
	if j > 0:
		left_neighbour = map_data[i][j - 1]
	# if j == MAP_WIDTH - 1, there's no right neighbour
	if j < MAP_WIDTH - 1:
		right_neighbour = map_data[i][j + 1]
	
	# can't cross in right dir if right neighbour goes to left
	if right_neighbour and room.column > j:
		for next_room: Room in right_neighbour.next_rooms:
			if next_room.column < room.column:
				return true
	
	# can't cross in left dir if left neighbour goes to right
	if left_neighbour and room.column < j:
		for next_room: Room in left_neighbour.next_rooms:
			if next_room.column > room.column:
				return true
	
	return false


func _setup_boss_room() -> void:
	var middle := floori(MAP_WIDTH * 0.5)
	var boss_room := map_data[FLOORS - 1][middle] as Room
	
	for j in MAP_WIDTH:
		var current_room = map_data[FLOORS - 2][j] as Room
		if current_room.next_rooms:
			current_room.next_rooms = [] as Array[Room]
			current_room.next_rooms.append(boss_room)
			
	boss_room.type = Room.Type.BOSS
	boss_room.battle_stats = _battle_for_room(2)


func _setup_random_room_weights() -> void:
	random_room_type_weights[Room.Type.MONSTER] = MONSTER_ROOM_WEIGHT
	random_room_type_weights[Room.Type.ELITE] = MONSTER_ROOM_WEIGHT + ELITE_ROOM_WEIGHT
	random_room_type_weights[Room.Type.CAMPFIRE] = random_room_type_weights[Room.Type.ELITE] + CAMPFIRE_ROOM_WEIGHT
	random_room_type_weights[Room.Type.SHOP] = random_room_type_weights[Room.Type.CAMPFIRE] + SHOP_ROOM_WEIGHT
	random_room_type_weights[Room.Type.EVENT] = random_room_type_weights[Room.Type.SHOP] + EVENT_ROOM_WEIGHT
	
	random_room_type_total_weight = random_room_type_weights[Room.Type.EVENT]


func _setup_room_types() -> void:
	# first floor is always a battle
	for room: Room in map_data[0]:
		if room.next_rooms.size() > 0:
				room.type = Room.Type.MONSTER
				room.battle_stats = _battle_for_room(0)

	# 9th floor is always a treasure
	for room: Room in map_data[8]:
		if room.next_rooms.size() > 0:
				room.type = Room.Type.TREASURE
				
	# last floor before the boss is always a campfire
	for room: Room in map_data[13]:
		if room.next_rooms.size() > 0:
				room.type = Room.Type.CAMPFIRE
	
	# rest of rooms
	for current_floor in map_data:
		for room: Room in current_floor:
			for next_room: Room in room.next_rooms:
				if next_room.type == Room.Type.NOT_ASSIGNED:
					_set_room_randomly(next_room)


func _set_room_randomly(room_to_set: Room) -> void:
	var campfire_below_4 := true
	var consecutive_campfire := true
	var consecutive_shop := true
	var consecutive_elite := true
	var elite_too_early_or_late := true
	var campfire_on_13 := true
	
	var type_candidate: Room.Type
	
	while campfire_below_4 or consecutive_campfire or consecutive_shop or consecutive_elite or elite_too_early_or_late or campfire_on_13:
		type_candidate = _get_random_room_type_by_weight()
		
		var is_campfire := type_candidate == Room.Type.CAMPFIRE
		var has_campfire_parent := _room_has_parent_of_type(room_to_set, Room.Type.CAMPFIRE)
		var is_shop := type_candidate == Room.Type.SHOP
		var has_shop_parent := _room_has_parent_of_type(room_to_set, Room.Type.SHOP)
		var is_elite := type_candidate == Room.Type.ELITE
		var has_elite_parent := _room_has_parent_of_type(room_to_set, Room.Type.ELITE)
		
		campfire_below_4 = is_campfire and room_to_set.row < 3
		consecutive_campfire = is_campfire and has_campfire_parent
		consecutive_shop = is_shop and has_shop_parent
		consecutive_elite = is_elite and has_elite_parent
		elite_too_early_or_late = is_elite and (room_to_set.row < 3 or room_to_set.row > 11)
		campfire_on_13 = is_campfire and room_to_set.row == 12
		
	room_to_set.type = type_candidate

	if type_candidate == Room.Type.ELITE:
		_setup_elite_battle(room_to_set)
	elif type_candidate == Room.Type.MONSTER:
		room_to_set.battle_stats = _battle_for_room(0)
	
	if type_candidate == Room.Type.EVENT:
		room_to_set.event_scene = event_room_pool.get_random()


func _prepend_blessing_room() -> void:
	if map_data.is_empty():
		return

	for row: Array in map_data:
		for room: Room in row:
			room.row += 1
			room.position.y -= Y_DIST

	var middle := floori(MAP_WIDTH * 0.5)
	var blessing_row: Array[Room] = []
	for column in MAP_WIDTH:
		var room := Room.new()
		room.row = 0
		room.column = column
		room.position = Vector2(column * X_DIST, 0)
		room.next_rooms = []

		if column == middle:
			room.type = Room.Type.BLESSING
			for first_room: Room in map_data[0]:
				if first_room.next_rooms.size() > 0:
					room.next_rooms.append(first_room)

		blessing_row.append(room)

	map_data.insert(0, blessing_row)


func _setup_elite_battle(room: Room) -> void:
	var battle_stats := battle_stats_pool.get_random_battle_for_tier(1)
	if not battle_stats:
		battle_stats = ELITE_BATTLE as BattleStats
	if not battle_stats:
		battle_stats = battle_stats_pool.get_random_battle_for_tier(0)
	if not battle_stats:
		return

	room.battle_stats = battle_stats.duplicate() as BattleStats
	# 精英在精英倍率的基础上再叠加章节倍率
	room.battle_stats.enemy_health_multiplier = ELITE_HEALTH_MULTIPLIER * _chapter_value(CHAPTER_HEALTH_MULTIPLIERS)
	room.battle_stats.enemy_damage_multiplier = ELITE_DAMAGE_MULTIPLIER * _chapter_value(CHAPTER_DAMAGE_MULTIPLIERS)
	var gold_multiplier := ELITE_GOLD_MULTIPLIER * _chapter_value(CHAPTER_GOLD_MULTIPLIERS)
	room.battle_stats.gold_reward_min = ceili(room.battle_stats.gold_reward_min * gold_multiplier)
	room.battle_stats.gold_reward_max = ceili(room.battle_stats.gold_reward_max * gold_multiplier)


func _battle_for_room(tier: int) -> BattleStats:
	var base := battle_stats_pool.get_random_battle_for_tier(tier)
	if not base:
		return null
	# 复制一份再缩放，避免改动共享的战斗池资源
	return _apply_chapter_scaling(base.duplicate() as BattleStats)


func _apply_chapter_scaling(battle_stats: BattleStats) -> BattleStats:
	if not battle_stats:
		return null
	battle_stats.enemy_health_multiplier *= _chapter_value(CHAPTER_HEALTH_MULTIPLIERS)
	battle_stats.enemy_damage_multiplier *= _chapter_value(CHAPTER_DAMAGE_MULTIPLIERS)
	var gold_multiplier := _chapter_value(CHAPTER_GOLD_MULTIPLIERS)
	battle_stats.gold_reward_min = ceili(battle_stats.gold_reward_min * gold_multiplier)
	battle_stats.gold_reward_max = ceili(battle_stats.gold_reward_max * gold_multiplier)
	return battle_stats


func _chapter_value(multipliers: Array) -> float:
	var index := clampi(current_chapter, 1, multipliers.size() - 1)
	return multipliers[index]


func _ensure_elite_room_exists() -> void:
	if _has_room_type(Room.Type.ELITE):
		return

	var candidates: Array[Room] = []
	for row_index in range(3, 12):
		for room: Room in map_data[row_index]:
			if room.next_rooms.is_empty():
				continue
			if room.type == Room.Type.TREASURE or room.type == Room.Type.CAMPFIRE:
				continue
			candidates.append(room)

	if candidates.is_empty():
		return

	var elite_room := RNG.array_pick_random(candidates) as Room
	elite_room.type = Room.Type.ELITE
	_setup_elite_battle(elite_room)


func _has_room_type(type: Room.Type) -> bool:
	for row: Array in map_data:
		for room: Room in row:
			if room.type == type:
				return true

	return false


func _room_has_parent_of_type(room: Room, type: Room.Type) -> bool:
	var parents: Array[Room] = []
	# left parent
	if room.column > 0 and room.row > 0:
		var parent_candidate := map_data[room.row - 1][room.column - 1] as Room
		if parent_candidate.next_rooms.has(room):
			parents.append(parent_candidate)
	# parent below
	if room.row > 0:
		var parent_candidate := map_data[room.row - 1][room.column] as Room
		if parent_candidate.next_rooms.has(room):
			parents.append(parent_candidate)
	# right parent
	if room.column < MAP_WIDTH-1 and room.row > 0:
		var parent_candidate := map_data[room.row - 1][room.column + 1] as Room
		if parent_candidate.next_rooms.has(room):
			parents.append(parent_candidate)
	
	for parent: Room in parents:
		if parent.type == type:
			return true
	
	return false


func _get_random_room_type_by_weight() -> Room.Type:
	var roll := randf_range(0.0, random_room_type_total_weight)
	
	for type: Room.Type in random_room_type_weights:
		if random_room_type_weights[type] > roll:
			return type
	
	return Room.Type.MONSTER
