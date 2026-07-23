class_name DebugConsole
extends CanvasLayer

const CARD_FUSION_LIBRARY := preload("res://fusion_recipes/card_fusion_library.tres")
const DEBUG_CONSOLE_STATE := preload("res://custom_resources/debug_console_state.gd")
const EVENT_ROOM_POOL := preload("res://scenes/event_rooms/event_room_pool.tres")
const COMMAND_HINTS := [
	"help", "status", "deck", "cards", "card add", "card remove", "card upgrade", "card fuse",
	"hand list", "hand add", "hand draw", "hand discard", "hand clear",
	"hp set", "hp heal", "hp damage", "hp max", "block set", "block add", "block clear",
	"mana set", "mana add", "mana fill", "gold set", "gold add", "gold remove",
	"relic list", "relic library", "relic add", "relic remove",
	"potion list", "potion library", "potion add", "potion remove", "potion clear",
	"enemy list", "enemy damage", "enemy kill", "enemy intent",
	"turn status", "turn unlock", "turn end", "map status", "map unlock", "map free", "map show",
	"event list", "event open", "event random", "difficulty set", "next dealt", "next taken",
	"next clear", "reload", "save", "clear",
]

var character_stats: CharacterStats
var run_stats: RunStats
var relic_handler: RelicHandler
var potion_handler: PotionHandler
var run_node: Node

var root: Control
var output: RichTextLabel
var input: LineEdit
var history: PackedStringArray = []
var command_history: PackedStringArray = []
var command_history_index := 0

var card_library := {}
var relic_library := {}
var potion_library := {}
var event_library := {}
var event_entries: Array[Dictionary] = []


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
	new_potion_handler: PotionHandler,
	new_run_node: Node = null
) -> void:
	character_stats = new_character_stats
	run_stats = new_run_stats
	relic_handler = new_relic_handler
	potion_handler = new_potion_handler
	run_node = new_run_node


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
	input.gui_input.connect(_on_input_gui_input)
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
	if command_history.is_empty() or command_history[-1] != trimmed:
		command_history.append(trimmed)
		while command_history.size() > 80:
			command_history.remove_at(0)
	command_history_index = command_history.size()

	_log("> %s" % trimmed)
	_execute_command(trimmed)


func _execute_command(command: String) -> void:
	var tokens := command.split(" ", false)
	if tokens.is_empty():
		return

	var root_command := _normalize_root_command(tokens[0])
	var args := tokens.slice(1)
	match root_command:
		"help", "?":
			_log_help()
		"deck":
			_log_deck()
		"cards":
			_log_card_library(args)
		"card":
			_cmd_card(args)
		"hand":
			_cmd_hand(args)
		"hp", "health":
			_cmd_hp(args)
		"block":
			_cmd_block(args)
		"mana":
			_cmd_mana(args)
		"gold":
			_cmd_gold(args)
		"relic":
			_cmd_relic(args)
		"potion":
			_cmd_potion(args)
		"enemy":
			_cmd_enemy(args)
		"turn":
			_cmd_turn(args)
		"map":
			_cmd_map(args)
		"event":
			_cmd_event(args)
		"difficulty":
			_cmd_difficulty(args)
		"next":
			_cmd_next(args)
		"status":
			_log_status()
		"reload":
			_scan_libraries()
			_log("资源索引已刷新：卡牌 %d、法宝 %d、丹药/符箓 %d、事件 %d。" % [
				_unique_resource_count(card_library),
				_unique_resource_count(relic_library),
				_unique_resource_count(potion_library),
				event_entries.size(),
			])
		"save":
			_cmd_save()
		"clear":
			history.clear()
			output.text = ""
		_:
			_log("未知命令：%s。输入 help 查看命令。" % root_command)


func _on_input_gui_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.ctrl_pressed and key_event.keycode == KEY_QUOTELEFT:
		_hide_console()
		input.accept_event()
		return
	match key_event.keycode:
		KEY_ESCAPE:
			_hide_console()
			input.accept_event()
		KEY_UP:
			_navigate_command_history(-1)
			input.accept_event()
		KEY_DOWN:
			_navigate_command_history(1)
			input.accept_event()
		KEY_TAB:
			_complete_command()
			input.accept_event()
		KEY_L:
			if key_event.ctrl_pressed:
				history.clear()
				output.text = ""
				input.accept_event()


