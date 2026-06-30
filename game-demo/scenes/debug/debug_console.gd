class_name DebugConsole
extends CanvasLayer

const CARD_FUSION_LIBRARY := preload("res://fusion_recipes/card_fusion_library.tres")
const DEBUG_CONSOLE_STATE := preload("res://custom_resources/debug_console_state.gd")

var character_stats: CharacterStats
var run_stats: RunStats
var relic_handler: RelicHandler
var potion_handler: PotionHandler

var root: Control
var output: RichTextLabel
var input: LineEdit
var history: PackedStringArray = []

var card_library := {}
var relic_library := {}
var potion_library := {}


func _ready() -> void:
	layer = 90
	_build_ui()
	_scan_libraries()
	_log("调试控制台就绪。按 Ctrl+` 开关，输入 help 查看命令。")
	_hide_console()


func setup(
	new_character_stats: CharacterStats,
	new_run_stats: RunStats,
	new_relic_handler: RelicHandler,
	new_potion_handler: PotionHandler
) -> void:
	character_stats = new_character_stats
	run_stats = new_run_stats
	relic_handler = new_relic_handler
	potion_handler = new_potion_handler


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if key_event.ctrl_pressed and key_event.keycode == KEY_QUOTELEFT:
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if root.visible:
		_hide_console()
	else:
		_show_console()


func _show_console() -> void:
	root.show()
	input.grab_focus()


func _hide_console() -> void:
	root.hide()


func _build_ui() -> void:
	root = Control.new()
	root.name = "DebugConsoleRoot"
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = 22
	panel.offset_top = -492
	panel.offset_right = 822
	panel.offset_bottom = -22
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var title := Label.new()
	title.text = "调试控制台  Ctrl+`"
	InkTheme.apply_screen_title(title, 22)
	box.add_child(title)

	output = RichTextLabel.new()
	output.custom_minimum_size = Vector2(760, 350)
	output.bbcode_enabled = false
	output.fit_content = false
	output.scroll_following = true
	output.add_theme_font_size_override("normal_font_size", 17)
	output.add_theme_color_override("default_color", Color("efe6d0"))
	box.add_child(output)

	input = LineEdit.new()
	input.placeholder_text = "输入命令，例如：card add demon_strike 2 / hp set 80 / next dealt set 30"
	input.text_submitted.connect(_on_command_submitted)
	input.add_theme_font_size_override("font_size", 18)
	input.add_theme_color_override("font_color", Color("f4e6c6"))
	input.add_theme_color_override("font_placeholder_color", Color(0.72, 0.62, 0.48, 0.78))
	input.add_theme_stylebox_override("normal", InkTheme.make_style(Color(0.030, 0.020, 0.020, 0.92), Color(0.52, 0.36, 0.18, 0.84), 1, 4))
	input.add_theme_stylebox_override("focus", InkTheme.make_style(Color(0.050, 0.030, 0.028, 0.96), Color("f2c94f"), 1, 4, Color(0.70, 0.24, 0.10, 0.18), 8))
	box.add_child(input)


func _on_command_submitted(command: String) -> void:
	var trimmed := command.strip_edges()
	input.clear()
	if trimmed.is_empty():
		return

	_log("> %s" % trimmed)
	_execute_command(trimmed)


func _execute_command(command: String) -> void:
	var tokens := command.split(" ", false)
	if tokens.is_empty():
		return

	var root_command := tokens[0].to_lower()
	var args := tokens.slice(1)
	match root_command:
		"help", "?":
			_log_help()
		"deck":
			_log_deck()
		"cards":
			_log_library(card_library, args)
		"card":
			_cmd_card(args)
		"hp", "health":
			_cmd_hp(args)
		"gold":
			_cmd_gold(args)
		"relic":
			_cmd_relic(args)
		"potion":
			_cmd_potion(args)
		"next":
			_cmd_next(args)
		"clear":
			history.clear()
			output.text = ""
		_:
			_log("未知命令：%s。输入 help 查看命令。" % root_command)


