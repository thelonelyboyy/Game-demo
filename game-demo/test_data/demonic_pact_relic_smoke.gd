extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const PACT_PATHS := [
	"res://relics/demon_blood_pact_crown.tres",
	"res://relics/demon_flame_pact_wheel.tres",
	"res://relics/demon_ash_pact_scripture.tres",
]

var failures := PackedStringArray()


func _ready() -> void:
	get_tree().create_timer(10.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var character := load(CHARACTER_PATH) as CharacterStats
	_check(battle_scene != null and handler_scene != null and character != null, "pact smoke resources load")
	if not battle_scene or not handler_scene or not character:
		_finish()
		return

	for pact_index in PACT_PATHS.size():
		await _check_pact(pact_index, battle_scene, handler_scene, character)
	_finish()


func _check_pact(
	pact_index: int,
	battle_scene: PackedScene,
	handler_scene: PackedScene,
	character: CharacterStats
) -> void:
	var handler := handler_scene.instantiate() as RelicHandler
	add_child(handler)
	var battle := battle_scene.instantiate() as Battle
	add_child(battle)
	await get_tree().process_frame

	var stats := character.create_instance() as CharacterStats
	battle.char_stats = stats
	battle.player.stats = stats
	stats.mana = 0
	var pact := load(PACT_PATHS[pact_index]) as Relic
	handler.add_relic(pact)
	await get_tree().process_frame

	Events.player_turn_started.emit()
	await get_tree().process_frame
	_check(stats.mana == 1, "%s grants one mana at turn start" % pact.id)
	_emit_requirement_progress(pact_index)
	Events.player_turn_ended.emit()
	await get_tree().process_frame
	_check(battle.player.status_handler.get_status("exposed") == null, "%s avoids its penalty after meeting the route requirement" % pact.id)

	Events.player_turn_started.emit()
	await get_tree().process_frame
	_check(stats.mana == 2, "%s grants mana again on the next turn" % pact.id)
	Events.player_turn_ended.emit()
	await get_tree().process_frame
	var exposed := battle.player.status_handler.get_status("exposed")
	_check(exposed != null and exposed.duration == 1, "%s applies one turn of exposed when its route requirement is missed" % pact.id)

	battle.queue_free()
	handler.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _emit_requirement_progress(pact_index: int) -> void:
	match pact_index:
		0:
			Events.player_self_damaged.emit(4)
		1:
			Events.flame_wheel_changed.emit([0, 1, 2])
		2:
			Events.card_exhausted.emit(Card.new())
			Events.card_exhausted.emit(Card.new())


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("DEMONIC_PACT_RELIC_SMOKE_OK")
		get_tree().quit(0)
		return
	for failure: String in failures:
		push_error("DEMONIC_PACT_RELIC_SMOKE_FAIL: %s" % failure)
	get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("DEMONIC_PACT_RELIC_SMOKE_TIMEOUT")
	get_tree().quit(2)
