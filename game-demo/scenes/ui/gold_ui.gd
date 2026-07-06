class_name GoldUI
extends HBoxContainer

const ROLL_DURATION := 0.7

@export var run_stats: RunStats : set = set_run_stats

@onready var label: Label = $Label

var _shown_gold := 0
var _synced_once := false
var _roll_tween: Tween


func _ready() -> void:
	label.text = "0"


func set_run_stats(new_value: RunStats) -> void:
	run_stats = new_value

	if not run_stats.gold_changed.is_connected(_update_gold):
		run_stats.gold_changed.connect(_update_gold)
		_update_gold()


func _update_gold() -> void:
	if not is_node_ready():
		await ready

	var target := run_stats.gold

	# 进场首次同步（新开局/读档）直接显示，不做滚动。
	if not _synced_once:
		_synced_once = true
		_shown_gold = target
		label.text = str(target)
		return

	if _roll_tween and _roll_tween.is_running():
		_roll_tween.kill()
	if _shown_gold == target:
		label.text = str(target)
		return

	var increased := target > _shown_gold
	if increased:
		GameSfx.play(GameSfx.COINS, -4.0)
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2.ONE * (1.25 if increased else 0.85)
	label.modulate = Color(1.45, 1.3, 0.85) if increased else Color(1.5, 0.6, 0.55)

	_roll_tween = create_tween().set_parallel(true)
	_roll_tween.tween_method(_set_shown_gold, _shown_gold, target, ROLL_DURATION) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_roll_tween.tween_property(label, "scale", Vector2.ONE, 0.40) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_roll_tween.tween_property(label, "modulate", Color.WHITE, ROLL_DURATION) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _set_shown_gold(value: float) -> void:
	_shown_gold = roundi(value)
	label.text = str(_shown_gold)