func _cmd_card(args: PackedStringArray) -> void:
	if args.is_empty():
		_log("用法：card add/remove/upgrade/fuse ...")
		return

	match args[0].to_lower():
		"add":
			if args.size() < 2:
				_log("用法：card add <id> [数量]")
				return
			var card := _find_card_resource(args[1])
			if not card:
				_log("未找到卡牌：%s" % args[1])
				return
			var count := _optional_int(args, 2, 1)
			for _i in count:
				character_stats.deck.add_card(card.duplicate(true))
			_log("已加入卡牌：%s x%s" % [card.get_display_name(), count])
		"remove", "del", "delete":
			if args.size() < 2:
				_log("用法：card remove <id或序号> [数量]")
				return
			var count := _optional_int(args, 2, 1)
			var removed := 0
			for _i in count:
				var card := _find_deck_card(args[1])
				if not card:
					break
				if character_stats.deck.remove_card(card):
					removed += 1
			_log("已删除卡牌 %s 张。" % removed)
		"upgrade":
			if args.size() < 2:
				_log("用法：card upgrade <id或序号> [数量]")
				return
			var count := _optional_int(args, 2, 1)
			var upgraded := 0
			for _i in count:
				var card := _find_deck_card(args[1], [], true)
				if not card:
					break
				if card.upgrade():
					upgraded += 1
			_log("已突破卡牌 %s 张。" % upgraded)
		"fuse":
			if args.size() < 3:
				_log("用法：card fuse <id或序号A> <id或序号B>")
				return
			var card_a := _find_deck_card(args[1])
			var card_b := _find_deck_card(args[2], [card_a])
			if not card_a or not card_b:
				_log("融合失败：找不到两张可用卡牌。")
				return
			var result := CARD_FUSION_LIBRARY.fuse(character_stats.deck, card_a, card_b)
			if result:
				_log("融合成功：%s" % result.get_display_name())
			else:
				_log("融合失败：%s" % CARD_FUSION_LIBRARY.get_fusion_message(card_a, card_b))
		"list":
			_log_deck()
		_:
			_log("未知 card 子命令。")

	_emit_character_changed()


func _cmd_hp(args: PackedStringArray) -> void:
	if args.size() < 2 or not character_stats:
		_log("用法：hp set/add/damage/heal/max <数值>")
		return

	var amount := args[1].to_int()
	match args[0].to_lower():
		"set":
			character_stats.health = amount
		"add", "heal":
			character_stats.heal(amount)
		"damage":
			character_stats.health = maxi(1, character_stats.health - amount)
		"max":
			character_stats.max_health = amount
		_:
			_log("未知 hp 子命令。")
			return
	_log("当前生命：%s/%s" % [character_stats.health, character_stats.max_health])


func _cmd_gold(args: PackedStringArray) -> void:
	if args.size() < 2 or not run_stats:
		_log("用法：gold set/add/remove <数值>")
		return

	var amount := args[1].to_int()
	match args[0].to_lower():
		"set":
			run_stats.gold = amount
		"add":
			run_stats.gold += amount
		"remove", "sub":
			run_stats.gold = maxi(0, run_stats.gold - amount)
		_:
			_log("未知 gold 子命令。")
			return
	_log("当前金币：%s" % run_stats.gold)


func _cmd_relic(args: PackedStringArray) -> void:
	if args.is_empty():
		_log("用法：relic list/add/remove <id>")
		return

	match args[0].to_lower():
		"list":
			_log_relics()
		"add":
			if args.size() < 2:
				_log("用法：relic add <id>")
				return
			var relic := _find_relic_resource(args[1])
			if not relic:
				_log("未找到法宝：%s" % args[1])
				return
			relic_handler.add_relic(relic)
			_log("已加入法宝：%s" % relic.relic_name)
		"remove", "del", "delete":
			if args.size() < 2:
				_log("用法：relic remove <id>")
				return
			relic_handler.remove_relic(args[1])
			_log("已尝试删除法宝：%s" % args[1])
		_:
			_log("未知 relic 子命令。")


