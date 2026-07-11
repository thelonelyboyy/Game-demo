extends Node

const EVENT_POOL_PATH := "res://scenes/event_rooms/event_room_pool.tres"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const NEW_EVENT_PATHS := [
	"res://scenes/event_rooms/blood_script_wall_event.tscn",
	"res://scenes/event_rooms/soul_auction_event.tscn",
	"res://scenes/event_rooms/heaven_flame_eye_event.tscn",
]

var failures: PackedStringArray = []


func _ready() -> void:
	get_tree().create_timer(12.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var pool := load(EVENT_POOL_PATH) as EventRoomPool
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	_check(pool != null and character_resource != null, "event progression resources load")
	if not pool or not character_resource:
		_finish()
		return

	_check(pool.event_rooms.size() == 45, "event catalog contains forty-five events")
	var all_paths := {}
	for scene: PackedScene in pool.event_rooms:
		_check(scene != null, "event catalog entries load")
		if scene:
			all_paths[scene.resource_path] = true
			var instance := scene.instantiate()
			_check(instance is EventRoom, "%s instantiates as an event room" % scene.resource_path)
			instance.free()
	_check(all_paths.size() == 45, "event catalog paths are unique")

	var chapter_paths := {}
	for chapter in range(1, 4):
		var rooms := pool.get_chapter_rooms(chapter)
		_check(rooms.size() == 15, "chapter %s contains fifteen events" % chapter)
		pool.begin_chapter(chapter)
		var bag_paths := {}
		for _i in 15:
			var scene := pool.get_random(chapter)
			_check(scene != null, "chapter %s bag produces an event" % chapter)
			if scene:
				bag_paths[scene.resource_path] = true
				chapter_paths[scene.resource_path] = true
		_check(bag_paths.size() == 15, "chapter %s bag does not repeat before exhaustion" % chapter)
	_check(chapter_paths.size() == 45, "chapter event pools do not overlap")

	for path: String in NEW_EVENT_PATHS:
		_check(all_paths.has(path), "%s is registered in the event catalog" % path)

	_check_new_event_effects(character_resource)
	_finish()


func _check_new_event_effects(character_resource: CharacterStats) -> void:
	var character := character_resource.create_instance() as CharacterStats
	var scene := load(NEW_EVENT_PATHS[0]) as PackedScene
	var event := scene.instantiate() as GenericEvent
	_check(event != null, "new demonic event uses generic event behavior")
	if not event:
		return
	event.character_stats = character
	event.run_stats = RunStats.new()

	var deck_size := character.deck.cards.size()
	event._apply_single_effect("gain_rare_card", 1)
	_check(character.deck.cards.size() == deck_size + 1, "event can add a permanent reward card")
	_check(character.deck.cards.back().rarity == Card.Rarity.RARE, "rare-card event reward is actually rare")

	event._apply_single_effect("gain_curse", 1)
	_check(character.deck.cards.size() == deck_size + 2, "event can add a curse")
	_check(character.deck.cards.back().id == "heart_demon", "event curse is heart demon")
	event.free()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("EVENT_PROGRESSION_SMOKE_OK")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error("EVENT_PROGRESSION_SMOKE: %s" % failure)
	get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("EVENT_PROGRESSION_SMOKE: timed out")
	get_tree().quit(1)
