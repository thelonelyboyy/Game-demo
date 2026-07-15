class_name BattleCombatantCard
extends Control

enum Kind {PLAYER, ENEMY}

const ICON_ATTACK := preload("res://assets/ui/generated/icons/icon_intent_attack.png")
const ICON_SHIELD := preload("res://art/tiles/intent_block_shield.png")
const COMBATANT_PORTRAIT_FRAME := preload("res://assets/ui/generated/cards/character_card_portrait_mask_frame.png")
const BATTLE_HP_BAR_FRAME := preload("res://assets/ui/generated/battle/battle_hp_bar_frame_9slice.png")
const BATTLE_INTENT_BADGE := preload("res://assets/ui/generated/battle/battle_intent_badge_attack_9slice.png")
const DEMONIC_CULTIVATOR_CARD := preload("res://art/ui/battle_cards/demonic_cultivator_card.png")
const PAPER_SOLDIER_CARD := preload("res://art/ui/battle_cards/paper_soldier_card.png")
const MIST_WOLF_CARD := preload("res://art/ui/battle_cards/mist_wolf_card.png")
const BULL_DEMON_CARD := preload("res://art/ui/battle_cards/bull_demon_card.png")
const ABYSSAL_SWORD_SOUL_CARD := preload("res://art/ui/battle_cards/abyssal_sword_soul_card.png")
const SHA_QI_STATUS := preload("res://statuses/sha_qi.tres")
const STATUS_ROW_HEIGHT := 112.0
const STATUS_ICON_SIZE := 36.0
const STATUS_CHIP_WIDTH := 62.0
const STATUS_CHIP_HEIGHT := 48.0

var kind := Kind.PLAYER
var combatant: Node
var stats: Stats
var status_handler: StatusHandler

var _intent_badge: Panel
var _frame: Panel
var _portrait: TextureRect
var _portrait_frame: TextureRect
var _name_label: Label
var _intent_label: Label
var _intent_icon: TextureRect
var _health_fill: ColorRect
var _block_fill: ColorRect
var _health_label: Label
var _block_label: Label
var _status_row: HFlowContainer
var _refresh_elapsed := 0.0
# 数值条平滑过渡：记录上次数值，只在真正变化时启动 tween（_process 0.12s 轮询会反复进 _refresh）。
var _last_health := -1
var _last_max_health := -1
var _last_block := -1
var _shown_health_ratio := 1.0
var _shown_block_ratio := 0.0
var _health_bar_tween: Tween
var _block_bar_tween: Tween
var _bar_sequence_tween: Tween
var _bar_animation_queue: Array[Dictionary] = []
var _displayed_health := -1
var _displayed_max_health := -1
var _displayed_block := -1
var _status_signature := ""
var _last_intent_text := ""
var _intent_pop_tween: Tween
# 煞气常驻徽章（仅玩家卡）：阈值与 class_mechanic_handler 保持一致（3/6/10）。
var _sha_badge: Panel
var _sha_label: Label
var _last_sha_stacks := -1
var _aura_tween: Tween

