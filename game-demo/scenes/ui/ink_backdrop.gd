class_name InkBackdrop
extends Control

@export var variant := "menu"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(func(): queue_redraw())


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color("080908"))

	match variant:
		"map":
			_draw_map_backdrop()
		"battle":
			_draw_battle_backdrop()
		"character":
			_draw_character_backdrop()
		_:
			_draw_menu_backdrop()

	_draw_ink_wash()
	_draw_border_vignette()


func _draw_menu_backdrop() -> void:
	var w := size.x
	var h := size.y
	_draw_mountains([
		Vector2(0, h * 0.74),
		Vector2(w * 0.14, h * 0.54),
		Vector2(w * 0.30, h * 0.70),
		Vector2(w * 0.47, h * 0.45),
		Vector2(w * 0.66, h * 0.68),
		Vector2(w * 0.84, h * 0.50),
		Vector2(w, h * 0.70),
		Vector2(w, h),
		Vector2(0, h),
	], Color("111817"), Color("202a26"))
	_draw_sun(Vector2(w * 0.78, h * 0.22), h * 0.09, Color(0.68, 0.42, 0.22, 0.18))
	_draw_cloud_band(h * 0.42, Color(0.72, 0.70, 0.62, 0.08))


func _draw_character_backdrop() -> void:
	var w := size.x
	var h := size.y
	_draw_mountains([
		Vector2(0, h * 0.82),
		Vector2(w * 0.18, h * 0.60),
		Vector2(w * 0.35, h * 0.76),
		Vector2(w * 0.58, h * 0.52),
		Vector2(w * 0.80, h * 0.73),
		Vector2(w, h * 0.58),
		Vector2(w, h),
		Vector2(0, h),
	], Color("101413"), Color("27312c"))
	_draw_cloud_band(h * 0.32, Color(0.9, 0.84, 0.68, 0.07))
	draw_line(Vector2(w * 0.14, h * 0.72), Vector2(w * 0.86, h * 0.72), Color(0.75, 0.61, 0.34, 0.22), 2.0, true)


func _draw_map_backdrop() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color("03070b"))
	_draw_mountains([
		Vector2(0, h * 0.24),
		Vector2(w * 0.12, h * 0.08),
		Vector2(w * 0.20, h * 0.26),
		Vector2(w * 0.26, h * 0.11),
		Vector2(w * 0.31, h * 0.34),
		Vector2(w * 0.31, h),
		Vector2(0, h),
	], Color("07141c"), Color("0c2732"))
	_draw_mountains([
		Vector2(w, h * 0.28),
		Vector2(w * 0.88, h * 0.12),
		Vector2(w * 0.80, h * 0.31),
		Vector2(w * 0.73, h * 0.16),
		Vector2(w * 0.69, h * 0.37),
		Vector2(w * 0.69, h),
		Vector2(w, h),
	], Color("07131b"), Color("103140"))

	var paper := PackedVector2Array([
		Vector2(w * 0.16, h * 0.08),
		Vector2(w * 0.84, h * 0.08),
		Vector2(w * 0.87, h * 0.50),
		Vector2(w * 0.84, h * 0.93),
		Vector2(w * 0.18, h * 0.95),
		Vector2(w * 0.13, h * 0.53),
	])
	draw_colored_polygon(paper, Color("aea8b0"))
	for i in paper.size():
		draw_line(paper[i], paper[(i + 1) % paper.size()], Color("676a76"), 8.0, true)
		draw_line(paper[i], paper[(i + 1) % paper.size()], Color("c3c0c8"), 3.0, true)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(w * 0.18, h * 0.11),
			Vector2(w * 0.82, h * 0.10),
			Vector2(w * 0.84, h * 0.90),
			Vector2(w * 0.20, h * 0.92),
			Vector2(w * 0.15, h * 0.53),
		]),
		Color("bab3b8")
	)
	_draw_paper_noise(Rect2(w * 0.16, h * 0.10, w * 0.68, h * 0.82))
	_draw_cloud_band(h * 0.82, Color(0.52, 0.56, 0.67, 0.08))
	draw_line(Vector2(w * 0.18, h * 0.89), Vector2(w * 0.82, h * 0.78), Color(0.28, 0.34, 0.40, 0.22), 3.0, true)


func _draw_battle_backdrop() -> void:
	var w := size.x
	var h := size.y
	_draw_mountains([
		Vector2(0, h * 0.70),
		Vector2(w * 0.16, h * 0.50),
		Vector2(w * 0.34, h * 0.62),
		Vector2(w * 0.50, h * 0.42),
		Vector2(w * 0.72, h * 0.64),
		Vector2(w, h * 0.48),
		Vector2(w, h),
		Vector2(0, h),
	], Color("101413"), Color("202923"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0, h * 0.62),
			Vector2(w, h * 0.54),
			Vector2(w, h),
			Vector2(0, h),
		]),
		Color("17130f")
	)
	draw_line(Vector2(0, h * 0.62), Vector2(w, h * 0.54), Color(0.72, 0.56, 0.28, 0.20), 2.0, true)
	_draw_cloud_band(h * 0.24, Color(0.72, 0.70, 0.62, 0.06))


func _draw_mountains(points: Array[Vector2], fill: Color, edge: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), fill)
	for i in points.size() - 3:
		draw_line(points[i], points[i + 1], edge, 2.0, true)


func _draw_sun(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center, radius, color)
	draw_circle(center, radius * 0.72, Color(color.r, color.g, color.b, color.a * 0.55))


func _draw_cloud_band(y: float, color: Color) -> void:
	var w := size.x
	for i in 9:
		var x := w * (0.04 + i * 0.13)
		draw_circle(Vector2(x, y + sin(i * 1.7) * 18.0), 90.0 + i % 3 * 18.0, color)


func _draw_paper_noise(rect: Rect2) -> void:
	for i in 80:
		var x := rect.position.x + fmod(float(i * 73), rect.size.x)
		var y := rect.position.y + fmod(float(i * 41), rect.size.y)
		var radius := 1.2 + float(i % 5) * 0.55
		var alpha := 0.028 + float(i % 4) * 0.008
		draw_circle(Vector2(x, y), radius, Color(0.36, 0.42, 0.52, alpha))

	for i in 18:
		var y := rect.position.y + rect.size.y * (0.10 + float(i) * 0.047)
		draw_line(
			Vector2(rect.position.x + rect.size.x * 0.03, y),
			Vector2(rect.position.x + rect.size.x * 0.96, y + sin(i * 1.31) * 7.0),
			Color(0.30, 0.25, 0.32, 0.065),
			1.0,
			true
		)


func _draw_ink_wash() -> void:
	var w := size.x
	var h := size.y
	for i in 8:
		var x := w * (0.08 + i * 0.13)
		var alpha := 0.022 + (i % 3) * 0.012
		draw_rect(Rect2(Vector2(x, 0), Vector2(w * 0.055, h)), Color(0.70, 0.66, 0.52, alpha))


func _draw_border_vignette() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, 4), Color(0.72, 0.56, 0.28, 0.20))
	draw_rect(Rect2(0, h - 4, w, 4), Color(0.72, 0.56, 0.28, 0.16))
	draw_rect(Rect2(0, 0, 4, h), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(w - 4, 0, 4, h), Color(0, 0, 0, 0.35))