func _navigate_command_history(direction: int) -> void:
	if command_history.is_empty():
		return
	command_history_index = clampi(command_history_index + direction, 0, command_history.size())
	input.text = "" if command_history_index == command_history.size() else command_history[command_history_index]
	input.caret_column = input.text.length()


func _complete_command() -> void:
	var prefix := input.text.strip_edges().to_lower()
	if prefix.is_empty():
		_log("可用命令：%s" % " / ".join(COMMAND_HINTS.slice(0, 12)))
		return
	var matches := PackedStringArray()
	for raw_hint in COMMAND_HINTS:
		var hint := str(raw_hint)
		if hint.begins_with(prefix):
			matches.append(hint)
	if matches.size() == 1:
		input.text = matches[0] + " "
		input.caret_column = input.text.length()
	elif not matches.is_empty():
		_log("补全候选：%s" % " / ".join(matches))


func _cmd_card(args: PackedStringArray) -> void:
	if not character_stats or not character_stats.deck:
		_log("当前没有可操作的角色牌组。")
		return
	if args.is_empty():
		_log("用法：card add/remove/upgrade/fuse ...")
		return

	match _normalize_subcommand(args[0]):
		"add":
			if args.size() < 2:
				_log("用法：card add <id> [数量]")
				return
			var card := _find_card_resource_fuzzy(args[1])
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
				if card.can_be_removed_from_deck() and character_stats.deck.remove_card(card):
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
	match _normalize_subcommand(args[0]):
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
	_emit_character_changed()


func _cmd_block(args: PackedStringArray) -> void:
	if args.is_empty() or not character_stats:
		_log("用法：block set/add/clear <数值>")
		return
	var action := _normalize_subcommand(args[0])
	var amount := args[1].to_int() if args.size() >= 2 else 0
	match action:
		"set":
			character_stats.block = amount
		"add":
			character_stats.block += amount
		"clear":
			character_stats.block = 0
		_:
			_log("未知 block 子命令。")
			return
	_log("当前护体：%s" % character_stats.block)


func _cmd_mana(args: PackedStringArray) -> void:
	if args.is_empty() or not character_stats:
		_log("用法：mana set/add/fill <数值>")
		return
	var action := _normalize_subcommand(args[0])
	var amount := args[1].to_int() if args.size() >= 2 else 0
	match action:
		"set":
			character_stats.mana = maxi(amount, 0)
		"add":
			character_stats.mana = maxi(character_stats.mana + amount, 0)
		"fill":
			character_stats.reset_mana()
		_:
			_log("未知 mana 子命令。")
			return
	_log("当前灵力：%s/%s" % [character_stats.mana, character_stats.max_mana])


func _cmd_gold(args: PackedStringArray) -> void:
	if args.size() < 2 or not run_stats:
		_log("用法：gold set/add/remove <数值>")
		return

	var amount := args[1].to_int()
	match _normalize_subcommand(args[0]):
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
	if not relic_handler:
		_log("当前没有可操作的法宝栏。")
		return
	if args.is_empty():
		_log("用法：relic list/add/remove <id>")
		return

	match _normalize_subcommand(args[0]):
		"list":
			_log_relics()
		"library":
			_log_named_resource_library(relic_library, args.slice(1), "法宝")
		"add":
			if args.size() < 2:
				_log("用法：relic add <id>")
				return
			var relic := _find_relic_resource_fuzzy(args[1])
			if not relic:
				_log("未找到法宝：%s" % args[1])
				return
			relic_handler.add_relic(relic)
			_log("已加入法宝：%s" % relic.relic_name)
		"remove", "del", "delete":
			if args.size() < 2:
				_log("用法：relic remove <id>")
				return
			var query := args[1].to_lower()
			var removed_id := ""
			for owned: Relic in relic_handler.get_all_relics():
				if owned.id.to_lower() == query or owned.relic_name.to_lower() == query:
					removed_id = owned.id
					break
			if removed_id.is_empty():
				_log("未持有法宝：%s" % args[1])
				return
			relic_handler.remove_relic(removed_id)
			_log("已删除法宝：%s" % removed_id)
		_:
			_log("未知 relic 子命令。")