const SHA_BADGE_TIER_COLORS := [
	Color(0.52, 0.48, 0.42, 0.9),
	Color(0.86, 0.55, 0.24, 0.95),
	Color(0.88, 0.30, 0.22, 0.95),
	Color(1.0, 0.22, 0.16, 1.0),
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build()


func bind_player(player: Player) -> void:
	kind = Kind.PLAYER
	combatant = player
	stats = player.stats if player else null
	status_handler = player.status_handler if player else null
	_apply_kind_styles()
	_reset_animation_tracking()
	_connect_stats()
	_layout()
	_refresh()


func bind_enemy(enemy: Enemy) -> void:
	kind = Kind.ENEMY
	combatant = enemy
	stats = enemy.stats if enemy else null
	status_handler = enemy.status_handler if enemy else null
	_apply_kind_styles()
	_reset_animation_tracking()
	_connect_stats()
	_layout()
	_refresh()


func _reset_animation_tracking() -> void:
	if _bar_sequence_tween and _bar_sequence_tween.is_running():
		_bar_sequence_tween.kill()
	_bar_animation_queue.clear()
	_last_health = -1
	_last_max_health = -1
	_last_block = -1
	_displayed_health = -1
	_displayed_max_health = -1
	_displayed_block = -1
	_status_signature = ""
	_last_intent_text = ""
	_last_sha_stacks = -1
	if _portrait:
		_portrait.modulate = Color.WHITE


func _apply_kind_styles() -> void:
	if _frame:
		_frame.add_theme_stylebox_override("panel", _make_card_style())
	if _intent_badge:
		_intent_badge.add_theme_stylebox_override("panel", _make_intent_style())
	var health_bar: Panel = null
	if _health_fill:
		health_bar = _health_fill.get_parent() as Panel
	if health_bar:
		health_bar.add_theme_stylebox_override("panel", _make_bar_style(false))
	var block_bar: Panel = null
	if _block_fill:
		block_bar = _block_fill.get_parent() as Panel
	if block_bar:
		block_bar.add_theme_stylebox_override("panel", _make_bar_style(true))


func _process(delta: float) -> void:
	_refresh_elapsed += delta
	if _refresh_elapsed < 0.12:
		return
	_refresh_elapsed = 0.0
	_refresh()


func _build() -> void:
	_frame = Panel.new()
	_frame.name = "Frame"
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frame.clip_contents = true
	_frame.add_theme_stylebox_override("panel", _make_card_style())
	add_child(_frame)

	_intent_badge = Panel.new()
	_intent_badge.name = "IntentBadge"
	_intent_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intent_badge.z_index = 20
	_intent_badge.add_theme_stylebox_override("panel", _make_intent_style())
	add_child(_intent_badge)

	_portrait = TextureRect.new()
	_portrait.name = "Portrait"
	# Character identity belongs to the artwork only. PASS keeps combat targeting
	# working while allowing the portrait to own the name/description tooltip.
	_portrait.mouse_filter = Control.MOUSE_FILTER_PASS
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_frame.add_child(_portrait)

	_portrait_frame = TextureRect.new()
	_portrait_frame.name = "PortraitFrame"
	_portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.texture = COMBATANT_PORTRAIT_FRAME
	_portrait_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_frame.stretch_mode = TextureRect.STRETCH_SCALE
	_portrait_frame.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_portrait_frame.z_index = 2
	_frame.add_child(_portrait_frame)

	_name_label = _make_label("Name", 22, Color("f4deb0"))
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.z_index = 3
	_frame.add_child(_name_label)

	_intent_icon = TextureRect.new()
	_intent_icon.name = "IntentIcon"
	_intent_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intent_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_intent_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_intent_badge.add_child(_intent_icon)

	_intent_label = _make_label("IntentLabel", 24, Color("ffc08a"))
	_intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intent_badge.add_child(_intent_label)

	var health_back := _make_stat_bar("HealthBar", Color("d71928"), false)
	_health_fill = health_back.get_node("Fill") as ColorRect
	_health_label = health_back.get_node("Label") as Label
	_frame.add_child(health_back)

	var block_back := _make_stat_bar("BlockBar", Color("1aa4ff"), true)
	_block_fill = block_back.get_node("Fill") as ColorRect
	_block_label = block_back.get_node("Label") as Label
	_frame.add_child(block_back)

	_status_row = HFlowContainer.new()
	_status_row.name = "StatusRow"
	_status_row.mouse_filter = Control.MOUSE_FILTER_PASS
	_status_row.alignment = FlowContainer.ALIGNMENT_CENTER
	_status_row.add_theme_constant_override("h_separation", 6)
	_status_row.add_theme_constant_override("v_separation", 6)
	_frame.add_child(_status_row)

	_sha_badge = Panel.new()
	_sha_badge.name = "ShaQiBadge"
	_sha_badge.mouse_filter = Control.MOUSE_FILTER_STOP
	_sha_badge.z_index = 22
	_sha_badge.tooltip_text = _format_status_tooltip(SHA_QI_STATUS)
	_sha_badge.hide()
	add_child(_sha_badge)

	_sha_label = _make_label("ShaQiLabel", 22, Color("ffd9c8"))
	_sha_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sha_badge.add_child(_sha_label)

	resized.connect(_layout)
	_apply_kind_styles()
	_layout()


func _layout() -> void:
	if not _frame:
		return

	var w := size.x
	var h := size.y
	var intent_top_height := 50.0 if kind == Kind.ENEMY else 0.0
	var frame_h := maxf(260.0, h - intent_top_height)
	var sx := w / 150.0
	var sy := frame_h / 260.0
	var portrait_pos := Vector2(17.0 * sx, 16.0 * sy)
	var bar_x := 24.0 * sx
	var bar_w := maxf(96.0 * sx, w - 48.0 * sx)
	var bar_h := maxf(20.0, 11.0 * sy)
	var status_y := frame_h - STATUS_ROW_HEIGHT - 12.0
	var health_y := status_y - bar_h * 2.0 - 12.0
	var block_y := health_y + bar_h + 6.0
	var portrait_frame_pos := Vector2(9.0 * sx, 8.0 * sy)
	var portrait_frame_h := maxf(130.0 * sy, health_y - portrait_frame_pos.y - 8.0)
	var portrait_h := maxf(116.0 * sy, health_y - portrait_pos.y - 8.0)

	_set_rect(_frame, Vector2(0, intent_top_height), Vector2(w, frame_h))
	# 参考角色选择卡框的 150x260 坐标系做等比摆位，战斗中保持三国杀式竖版人物牌。
	_name_label.hide()
	_set_rect(_portrait, portrait_pos, Vector2(w - 34.0 * sx, portrait_h))
	_set_rect(
		_portrait_frame,
		portrait_frame_pos,
		Vector2(w - 18.0 * sx, portrait_frame_h)
	)
	_set_rect(_health_fill.get_parent() as Control, Vector2(bar_x, health_y), Vector2(bar_w, bar_h))
	_set_rect(_block_fill.get_parent() as Control, Vector2(bar_x, block_y), Vector2(bar_w, bar_h))
	_set_rect(_status_row, Vector2(12.0 * sx, status_y), Vector2(w - 24.0 * sx, STATUS_ROW_HEIGHT))
	_layout_bar_label(_health_label, _health_fill.get_parent() as Control)
	_layout_bar_label(_block_label, _block_fill.get_parent() as Control)

	if kind == Kind.ENEMY:
		_intent_badge.show()
		_set_rect(_intent_badge, Vector2(w * 0.5 - 126.0, 3.0), Vector2(252.0, 52.0))
		_layout_intent_badge()
	else:
		_intent_badge.hide()

	if _sha_badge:
		# 煞气徽章悬在玩家卡顶部上方，常驻可读。
		_set_rect(_sha_badge, Vector2(w * 0.5 - 70.0, intent_top_height - 44.0), Vector2(140.0, 40.0))
		_set_rect(_sha_label, Vector2(0.0, 0.0), Vector2(140.0, 40.0))


func _refresh() -> void:
	if not is_instance_valid(combatant) or not stats:
		hide()
		return

	show()
	tooltip_text = ""
	_portrait.tooltip_text = _combatant_tooltip()
	_portrait.texture = _portrait_texture()
	_refresh_bars()
	_refresh_intent()
	_refresh_statuses()
	_refresh_sha_badge()


# 玩家卡常驻煞气显示：有煞气就亮徽章，按阈值档位变色，层数变化 punch。
func _refresh_sha_badge() -> void:
	if not _sha_badge or kind != Kind.PLAYER:
		if _sha_badge:
			_sha_badge.hide()
		return

	var stacks := 0
	if status_handler:
		var status: Status = status_handler.get_status("sha_qi") if status_handler.has_method("get_status") else null
		if status:
			stacks = status.stacks

	if stacks <= 0:
		_sha_badge.hide()
		_last_sha_stacks = 0
		return

	_sha_badge.show()
	_sha_label.text = "煞气 %d" % stacks
	_sha_badge.tooltip_text = _format_status_tooltip(SHA_QI_STATUS, stacks)

	var tier := 0
	if stacks >= 10:
		tier = 3
	elif stacks >= 6:
		tier = 2
	elif stacks >= 3:
		tier = 1
	var accent: Color = SHA_BADGE_TIER_COLORS[tier]
	_sha_label.add_theme_color_override("font_color", accent.lightened(0.35))
	_sha_badge.add_theme_stylebox_override("panel", InkTheme.make_style(
		Color(0.06, 0.012, 0.010, 0.90),
		accent,
		2,
		8,
		Color(accent.r, accent.g, accent.b, 0.30 if tier >= 2 else 0.12),
		12 if tier >= 2 else 6
	))

	if _last_sha_stacks >= 0 and stacks != _last_sha_stacks:
		_sha_badge.pivot_offset = _sha_badge.size * 0.5
		_sha_badge.scale = Vector2.ONE * 1.35
		var tween := _sha_badge.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(_sha_badge, "scale", Vector2.ONE, 0.42)
	_last_sha_stacks = stacks


# 煞气档位气场：染信息卡立绘（世界立绘已隐藏，染卡才可见）。
func set_aura_tint(color: Color) -> void:
	if not _portrait:
		return
	if _aura_tween and _aura_tween.is_running():
		_aura_tween.kill()
	_aura_tween = _portrait.create_tween()
	_aura_tween.tween_property(_portrait, "modulate", color, 0.6) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _refresh_bars() -> void:
	var ratio := clampf(float(stats.health) / float(maxi(stats.max_health, 1)), 0.0, 1.0)
	var block_ratio := clampf(float(stats.block) / float(maxi(stats.max_health, 1)), 0.0, 1.0)
	_block_label.visible = true

	if _last_health < 0:
		_health_label.text = "%s/%s" % [stats.health, stats.max_health]
		_block_label.text = "护 %s" % stats.block
		_set_bar_ratio(ratio, true)
		_set_bar_ratio(block_ratio, false)
		_displayed_health = stats.health
		_displayed_max_health = stats.max_health
		_displayed_block = stats.block
	else:
		if stats.health != _last_health or stats.max_health != _last_max_health or stats.block != _last_block:
			_bar_animation_queue.append({
				"health": stats.health,
				"max_health": stats.max_health,
				"block": stats.block,
			})
			_start_next_bar_animation()

	_last_health = stats.health
	_last_max_health = stats.max_health
	_last_block = stats.block


func _start_next_bar_animation() -> void:
	if (_bar_sequence_tween and _bar_sequence_tween.is_running()) or _bar_animation_queue.is_empty():
		return
	var snapshot: Dictionary = _bar_animation_queue.pop_front()
	var next_health := int(snapshot["health"])
	var next_max_health := int(snapshot["max_health"])
	var next_block := int(snapshot["block"])
	var health_changed := next_health != _displayed_health or next_max_health != _displayed_max_health
	var block_changed := next_block != _displayed_block or next_max_health != _displayed_max_health

	_health_label.text = "%s/%s" % [next_health, next_max_health]
	_block_label.text = "护 %s" % next_block
	if health_changed:
		var health_ratio := clampf(float(next_health) / float(maxi(next_max_health, 1)), 0.0, 1.0)
		_animate_bar_to(true, health_ratio)
		_flash_fill(_health_fill, next_health < _displayed_health)
		_punch_label(_health_label)
	if block_changed:
		var block_ratio := clampf(float(next_block) / float(maxi(next_max_health, 1)), 0.0, 1.0)
		_animate_bar_to(false, block_ratio)
		_flash_fill(_block_fill, next_block > _displayed_block)
		_punch_label(_block_label)

	_displayed_health = next_health
	_displayed_max_health = next_max_health
	_displayed_block = next_block
	_bar_sequence_tween = create_tween()
	_bar_sequence_tween.tween_interval(0.34)
	_bar_sequence_tween.tween_callback(_on_bar_animation_stage_finished)


func _on_bar_animation_stage_finished() -> void:
	_bar_sequence_tween = null
	_start_next_bar_animation()


func _animate_bar_to(is_health: bool, target_ratio: float) -> void:
	var running_tween := _health_bar_tween if is_health else _block_bar_tween
	if running_tween and running_tween.is_running():
		running_tween.kill()

	var from_ratio := _shown_health_ratio if is_health else _shown_block_ratio
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_bar_ratio.bind(is_health), from_ratio, target_ratio, 0.45)
	if is_health:
		_health_bar_tween = tween
	else:
		_block_bar_tween = tween


