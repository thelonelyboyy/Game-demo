class_name PotionHandler
extends HBoxContainer

signal potion_used(potion: Potion)

const MAX_SLOTS := 3
const POTION_UI := preload("res://scenes/potion_handler/potion_ui.tscn")

## 战斗外使用（地图回血）时把效果落到角色数值上。由 Run 设置。
var character_stats: CharacterStats


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	for child in get_children():
		child.queue_free()
	for i in range(MAX_SLOTS):
		_add_empty_slot()


func count() -> int:
	var occupied := 0
	for ui: PotionUI in get_children():
		if ui.potion:
			occupied += 1
	return occupied


func is_full() -> bool:
	return count() >= MAX_SLOTS


func add_potion(potion: Potion) -> bool:
	if not potion or is_full():
		return false
	for ui: PotionUI in get_children():
		if not ui.potion:
			ui.potion = potion
			return true
	return false


func get_potions() -> Array[Potion]:
	var result: Array[Potion] = []
	for ui: PotionUI in get_children():
		if ui.potion:
			result.append(ui.potion)
	return result


func load_potions(potions: Array) -> void:
	_ensure_slots()
	for ui: PotionUI in get_children():
		ui.clear_potion()
	for potion: Potion in potions:
		add_potion(potion)


func can_use(potion: Potion) -> bool:
	if _player():
		return true
	return potion.usable_out_of_combat


func _player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func _on_use_requested(ui: PotionUI) -> void:
	if not is_instance_valid(ui) or not ui.potion or not can_use(ui.potion):
		return
	var potion := ui.potion
	_apply(potion)
	ui.clear_potion()
	potion_used.emit(potion)


func _add_empty_slot() -> PotionUI:
	var ui := POTION_UI.instantiate() as PotionUI
	add_child(ui)
	ui.use_requested.connect(_on_use_requested)
	ui.potion = null
	return ui


func _ensure_slots() -> void:
	while get_child_count() < MAX_SLOTS:
		_add_empty_slot()


func _apply(potion: Potion) -> void:
	var player := _player()
	if player:
		var targets := _resolve_targets(potion, player)
		var modifiers: ModifierHandler = player.modifier_handler
		for effect in potion.configured_effects:
			if effect:
				effect.execute(null, targets, modifiers)
	else:
		# 战斗外：只把"回血"类效果落到角色数值上。
		for effect in potion.configured_effects:
			if effect is ConfiguredHealEffect and character_stats:
				character_stats.heal(effect.amount)


func _resolve_targets(potion: Potion, player: Player) -> Array[Node]:
	if potion.target_kind == Potion.TargetKind.SINGLE_ENEMY:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
				return [enemy]
		return []
	# SELF / ALL_ENEMIES：传入玩家作为场景上下文，效果按各自 target_mode 取组。
	return [player]