func _cmd_potion(args: PackedStringArray) -> void:
	if not potion_handler:
		_log("当前没有可操作的丹药栏。")
		return
	if args.is_empty():
		_log("用法：potion list/add/remove/clear <id或序号>")
		return

	match _normalize_subcommand(args[0]):
		"list":
			_log_potions()
		"library":
			_log_named_resource_library(potion_library, args.slice(1), "丹药/符箓")
		"add":
			if args.size() < 2:
				_log("用法：potion add <id>")
				return
			var potion := _find_potion_resource_fuzzy(args[1])
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

	if _normalize_subcommand(args[0]) == "clear":
		DEBUG_CONSOLE_STATE.clear_all()
		_log("已清除下一次伤害设置。")
		return

	if args.size() < 2:
		_log("用法：next dealt/taken [set/add] <数值>")
		return

	var target := _normalize_damage_target(args[0])
	var mode := DEBUG_CONSOLE_STATE.DamageEditMode.SET
	var amount_index := 1
	if _normalize_subcommand(args[1]) == "add":
		mode = DEBUG_CONSOLE_STATE.DamageEditMode.ADD
		amount_index = 2
	elif _normalize_subcommand(args[1]) == "set":
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


func _cmd_hand(args: PackedStringArray) -> void:
	var handler := _player_handler()
	if not handler or not handler.hand:
		_log("当前不在战斗中，无法操作手牌。")
		return
	var action := _normalize_subcommand(args[0]) if not args.is_empty() else "list"
	match action:
		"list":
			_log_hand(handler.hand)
		"add":
			if args.size() < 2:
				_log("用法：hand add <卡牌ID或中文名> [数量]")
				return
			var card := _find_card_resource_fuzzy(args[1])
			if not card:
				_log("未找到卡牌：%s" % args[1])
				return
			var count := _optional_int(args, 2, 1)
			var added := 0
			for _i in count:
				var copy := card.duplicate(true) as Card
				copy.bind_spirit_root_owner(character_stats)
				if not handler.hand.add_card(copy, false):
					break
				added += 1
			_log("已将「%s」加入手牌 %d 张。" % [card.get_display_name(), added])
		"draw":
			var count := _optional_int(args, 1, 1)
			handler.draw_cards(count)
			_log("已请求抽牌 %d 张。" % count)
		"discard":
			if args.size() < 2:
				_log("用法：hand discard <all|序号|卡牌ID>")
				return
			var targets := _select_hand_cards(handler.hand, args[1])
			for card_ui: CardUI in targets:
				handler.discard_card_from_hand(card_ui, false)
			_log("已弃置手牌 %d 张。" % targets.size())
		"clear":
			var targets := _hand_card_uis(handler.hand)
			for card_ui: CardUI in targets:
				handler.remove_card_from_hand(card_ui)
			_log("已清空手牌（不触发弃置效果）。")
		_:
			_log("用法：hand list/add/draw/discard/clear ...")


func _cmd_enemy(args: PackedStringArray) -> void:
	var enemies := _live_enemies()
	var action := _normalize_subcommand(args[0]) if not args.is_empty() else "list"
	if action == "list":
		_log_enemies(enemies)
		return
	if enemies.is_empty():
		_log("当前战斗中没有存活敌人。")
		return
	match action:
		"damage":
			if args.size() < 3:
				_log("用法：enemy damage <all|序号> <数值>")
				return
			var targets := _select_enemies(enemies, args[1])
			var amount := maxi(args[2].to_int(), 0)
			for enemy: Enemy in targets:
				enemy.take_damage(amount, Modifier.Type.DMG_TAKEN)
			_log("已对 %d 个敌人造成调试伤害 %d。" % [targets.size(), amount])
		"kill":
			if args.size() < 2:
				_log("用法：enemy kill <all|序号>")
				return
			var targets := _select_enemies(enemies, args[1])
			for enemy: Enemy in targets:
				enemy.take_damage(999999, Modifier.Type.DMG_TAKEN)
			_log("已击杀敌人 %d 个。" % targets.size())
		"intent":
			for enemy: Enemy in enemies:
				enemy.current_action = null
				enemy.update_action()
			_log("已重新生成全部敌人意图。")
		_:
			_log("用法：enemy list/damage/kill/intent ...")