func _set_bar_ratio(ratio: float, is_health: bool) -> void:
	if is_health:
		_shown_health_ratio = ratio
		_set_horizontal_fill(_health_fill, ratio)
	else:
		_shown_block_ratio = ratio
		_set_horizontal_fill(_block_fill, ratio)


func _flash_fill(fill: ColorRect, strong: bool) -> void:
	fill.modulate = Color(1.9, 1.9, 1.9) if strong else Color(1.45, 1.5, 1.6)
	var tween := fill.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(fill, "modulate", Color.WHITE, 0.40)


func _punch_label(label: Label) -> void:
	if not label or not label.visible:
		return
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2.ONE * 1.3
	var tween := label.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.32)


func _refresh_intent() -> void:
	if kind == Kind.PLAYER:
		_intent_badge.hide()
		_intent_icon.texture = null
		_intent_label.text = ""
		return

	_intent_badge.show()
	var enemy := combatant as Enemy
	if not enemy or not enemy.current_action or not enemy.current_action.intent:
		_intent_icon.texture = null
		_intent_label.text = ""
		return

	var intent := enemy.current_action.intent
	_intent_icon.texture = ICON_SHIELD if intent.category == Intent.Category.DEFEND else ICON_ATTACK
	var category_text := _intent_category_label(intent.category)
	var value_text := str(intent.current_text).strip_edges()
	var new_text := category_text if value_text.is_empty() else "%s %s" % [category_text, value_text]
	_intent_label.text = new_text

	# 意图变化（敌人换招）时徽章弹跳 + 闪亮，提醒玩家注意。
	if new_text != _last_intent_text:
		_last_intent_text = new_text
		_pop_intent_badge()


