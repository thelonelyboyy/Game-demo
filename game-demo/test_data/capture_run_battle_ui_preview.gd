extends Node

const RUN_SCENE_PATH := "res://scenes/run/run.tscn"
const OUTPUT_PATH := "res://art/design/run_battle_ui_preview.png"
const MARKER_PATH := "res://art/design/run_battle_ui_preview_marker.txt"

var _previous_save: SaveGame


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	_previous_save = SaveGame.load_data()
	_write_marker("start")

	var run_scene := load(RUN_SCENE_PATH) as PackedScene
	if not run_scene:
		_finish(false, "run scene failed")
		return

	var run := run_scene.instantiate() as Run
	add_child(run)
	await get_tree().process_frame
	await get_tree().process_frame
	_write_marker("run added")

	var room := _first_battle_room(run)
	if not room:
		_finish(false, "battle room failed")
		return

	run._on_battle_room_entered(room)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(1.8).timeout
	_write_marker("battle ready")

	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		_finish(false, "save failed: %s" % error)
		return

	_finish(true, OUTPUT_PATH)


func _first_battle_room(run: Run) -> Room:
	if not run or not run.map:
		return null

	for row: Array in run.map.map_data:
		for room: Room in row:
			if room and room.type == Room.Type.MONSTER and room.battle_stats:
				return room
	return null


func _finish(ok: bool, message: String) -> void:
	_restore_previous_save()
	if ok:
		_write_marker("ok: %s" % message)
		print("RUN_CAPTURE_OK:%s" % message)
		get_tree().quit(0)
	else:
		_write_marker("fail: %s" % message)
		push_error("RUN_CAPTURE_FAIL:%s" % message)
		get_tree().quit(1)


func _restore_previous_save() -> void:
	if _previous_save:
		_previous_save.save_data()
	else:
		SaveGame.delete_data()


func _write_marker(message: String) -> void:
	var file := FileAccess.open(MARKER_PATH, FileAccess.WRITE)
	if file:
		file.store_line(message)
