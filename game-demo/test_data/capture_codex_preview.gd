extends Node

const CODEX_SCENE_PATH := "res://scenes/ui/codex.tscn"
const OUTPUT_PATH := "res://art/design/codex_overview_preview.png"


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	get_window().size = Vector2i(1672, 941)

	var codex_scene := load(CODEX_SCENE_PATH) as PackedScene
	if not codex_scene:
		push_error("CODEX_CAPTURE_FAIL: missing codex scene")
		get_tree().quit(1)
		return

	var codex := codex_scene.instantiate()
	add_child(codex)
	codex.show()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout

	var image := get_viewport().get_texture().get_image()
	var output_path := ProjectSettings.globalize_path(OUTPUT_PATH)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var error := image.save_png(output_path)
	if error != OK:
		push_error("CODEX_CAPTURE_FAIL: save_png %s" % error)
		get_tree().quit(1)
		return

	print("CODEX_CAPTURE_OK:%s" % output_path)
	get_tree().quit(0)