func _pop_intent_badge() -> void:
	if not _intent_badge:
		return
	if _intent_pop_tween and _intent_pop_tween.is_running():
		_intent_pop_tween.kill()

	_intent_badge.pivot_offset = _intent_badge.size * 0.5
	_intent_badge.scale = Vector2.ONE * 1.25
	_intent_badge.modulate = Color(1.55, 1.45, 1.3)
	_intent_pop_tween = _intent_badge.create_tween().set_parallel(true)
	_intent_pop_tween.tween_property(_intent_badge, "scale", Vector2.ONE, 0.36) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intent_pop_tween.tween_property(_intent_badge, "modulate", Color.WHITE, 0.46) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _refresh_statuses() -> void:
	var statuses: Array[Status] = []
	if status_handler:
		for status_ui in status_handler.get_children():
			var status := status_ui.get("status") as Status
			if status:
				statuses.append(status)

	# 每 0.12s 轮询会反复进来；只有状态集合/层数变化时才重建，否则出现动画活不过一帧。
	var previous_ids := {}
	var signature_parts: PackedStringArray = []
	for status in statuses:
		signature_parts.append("%s:%s" % [status.id, _status_value(status)])
	var signature := "|".join(signature_parts)
	if signature == _status_signature:
		return

	for part in _status_signature.split("|", false):
		previous_ids[part.get_slice(":", 0)] = part.get_slice(":", 1)
	_status_signature = signature

	for child in _status_row.get_children():
		child.queue_free()

	for status in statuses:
		var is_new: bool = not previous_ids.has(status.id)
		var stacks_changed: bool = not is_new and str(previous_ids[status.id]) != str(_status_value(status))
		_status_row.add_child(_make_status_chip(status, is_new, stacks_changed))