func _cmd_turn(args: PackedStringArray) -> void:
	var handler := _player_handler()
	if not handler:
		_log("当前不在战斗中。")
		return
	var action := _normalize_subcommand(args[0]) if not args.is_empty() else "status"
	match action:
		"status":
			_log("回合状态：战斗=%s，玩家操作=%s，抽牌动画=%s，弃牌动画=%s" % [
				"运行中" if handler.battle_running else "已停止",
				"已解锁" if handler.player_actions_enabled else "已锁定",
				"运行中" if handler.draw_tween and handler.draw_tween.is_running() else "无",
				"运行中" if handler.discard_tween and handler.discard_tween.is_running() else "无",
			])
		"unlock":
			if not handler.battle_running:
				_log("战斗未运行，不能解锁玩家操作。")
				return
			handler.player_actions_enabled = true
			if handler.hand:
				handler.hand.enable_hand()
			_log("已恢复玩家操作与结束回合按钮。")
		"end":
			if not handler.battle_running or not handler.player_actions_enabled:
				_log("当前不能结束回合；可先用 turn unlock 检查恢复。")
				return
			handler.player_actions_enabled = false
			Events.player_turn_ended.emit()
			_log("已结束玩家回合。")
		_:
			_log("用法：turn status/unlock/end")


func _cmd_map(args: PackedStringArray) -> void:
	var map_node := _run_map()
	if not map_node:
		_log("当前没有可用地图。")
		return
	var action := _normalize_subcommand(args[0]) if not args.is_empty() else "status"
	match action:
		"status":
			_log("地图：第 %d/%d 层，自由导航=%s，当前显示=%s" % [
				map_node.floors_climbed,
				map_node.get_floor_count(),
				"开" if map_node.free_navigation else "关",
				"是" if map_node.visible else "否",
			])
		"unlock":
			var target := args[1].to_lower() if args.size() >= 2 else "current"
			if target in ["all", "全部"]:
				map_node.call("_unlock_all_rooms")
				_log("已解锁地图全部节点。")
			else:
				var floor_index := map_node.floors_climbed
				if target.is_valid_int():
					floor_index = clampi(target.to_int(), 0, map_node.get_floor_count() - 1)
				map_node.unlock_floor(floor_index)
				_log("已解锁地图第 %d 层节点。" % floor_index)
		"free":
			if args.size() < 2:
				_log("用法：map free on/off")
				return
			map_node.free_navigation = _parse_toggle(args[1], map_node.free_navigation)
			if map_node.free_navigation:
				map_node.call("_unlock_all_rooms")
			_log("地图自由导航：%s" % ("开启" if map_node.free_navigation else "关闭"))
		"show":
			if run_node and run_node.has_method("_show_map"):
				run_node.call("_show_map")
				_log("已返回地图。")
				_hide_console()
		_:
			_log("用法：map status/unlock/free/show ...")


func _cmd_event(args: PackedStringArray) -> void:
	var action := _normalize_subcommand(args[0]) if not args.is_empty() else "list"
	match action:
		"list":
			_log_event_library(args.slice(1))
		"open":
			if args.size() < 2:
				_log("用法：event open <事件ID或中文标题>")
				return
			var scene := _find_event_scene(args[1])
			if not scene:
				_log("未找到事件：%s；可用 event list 筛选。" % args[1])
				return
			_open_event(scene)
		"random":
			var chapter := _optional_int(args, 1, _current_chapter())
			var scenes: Array[PackedScene] = EVENT_ROOM_POOL.get_chapter_rooms(clampi(chapter, 1, 3))
			var scene := RNG.array_pick_random(scenes) as PackedScene
			_open_event(scene)
		_:
			_log("用法：event list/open/random ...")


