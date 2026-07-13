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
	_check_curse_pool(character_resource)
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
	_check(character.deck.cards.back().is_curse_card(), "event curse is marked as a curse")
	event.free()


func _check_curse_pool(character_resource: CharacterStats) -> void:
	var character := character_resource.create_instance() as CharacterStats
	var event := GenericEvent.new()
	event.character_stats = character
	var deck_size := character.deck.cards.size()
	var curses := event._add_random_curses(3)
	_check(curses.size() == 3, "event curse pool contains three outcomes")
	_check(character.deck.cards.size() == deck_size + 3, "multi-curse effects add each curse to the permanent deck")

	var ids := {}
	for curse: Card in curses:
		ids[curse.id] = true
		_check(curse.is_curse_card(), "every curse pool card has the curse marker")
	_check(ids.size() == 3, "a multi-curse effect does not repeat before pool exhaustion")

	var blood_debt := curses.filter(func(card: Card): return card.id == "blood_debt_curse").front() as CultivationCard
	_check(blood_debt.blocks_manual_play(), "blood debt cannot be manually played")
	_check(blood_debt.has_discard_trigger() and blood_debt.discard_trigger_effects[0].amount == 2, "blood debt loses two life when discarded")

	var karmic_fire := curses.filter(func(card: Card): return card.id == "karmic_fire_curse").front() as CultivationCard
	_check(not karmic_fire.blocks_manual_play(), "karmic fire can be manually burned away")
	_check(karmic_fire.is_consumable_card() and karmic_fire.cost == 1, "karmic fire costs one mana and exhausts")
	_check(karmic_fire.configured_effects[0].amount == 3, "burning karmic fire costs three life")
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
