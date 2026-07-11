class_name EventRoomPool
extends Resource

@export var event_rooms: Array[PackedScene]
@export var chapter_1_rooms: Array[PackedScene]
@export var chapter_2_rooms: Array[PackedScene]
@export var chapter_3_rooms: Array[PackedScene]

var _active_chapter := 0
var _event_bag: Array[PackedScene] = []


func begin_chapter(chapter: int) -> void:
	_active_chapter = clampi(chapter, 1, 3)
	_event_bag = get_chapter_rooms(_active_chapter).duplicate()
	RNG.array_shuffle(_event_bag)


func get_random(chapter := 1) -> PackedScene:
	var chapter_key := clampi(chapter, 1, 3)
	if _active_chapter != chapter_key or _event_bag.is_empty():
		begin_chapter(chapter_key)
	if _event_bag.is_empty():
		return null
	return _event_bag.pop_back()


func get_chapter_rooms(chapter: int) -> Array[PackedScene]:
	match clampi(chapter, 1, 3):
		1:
			return chapter_1_rooms if not chapter_1_rooms.is_empty() else event_rooms
		2:
			return chapter_2_rooms if not chapter_2_rooms.is_empty() else event_rooms
		3:
			return chapter_3_rooms if not chapter_3_rooms.is_empty() else event_rooms
		_:
			return event_rooms