func _cmd_difficulty(args: PackedStringArray) -> void:
	if not run_stats:
		_log("当前没有轮回数据。")
		return
	if args.is_empty():
		_log("当前难度：%s（%s）" % [run_stats.get_difficulty_name(), RunStats.get_difficulty_rule(run_stats.difficulty_level)])
		return
	if _normalize_subcommand(args[0]) != "set" or args.size() < 2:
		_log("用法：difficulty set <0-%d>" % RunStats.MAX_DIFFICULTY_LEVEL)
		return
	run_stats.configure_difficulty(args[1].to_int(), false)
	_log("难度已设为：%s（只影响之后生成的敌人与房间）。" % run_stats.get_difficulty_name())


func _cmd_save() -> void:
	if not run_node or not run_node.has_method("_save_run"):
		_log("当前轮回尚未初始化，无法保存。")
		return
	var map_node := _run_map()
	run_node.call("_save_run", map_node.visible if map_node else false)
	_log("当前轮回已手动保存。")


func _scan_libraries() -> void:
	card_library.clear()
	relic_library.clear()
	potion_library.clear()
	event_library.clear()
	event_entries.clear()
	_scan_cards("res://common_cards")
	_scan_cards("res://characters")
	_scan_cards("res://fusion_cards")
	_scan_relics("res://relics")
	_scan_potions("res://potions")
	_scan_events()


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


func _scan_events() -> void:
	for chapter in range(1, 4):
		for scene: PackedScene in EVENT_ROOM_POOL.get_chapter_rooms(chapter):
			if not scene:
				continue
			var path := scene.resource_path
			if event_entries.any(func(entry: Dictionary): return entry.get("path", "") == path):
				continue
			var event_instance := scene.instantiate() as GenericEvent
			var title := event_instance.event_title if event_instance else path.get_file().get_basename()
			if event_instance:
				event_instance.free()
			var event_id := path.get_file().get_basename().trim_suffix("_event")
			var entry := {"id": event_id, "title": title, "chapter": chapter, "path": path, "scene": scene}
			event_entries.append(entry)
			for raw_key in [event_id, path.get_file().get_basename(), title]:
				var key := str(raw_key).strip_edges().to_lower()
				if not key.is_empty() and not event_library.has(key):
					event_library[key] = scene


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


func _find_card_resource_fuzzy(query: String) -> Card:
	return _find_resource_fuzzy(card_library, query) as Card


func _find_relic_resource(query: String) -> Relic:
	return relic_library.get(query.to_lower()) as Relic


func _find_relic_resource_fuzzy(query: String) -> Relic:
	return _find_resource_fuzzy(relic_library, query) as Relic


func _find_potion_resource(query: String) -> Potion:
	return potion_library.get(query.to_lower()) as Potion


func _find_potion_resource_fuzzy(query: String) -> Potion:
	return _find_resource_fuzzy(potion_library, query) as Potion


func _find_resource_fuzzy(library: Dictionary, query: String) -> Resource:
	var key := query.strip_edges().to_lower()
	if library.has(key):
		return library[key] as Resource
	var matches: Array[Resource] = []
	var seen := {}
	for alias in library:
		if not str(alias).contains(key):
			continue
		var resource := library[alias] as Resource
		if resource and not seen.has(resource.resource_path):
			seen[resource.resource_path] = true
			matches.append(resource)
	return matches[0] if matches.size() == 1 else null


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
	if not relic_handler:
		_log("当前没有法宝栏。")
		return
	var lines: PackedStringArray = ["当前法宝："]
	for relic: Relic in relic_handler.get_all_relics():
		lines.append("%s  %s" % [relic.id, relic.relic_name])
	_log("\n".join(lines))


func _log_potions() -> void:
	if not potion_handler:
		_log("当前没有丹药栏。")
		return
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


