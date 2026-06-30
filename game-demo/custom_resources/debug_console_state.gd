class_name DebugConsoleState
extends RefCounted

enum DamageEditMode { NONE, SET, ADD }

static var next_dealt_mode := DamageEditMode.NONE
static var next_dealt_amount := 0
static var next_taken_mode := DamageEditMode.NONE
static var next_taken_amount := 0


static func set_next_dealt(mode: int, amount: int) -> void:
	next_dealt_mode = mode
	next_dealt_amount = amount


static func set_next_taken(mode: int, amount: int) -> void:
	next_taken_mode = mode
	next_taken_amount = amount


static func clear_next_dealt() -> void:
	next_dealt_mode = DamageEditMode.NONE
	next_dealt_amount = 0


static func clear_next_taken() -> void:
	next_taken_mode = DamageEditMode.NONE
	next_taken_amount = 0


static func clear_all() -> void:
	clear_next_dealt()
	clear_next_taken()


static func apply_next_dealt(current_damage: int) -> int:
	return _apply_and_clear(true, current_damage)


static func apply_next_taken(current_damage: int) -> int:
	return _apply_and_clear(false, current_damage)


static func describe() -> String:
	return "下一次造成伤害：%s；下一次受到伤害：%s" % [
		_describe_one(next_dealt_mode, next_dealt_amount),
		_describe_one(next_taken_mode, next_taken_amount),
	]


static func _apply_and_clear(is_dealt: bool, current_damage: int) -> int:
	var mode: int = next_dealt_mode if is_dealt else next_taken_mode
	var amount := next_dealt_amount if is_dealt else next_taken_amount
	if mode == DamageEditMode.NONE:
		return current_damage

	if is_dealt:
		clear_next_dealt()
	else:
		clear_next_taken()

	match mode:
		DamageEditMode.SET:
			return maxi(0, amount)
		DamageEditMode.ADD:
			return maxi(0, current_damage + amount)
		_:
			return current_damage


static func _describe_one(mode: int, amount: int) -> String:
	match mode:
		DamageEditMode.SET:
			return "设为 %s" % amount
		DamageEditMode.ADD:
			return "%+d" % amount
		_:
			return "未设置"
