class_name HitPause
extends RefCounted

## 命中停顿：伤害落地瞬间把 Engine.time_scale 拉低几十毫秒再恢复，
## 给打击一个"顿挫感"。恢复计时器用 ignore_time_scale，不受降速影响。
## 连续命中时取最长的停顿窗口，不会叠加或提前恢复。

const DEFAULT_DURATION := 0.08
const DEFAULT_TIME_SCALE := 0.05

static var _pause_until_msec := 0
static var _restore_time_scale := 1.0
static var _generation := 0
static var _active := false


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

	var safe_duration := maxf(duration, 0.01)
	var until := Time.get_ticks_msec() + int(safe_duration * 1000.0)
	if not _active:
		_restore_time_scale = Engine.time_scale
		_active = true
	_pause_until_msec = maxi(_pause_until_msec, until)
	_generation += 1

	Engine.time_scale = minf(Engine.time_scale, clampf(time_scale, 0.01, 1.0))
	_schedule_restore(tree, _generation, safe_duration)


static func _schedule_restore(tree: SceneTree, generation: int, delay: float) -> void:
	var timer := tree.create_timer(maxf(delay, 0.01), true, false, true)
	timer.timeout.connect(_restore.bind(generation))


static func _restore(generation: int) -> void:
	if not _active or generation != _generation:
		return
	var remaining_msec := _pause_until_msec - Time.get_ticks_msec()
	if remaining_msec > 8:
		var tree := Engine.get_main_loop() as SceneTree
		if tree:
			_schedule_restore(tree, generation, float(remaining_msec) / 1000.0)
		return
	force_restore()


## Called from Battle every rendered frame. If a SceneTreeTimer callback is lost
## during a scene transition, the global game speed still recovers immediately.
static func watchdog() -> void:
	if _active and Time.get_ticks_msec() >= _pause_until_msec:
		force_restore()


static func force_restore() -> void:
	if not _active:
		return
	Engine.time_scale = _restore_time_scale
	_pause_until_msec = 0
	_restore_time_scale = 1.0
	_active = false
	_generation += 1