func _log_card_library(args: PackedStringArray) -> void:
	var filter := " ".join(args).to_lower()
	var cards: Array[Card] = []
	var seen := {}
	for value in card_library.values():
		var card := value as Card
		if not card or seen.has(card.resource_path):
			continue
		seen[card.resource_path] = true
		var searchable := "%s %s %s" % [card.id, card.get_display_name(), card.description]
		if not filter.is_empty() and not searchable.to_lower().contains(filter):
			continue
		cards.append(card)
	cards.sort_custom(func(a: Card, b: Card): return a.id.naturalnocasecmp_to(b.id) < 0)
	var lines := PackedStringArray(["卡牌库（ID | 名称 | 费用 | 类型/元素 | 关键词）："])
	for card: Card in cards.slice(0, 60):
		var keywords := "、".join(card.get_keyword_labels())
		lines.append("%s | %s | %d | %s/%s | %s" % [
			card.id, card.get_display_name(), card.cost, _card_type_name(card.type), card.get_element_name(),
			keywords if not keywords.is_empty() else "无",
		])
	if cards.size() > 60:
		lines.append("... 共 %d 条，请加筛选词。" % cards.size())
	_log("\n".join(lines) if cards.size() > 0 else "没有匹配卡牌。")


func _log_named_resource_library(library: Dictionary, args: PackedStringArray, label: String) -> void:
	var filter := " ".join(args).to_lower()
	var resources: Array[Resource] = []
	var seen := {}
	for value in library.values():
		var resource := value as Resource
		if not resource or seen.has(resource.resource_path):
			continue
		seen[resource.resource_path] = true
		var id := str(resource.get("id"))
		var display_name := str(resource.get("relic_name")) if resource is Relic else str(resource.get("potion_name"))
		if not filter.is_empty() and not ("%s %s" % [id, display_name]).to_lower().contains(filter):
			continue
		resources.append(resource)
	resources.sort_custom(func(a: Resource, b: Resource): return str(a.get("id")).naturalnocasecmp_to(str(b.get("id"))) < 0)
	var lines := PackedStringArray(["%s库（ID | 名称）：" % label])
	for resource: Resource in resources.slice(0, 60):
		var display_name := str(resource.get("relic_name")) if resource is Relic else str(resource.get("potion_name"))
		lines.append("%s | %s" % [resource.get("id"), display_name])
	if resources.size() > 60:
		lines.append("... 共 %d 条，请加筛选词。" % resources.size())
	_log("\n".join(lines) if resources.size() > 0 else "没有匹配%s。" % label)


func _log_event_library(args: PackedStringArray) -> void:
	var filter := " ".join(args).to_lower()
	var chapter_filter := filter.to_int() if filter.is_valid_int() else 0
	var lines := PackedStringArray(["事件库（章节 | ID | 标题）："])
	var shown := 0
	for entry: Dictionary in event_entries:
		if chapter_filter > 0 and int(entry["chapter"]) != chapter_filter:
			continue
		var searchable := "%s %s" % [entry["id"], entry["title"]]
		if chapter_filter == 0 and not filter.is_empty() and not searchable.to_lower().contains(filter):
			continue
		lines.append("第%s章 | %s | %s" % [entry["chapter"], entry["id"], entry["title"]])
		shown += 1
	_log("\n".join(lines) if shown > 0 else "没有匹配事件。")


func _log_help() -> void:
	_log("\n".join(PackedStringArray([
		"调试控制台（↑↓历史，Tab 补全，Ctrl+L 清屏，Esc 关闭）：",
		"status  显示轮回、地图与战斗摘要",
		"deck / cards [名称、ID或描述筛选]",
		"card add <id> [数量]",
		"card remove <id或序号> [数量]",
		"card upgrade <id或序号> [数量]",
		"card fuse <id或序号A> <id或序号B>",
		"hand list/add/draw/discard/clear ...",
		"hp set/add/heal/damage/max <数值>",
		"block set/add/clear <数值> / mana set/add/fill <数值>",
		"gold set/add/remove <数值>",
		"relic list/library/add/remove <id>",
		"potion list/library/add/remove/clear <id或序号>",
		"enemy list/damage/kill/intent ...",
		"turn status/unlock/end",
		"map status/unlock/free/show ...",
		"event list/open/random ...",
		"difficulty set <0-15>",
		"next dealt set/add <数值>",
		"next taken set/add <数值>",
		"next clear / reload / save / clear",
		"常用命令及子命令支持中文：生命、护体、灵力、灵石、手牌、敌人、回合、地图、事件等。",
	])))


