class_name HitPause
extends RefCounted

## 命中停顿：伤害落地瞬间把 Engine.time_scale 拉低几十毫秒再恢复，
## 给打击一个"顿挫感"。恢复计时器用 ignore_time_scale，不受降速影响。
## 连续命中时取最长的停顿窗口，不会叠加或提前恢复。

const DEFAULT_DURATION := 0.08
const DEFAULT_TIME_SCALE := 0.05

static var _pause_until_msec := 0


static func trigger(duration := DEFAULT_DURATION, time_scale := DEFAULT_TIME_SCALE) -> void:
	# 无头模式（smoke 测试）没有视觉意义，且会拖慢受 time_scale 影响的测试计时器。
	if DisplayServer.get_name() == "headless":
		return

	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return
	# 全局暂停（暂停菜单）时不做时间操作。
	if tree.paused:
		return

	var until := Time.get_ticks_msec() + int(duration * 1000.0)
	if until <= _pause_until_msec:
		return
	_pause_until_msec = until

	Engine.time_scale = time_scale
	var timer := tree.create_timer(duration, true, false, true)
	timer.timeout.connect(_restore)


static func _restore() -> void:
	# 只有最后一个到期的计时器负责恢复（更长的停顿窗口仍在时跳过）。
	if Time.get_ticks_msec() < _pause_until_msec - 8:
		return
	Engine.time_scale = 1.0