func _cmd_potion(args: PackedStringArray) -> void:
	if args.is_empty():
		_log("用法：potion list/add/remove/clear <id或序号>")
		return

	match args[0].to_lower():
		"list":
			_log_potions()
		"add":
			if args.size() < 2:
				_log("用法：potion add <id>")
				return
			var potion := _find_potion_resource(args[1])
			if not potion:
				_log("未找到丹药/符箓：%s" % args[1])
				return
			if potion_handler.add_potion(potion):
				_log("已加入：%s" % potion.potion_name)
			else:
				_log("丹药栏已满。")
		"remove", "del", "delete":
			if args.size() < 2:
				_log("用法：potion remove <id或序号>")
				return
			_log("删除丹药：%s" % ("成功" if _remove_potion(args[1]) else "未找到"))
		"clear":
			for ui: PotionUI in potion_handler.get_children():
				ui.clear_potion()
			_log("丹药栏已清空。")
		_:
			_log("未知 potion 子命令。")


func _cmd_next(args: PackedStringArray) -> void:
	if args.is_empty():
		_log(DEBUG_CONSOLE_STATE.describe())
		return

	if args[0].to_lower() == "clear":
		DEBUG_CONSOLE_STATE.clear_all()
		_log("已清除下一次伤害设置。")
		return

	if args.size() < 2:
		_log("用法：next dealt/taken [set/add] <数值>")
		return

	var target := args[0].to_lower()
	var mode := DEBUG_CONSOLE_STATE.DamageEditMode.SET
	var amount_index := 1
	if args[1].to_lower() == "add":
		mode = DEBUG_CONSOLE_STATE.DamageEditMode.ADD
		amount_index = 2
	elif args[1].to_lower() == "set":
		mode = DEBUG_CONSOLE_STATE.DamageEditMode.SET
		amount_index = 2
	if args.size() <= amount_index:
		_log("缺少数值。")
		return

	var amount := args[amount_index].to_int()
	match target:
		"dealt", "damage", "out":
			DEBUG_CONSOLE_STATE.set_next_dealt(mode, amount)
		"taken", "incoming", "in":
			DEBUG_CONSOLE_STATE.set_next_taken(mode, amount)
		_:
			_log("未知 next 目标：%s" % target)
			return
	_log(DEBUG_CONSOLE_STATE.describe())


func _scan_libraries() -> void:
	card_library.clear()
	relic_library.clear()
	potion_library.clear()
	_scan_cards("res://common_cards")
	_scan_cards("res://characters")
	_scan_cards("res://fusion_cards")
	_scan_relics("res://relics")
	_scan_potions("res://potions")


func _scan_cards(folder: String) -> void:
	_scan_folder(folder, func(resource):
		if resource is Card:
			_register_resource(card_library, resource, [resource.id, resource.display_name])
	)


func _scan_relics(folder: String) -> void:
	_scan_folder(folder, func(resource):
		if resource is Relic:
			_register_resource(relic_library, resource, [resource.id, resource.relic_name])
	)


func _scan_potions(folder: String) -> void:
	_scan_folder(folder, func(resource):
		if resource is Potion:
			_register_resource(potion_library, resource, [resource.id, resource.potion_name])
	)


func _scan_folder(folder: String, visitor: Callable) -> void:
	var dir := DirAccess.open(folder)
	if not dir:
		return

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name.is_empty():
			break
		if file_name.begins_with("."):
			continue

		var path := folder.path_join(file_name)
		if dir.current_is_dir():
			_scan_folder(path, visitor)
		elif file_name.ends_with(".tres"):
			var resource := ResourceLoader.load(path)
			if resource:
				visitor.call(resource)
	dir.list_dir_end()


func _register_resource(library: Dictionary, resource: Resource, keys: Array) -> void:
	keys.append(resource.resource_path.get_file().get_basename())
	for raw_key in keys:
		var key := str(raw_key).strip_edges().to_lower()
		if key.is_empty():
			continue
		if not library.has(key):
			library[key] = resource


func _find_card_resource(query: String) -> Card:
	return card_library.get(query.to_lower()) as Card


func _find_relic_resource(query: String) -> Relic:
	return relic_library.get(query.to_lower()) as Relic


