extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const BATTLE_STATS_PATH := "res://battles/demo_e_shadow_reaper.tres"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const OUTPUT_PATH := "res://art/design/battle_ui_preview.png"
const MARKER_PATH := "res://art/design/battle_ui_preview_marker.txt"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	get_window().size = Vector2i(1920, 1080)
	_write_marker("started")

	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var character := load(CHARACTER_PATH) as CharacterStats
	var battle_stats := load(BATTLE_STATS_PATH) as BattleStats
	var relic_handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	if not battle_scene or not character or not battle_stats or not relic_handler_scene:
		push_error("CAPTURE_FAIL: missing capture resources")
		_finish(1)
		return
	_write_marker("resources loaded")

	var relic_handler := relic_handler_scene.instantiate() as RelicHandler
	add_child(relic_handler)
	_write_marker("relic handler added")

	var battle := battle_scene.instantiate() as Battle
	battle.char_stats = character.create_instance(Card.Element.FIRE) as CharacterStats
	battle.battle_stats = battle_stats
	battle.relics = relic_handler
	add_child(battle)
	_write_marker("battle added")
	await get_tree().process_frame
	_write_marker("frame 1")
	await get_tree().process_frame
	_write_marker("frame 2")

	battle.start_battle()
	_write_marker("battle started")
	await get_tree().process_frame
	_write_marker("battle frame 1")
	await get_tree().process_frame
	_write_marker("battle frame 2")
	await get_tree().create_timer(2.0).timeout
	_write_marker("timer done")

	var image := get_viewport().get_texture().get_image()
	var output_path := ProjectSettings.globalize_path(OUTPUT_PATH)
	var error := image.save_png(output_path)
	if error != OK:
		push_error("CAPTURE_FAIL: save_png %s" % error)
		_write_marker("save failed: %s" % error)
		_finish(1)
		return

	_write_marker("ok: %s" % output_path)
	print("CAPTURE_OK:%s" % output_path)
	_finish(0)


func _finish(code: int) -> void:
	get_tree().quit(code)


func _write_marker(text: String) -> void:
	var marker_path := ProjectSettings.globalize_path(MARKER_PATH)
	var file := FileAccess.open(marker_path, FileAccess.WRITE)
	if file:
		file.store_string(text)