func _normalize_root_command(raw: String) -> String:
	var key := raw.strip_edges().to_lower()
	return {
		"帮助": "help", "？": "help",
		"状态": "status", "概况": "status",
		"牌组": "deck", "卡组": "deck", "卡牌库": "cards",
		"卡牌": "card", "手牌": "hand",
		"生命": "hp", "血量": "hp", "护体": "block", "护盾": "block",
		"灵力": "mana", "法力": "mana", "灵石": "gold", "金币": "gold",
		"法宝": "relic", "遗物": "relic", "丹药": "potion", "符箓": "potion",
		"敌人": "enemy", "怪物": "enemy", "回合": "turn", "地图": "map",
		"事件": "event", "难度": "difficulty", "下次伤害": "next",
		"刷新": "reload", "保存": "save", "清屏": "clear",
	}.get(key, key)


func _normalize_subcommand(raw: String) -> String:
	var key := raw.strip_edges().to_lower()
	return {
		"列表": "list", "查看": "list", "库": "library", "资源库": "library",
		"添加": "add", "增加": "add", "获得": "add",
		"删除": "remove", "移除": "remove", "减少": "remove",
		"突破": "upgrade", "升级": "upgrade", "融合": "fuse", "合炼": "fuse",
		"设置": "set", "设为": "set", "治疗": "heal", "回复": "heal",
		"伤害": "damage", "扣血": "damage", "上限": "max",
		"清空": "clear", "填满": "fill", "回满": "fill", "抽牌": "draw",
		"弃置": "discard", "击杀": "kill", "意图": "intent",
		"解锁": "unlock", "结束": "end", "开启操作": "unlock",
		"显示": "show", "自由": "free", "打开": "open", "随机": "random",
		"状态": "status",
	}.get(key, key)


func _normalize_damage_target(raw: String) -> String:
	var key := raw.strip_edges().to_lower()
	return {"造成": "dealt", "输出": "dealt", "受到": "taken", "承受": "taken"}.get(key, key)


func _parse_toggle(raw: String, fallback: bool) -> bool:
	var key := raw.strip_edges().to_lower()
	if key in ["on", "true", "1", "开", "开启", "是"]:
		return true
	if key in ["off", "false", "0", "关", "关闭", "否"]:
		return false
	return fallback


func _unique_resource_count(library: Dictionary) -> int:
	var paths := {}
	for value in library.values():
		var resource := value as Resource
		if resource:
			paths[resource.resource_path] = true
	return paths.size()


func _card_type_name(type: Card.Type) -> String:
	match type:
		Card.Type.ATTACK:
			return "攻击"
		Card.Type.POWER:
			return "功法"
		_:
			return "技能"


func _player_handler() -> PlayerHandler:
	return get_tree().get_first_node_in_group("player_handler") as PlayerHandler


func _live_enemies() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and enemy.stats and enemy.stats.health > 0 and not enemy.is_queued_for_deletion():
			result.append(enemy)
	return result


func _select_enemies(enemies: Array[Enemy], query: String) -> Array[Enemy]:
	if query.to_lower() in ["all", "全部"]:
		return enemies
	var result: Array[Enemy] = []
	if query.is_valid_int():
		var index := query.to_int()
		if index >= 0 and index < enemies.size():
			result.append(enemies[index])
	return result


func _log_enemies(enemies: Array[Enemy]) -> void:
	if enemies.is_empty():
		_log("当前没有存活敌人。")
		return
	var lines := PackedStringArray(["敌人（序号 | ID | 名称 | 生命 | 护体 | 意图）："])
	for index in enemies.size():
		var enemy := enemies[index]
		var intent := enemy.current_action.intent.current_text if enemy.current_action and enemy.current_action.intent else "无"
		lines.append("[%d] %s | %s | %d/%d | %d | %s" % [
			index, enemy.stats.id, enemy.stats.display_name, enemy.stats.health, enemy.stats.max_health, enemy.stats.block, intent,
		])
	_log("\n".join(lines))


func _hand_card_uis(hand: Hand) -> Array[CardUI]:
	var result: Array[CardUI] = []
	for child in hand.get_children():
		var card_ui := child as CardUI
		if card_ui and card_ui.card and not card_ui.is_queued_for_deletion():
			result.append(card_ui)
	return result