func _status_value(status: Status) -> int:
	return status.stacks if status.stack_type == Status.StackType.INTENSITY else status.duration


func _make_status_chip(status: Status, is_new := false, stacks_changed := false) -> Control:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_STOP
	chip.custom_minimum_size = Vector2(STATUS_CHIP_WIDTH, STATUS_CHIP_HEIGHT)
	chip.tooltip_text = _format_status_tooltip(status)
	chip.add_theme_stylebox_override("panel", InkTheme.make_style(
		Color(0.018, 0.014, 0.018, 0.82),
		Color(0.68, 0.52, 0.25, 0.78),
		1,
		6,
		Color(0, 0, 0, 0.42),
		8
	))

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_bottom", 3)
	chip.add_child(margin)

	var content := HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 3)
	margin.add_child(content)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(STATUS_ICON_SIZE, STATUS_ICON_SIZE)
	icon.texture = status.icon
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)

	var label := _make_label("Value", 18, Color("fff1c9"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(18, STATUS_ICON_SIZE)
	label.text = str(_status_value(status))
	content.add_child(label)

	if is_new:
		# 新词条：图标从小弹出 + 整体淡入。
		icon.pivot_offset = Vector2.ONE * (STATUS_ICON_SIZE * 0.5)
		icon.scale = Vector2.ONE * 0.2
		chip.modulate = Color(1, 1, 1, 0.0)
		var tween := chip.create_tween().set_parallel(true)
		tween.tween_property(icon, "scale", Vector2.ONE, 0.38) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(chip, "modulate:a", 1.0, 0.22)
	elif stacks_changed:
		# 层数变化：数字 punch。
		label.pivot_offset = Vector2(10, STATUS_ICON_SIZE * 0.5)
		label.scale = Vector2.ONE * 1.5
		var tween := label.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "scale", Vector2.ONE, 0.32)

	return chip


func _connect_stats() -> void:
	if stats and not stats.stats_changed.is_connected(_refresh):
		stats.stats_changed.connect(_refresh)


func _display_name() -> String:
	if stats is CharacterStats:
		return (stats as CharacterStats).character_name
	if stats is EnemyStats:
		return (stats as EnemyStats).display_name
	return ""


func _combatant_tooltip() -> String:
	var name := _display_name()
	var description_text := ""
	if stats is CharacterStats:
		description_text = (stats as CharacterStats).description
	elif stats is EnemyStats:
		description_text = (stats as EnemyStats).description
	return name if description_text.is_empty() else "%s\n%s" % [name, description_text]


func _portrait_texture() -> Texture2D:
	if stats is CharacterStats and (stats as CharacterStats).character_name == "魔修":
		return DEMONIC_CULTIVATOR_CARD
	if stats is EnemyStats:
		match (stats as EnemyStats).id:
			"paper_soldier":
				return PAPER_SOLDIER_CARD
			"mist_wolf":
				return MIST_WOLF_CARD
			"bull_demon":
				return BULL_DEMON_CARD
			"abyssal_sword_soul":
				return ABYSSAL_SWORD_SOUL_CARD
	if stats is CharacterStats and (stats as CharacterStats).portrait:
		return (stats as CharacterStats).portrait
	return stats.art if stats else null


func _set_horizontal_fill(fill: ColorRect, ratio: float) -> void:
	fill.visible = ratio > 0.001
	fill.anchor_left = 0.0
	fill.anchor_right = maxf(ratio, 0.001)
	fill.anchor_top = 0.0
	fill.anchor_bottom = 1.0
	fill.offset_left = 5.0
	fill.offset_top = 5.0
	fill.offset_right = -5.0
	fill.offset_bottom = -5.0


func _make_stat_bar(node_name: String, fill_color: Color, is_block := false) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", _make_bar_style(is_block))

	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.color = fill_color
	panel.add_child(fill)

	var label := _make_label("Label", 20, Color("fff2d0"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.add_child(label)
	return panel


func _layout_bar_label(label: Label, bar: Control) -> void:
	if not label or not bar:
		return

	label.rotation_degrees = 0.0
	label.position = Vector2.ZERO
	label.size = bar.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _format_status_tooltip(status: Status, override_value := -1) -> String:
	if not status:
		return ""
	var text := status.get_tooltip()
	if text.is_empty():
		return ""
	if text.contains("%s"):
		var value := override_value
		if value < 0:
			value = status.stacks if status.stack_type == Status.StackType.INTENSITY else status.duration
		text = text.replace("%s", str(value))
	return text.replace("%%", "%")


func _layout_intent_badge() -> void:
	if not _intent_badge:
		return

	var badge_size := _intent_badge.size
	_set_rect(_intent_icon, Vector2(16.0, badge_size.y * 0.5 - 16.0), Vector2(32.0, 32.0))
	_set_rect(_intent_label, Vector2(54.0, 0.0), Vector2(maxf(40.0, badge_size.x - 70.0), badge_size.y))


func _make_label(node_name: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.86))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _make_card_style() -> StyleBox:
	# The portrait already has its own frame. Keeping the full-card ornamental frame
	# around it made large combatant cards feel like two nested cards.
	return StyleBoxEmpty.new()


func _make_intent_style() -> StyleBox:
	return _make_texture_style(
		BATTLE_INTENT_BADGE,
		Vector4(42.0, 18.0, 42.0, 18.0),
		Vector4(12.0, 6.0, 12.0, 6.0),
		Color(1.04, 0.92, 0.82, 0.98)
	)


func _make_bar_style(is_block := false) -> StyleBox:
	var tint := Color(0.82, 0.92, 1.20, 0.96) if is_block else Color(1.10, 0.82, 0.72, 0.96)
	return _make_texture_style(
		BATTLE_HP_BAR_FRAME,
		Vector4(36.0, 10.0, 36.0, 10.0),
		Vector4(6.0, 4.0, 6.0, 4.0),
		tint
	)


func _make_texture_style(
	texture: Texture2D,
	texture_margins: Vector4,
	content_margins: Vector4,
	modulate_color := Color.WHITE
) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.draw_center = true
	style.modulate_color = modulate_color
	style.set_texture_margin(SIDE_LEFT, texture_margins.x)
	style.set_texture_margin(SIDE_TOP, texture_margins.y)
	style.set_texture_margin(SIDE_RIGHT, texture_margins.z)
	style.set_texture_margin(SIDE_BOTTOM, texture_margins.w)
	style.set_content_margin(SIDE_LEFT, content_margins.x)
	style.set_content_margin(SIDE_TOP, content_margins.y)
	style.set_content_margin(SIDE_RIGHT, content_margins.z)
	style.set_content_margin(SIDE_BOTTOM, content_margins.w)
	return style


func _set_rect(control: Control, position: Vector2, rect_size: Vector2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = position.x
	control.offset_top = position.y
	control.offset_right = position.x + rect_size.x
	control.offset_bottom = position.y + rect_size.y


func _intent_category_label(category: int) -> String:
	match category:
		Intent.Category.ATTACK, Intent.Category.MULTI_ATTACK:
			return "攻击"
		Intent.Category.DEFEND:
			return "防御"
		Intent.Category.ATTACK_DEFEND:
			return "攻防"
		Intent.Category.BUFF:
			return "强化"
		Intent.Category.DEBUFF:
			return "削弱"
		Intent.Category.CHARGE:
			return "蓄势"
		Intent.Category.SUMMON:
			return "召唤"
		Intent.Category.HEAL:
			return "疗愈"
		_:
			return "意图"