func _find_potion_resource(query: String) -> Potion:
	return potion_library.get(query.to_lower()) as Potion


func _find_deck_card(query: String, excluded: Array = [], require_upgradeable := false) -> Card:
	if not character_stats or not character_stats.deck:
		return null

	if query.is_valid_int():
		var index := query.to_int()
		if index >= 0 and index < character_stats.deck.cards.size():
			var indexed := character_stats.deck.cards[index]
			if not excluded.has(indexed) and (not require_upgradeable or indexed.can_upgrade()):
				return indexed

	var key := query.to_lower()
	for card: Card in character_stats.deck.cards:
		if not card or excluded.has(card):
			continue
		if require_upgradeable and not card.can_upgrade():
			continue
		if card.id.to_lower() == key or card.display_name.to_lower() == key:
			return card
	return null


func _remove_potion(query: String) -> bool:
	if query.is_valid_int():
		var index := query.to_int()
		if index >= 0 and index < potion_handler.get_child_count():
			var indexed := potion_handler.get_child(index) as PotionUI
			if indexed and indexed.potion:
				indexed.clear_potion()
				return true

	var key := query.to_lower()
	for ui: PotionUI in potion_handler.get_children():
		if ui.potion and (ui.potion.id.to_lower() == key or ui.potion.potion_name.to_lower() == key):
			ui.clear_potion()
			return true
	return false


func _log_deck() -> void:
	if not character_stats or not character_stats.deck:
		_log("当前没有牌组。")
		return

	var lines: PackedStringArray = ["牌组："]
	for i in character_stats.deck.cards.size():
		var card := character_stats.deck.cards[i]
		lines.append("[%s] %s  %s" % [i, card.id, card.get_display_name()])
	_log("\n".join(lines))


func _log_relics() -> void:
	var lines: PackedStringArray = ["当前法宝："]
	for relic: Relic in relic_handler.get_all_relics():
		lines.append("%s  %s" % [relic.id, relic.relic_name])
	_log("\n".join(lines))


func _log_potions() -> void:
	var lines: PackedStringArray = ["当前丹药/符箓："]
	for i in potion_handler.get_child_count():
		var ui := potion_handler.get_child(i) as PotionUI
		if ui and ui.potion:
			lines.append("[%s] %s  %s" % [i, ui.potion.id, ui.potion.potion_name])
		else:
			lines.append("[%s] 空" % i)
	_log("\n".join(lines))


func _log_library(library: Dictionary, args: PackedStringArray) -> void:
	var filter := args[0].to_lower() if not args.is_empty() else ""
	var keys := library.keys()
	keys.sort()
	var lines: PackedStringArray = []
	var shown := 0
	for key in keys:
		if not filter.is_empty() and not str(key).contains(filter):
			continue
		lines.append(str(key))
		shown += 1
		if shown >= 60:
			lines.append("... 结果过多，请加筛选词。")
			break
	_log("\n".join(lines) if not lines.is_empty() else "没有匹配资源。")


func _log_help() -> void:
	_log("\n".join(PackedStringArray([
		"命令：",
		"deck / cards [筛选]",
		"card add <id> [数量]",
		"card remove <id或序号> [数量]",
		"card upgrade <id或序号> [数量]",
		"card fuse <id或序号A> <id或序号B>",
		"hp set/add/heal/damage/max <数值>",
		"gold set/add/remove <数值>",
		"relic list/add/remove <id>",
		"potion list/add/remove/clear <id或序号>",
		"next dealt set/add <数值>",
		"next taken set/add <数值>",
		"next clear",
	])))


func _optional_int(args: PackedStringArray, index: int, fallback: int) -> int:
	if args.size() <= index:
		return fallback
	return maxi(args[index].to_int(), 1)


func _emit_character_changed() -> void:
	if character_stats:
		character_stats.stats_changed.emit()


func _log(text: String) -> void:
	history.append(text)
	while history.size() > 120:
		history.remove_at(0)
	output.text = "\n".join(history)


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.030, 0.020, 0.020, 0.96)
	style.border_color = Color(0.70, 0.48, 0.24, 0.9)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 14
	return style
