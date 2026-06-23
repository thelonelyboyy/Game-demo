class_name ManaUI
extends Panel

@export var char_stats: CharacterStats : set = _set_char_stats

@onready var mana_label: Label = $ManaLabel
@onready var frame: TextureRect = $Frame


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())


func _set_char_stats(value: CharacterStats) -> void:
	char_stats = value
	
	if not char_stats.stats_changed.is_connected(_on_stats_changed):
		char_stats.stats_changed.connect(_on_stats_changed)

	if not is_node_ready():
		await ready

	_on_stats_changed()


func _on_stats_changed() -> void:
	mana_label.text = "%s/%s" % [char_stats.mana, char_stats.max_mana]
	var active := char_stats.mana > 0
	frame.modulate = Color.WHITE if active else Color(0.55, 0.48, 0.48, 0.78)
	mana_label.modulate = Color.WHITE if active else Color(0.68, 0.72, 0.75, 0.72)