func _select_hand_cards(hand: Hand, query: String) -> Array[CardUI]:
	var cards := _hand_card_uis(hand)
	if query.to_lower() in ["all", "全部"]:
		return cards
	var result: Array[CardUI] = []
	if query.is_valid_int():
		var index := query.to_int()
		if index >= 0 and index < cards.size():
			result.append(cards[index])
		return result
	var key := query.to_lower()
	for card_ui: CardUI in cards:
		if card_ui.card.id.to_lower() == key or card_ui.card.get_display_name().to_lower() == key:
			result.append(card_ui)
			break
	return result


func _log_hand(hand: Hand) -> void:
	var cards := _hand_card_uis(hand)
	var lines := PackedStringArray(["手牌（序号 | ID | 名称 | 当前费用）："])
	for index in cards.size():
		var card := cards[index].card
		lines.append("[%d] %s | %s | %d" % [index, card.id, card.get_display_name(), card.cost])
	_log("\n".join(lines) if not cards.is_empty() else "当前手牌为空。")


func _run_map() -> Map:
	return run_node.get_node_or_null("Map") as Map if run_node else null


func _current_chapter() -> int:
	return int(run_node.get("current_chapter")) if run_node else 1


func _find_event_scene(query: String) -> PackedScene:
	var key := query.strip_edges().to_lower()
	if event_library.has(key):
		return event_library[key] as PackedScene
	var matches: Array[PackedScene] = []
	for alias in event_library:
		if str(alias).contains(key):
			var scene := event_library[alias] as PackedScene
			if scene and not matches.has(scene):
				matches.append(scene)
	return matches[0] if matches.size() == 1 else null


func _open_event(scene: PackedScene) -> void:
	if not scene or not run_node or not run_node.has_method("_change_view"):
		_log("当前轮回未初始化，无法直接打开事件。")
		return
	var event_room := run_node.call("_change_view", scene) as EventRoom
	if not event_room:
		_log("事件场景无法载入。")
		return
	event_room.character_stats = character_stats
	event_room.run_stats = run_stats
	event_room.setup()
	InkTheme.animate_screen_entrance(event_room)
	_log("已打开事件：%s" % scene.resource_path.get_file().get_basename())
	_hide_console()


func _log_status() -> void:
	if not character_stats or not run_stats:
		_log("轮回尚未初始化。")
		return
	var lines := PackedStringArray([
		"轮回状态：",
		"角色：%s | 生命 %d/%d | 护体 %d | 灵力 %d/%d" % [
			character_stats.character_name, character_stats.health, character_stats.max_health,
			character_stats.block, character_stats.mana, character_stats.max_mana,
		],
		"灵根：%s·%s | 牌组 %d 张 | 灵石 %d | 难度 %s" % [
			SpiritRootText.element_name(character_stats.spirit_root), character_stats.get_spirit_root_stage_name(),
			character_stats.deck.cards.size() if character_stats.deck else 0, run_stats.gold, run_stats.get_difficulty_name(),
		],
		"章节：%d | 战斗胜利 %d | 精英 %d | Boss %d | 事件 %d" % [
			_current_chapter(), run_stats.battles_won, run_stats.elites_defeated,
			run_stats.bosses_defeated, run_stats.events_resolved,
		],
	])
	var map_node := _run_map()
	if map_node:
		lines.append("地图：%d/%d 层 | 当前%s显示" % [map_node.floors_climbed, map_node.get_floor_count(), "" if map_node.visible else "未"])
	var handler := _player_handler()
	if handler and character_stats.draw_pile and character_stats.discard and character_stats.exhaust_pile:
		lines.append("战斗牌堆：手牌 %d | 抽牌 %d | 弃牌 %d | 消耗 %d | 操作%s" % [
			_hand_card_uis(handler.hand).size(), character_stats.draw_pile.cards.size(),
			character_stats.discard.cards.size(), character_stats.exhaust_pile.cards.size(),
			"可用" if handler.player_actions_enabled else "锁定",
		])
	_log("\n".join(lines))


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
