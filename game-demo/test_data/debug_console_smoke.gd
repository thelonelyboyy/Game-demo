extends Node

var _failed := false


func _ready() -> void:
	var character := CharacterStats.new()
	character.character_name = "控制台测试角色"
	character.max_health = 100
	character.health = 60
	character.max_mana = 3
	character.mana = 1
	character.deck = CardPile.new()
	character.deck.bind_cards_to_owner(character)

	var run_stats := RunStats.new()
	var console := DebugConsole.new()
	add_child(console)
	console.setup(character, run_stats, null, null, null)

	console._execute_command("生命 设置 40")
	_check(character.health == 40, "Chinese hp command updates health")
	console._execute_command("护体 增加 12")
	_check(character.block == 12, "Chinese block command updates block")
	console._execute_command("灵力 填满")
	_check(character.mana == 3, "Chinese mana command fills mana")
	console._execute_command("灵石 增加 30")
	_check(run_stats.gold == RunStats.STARTING_GOLD + 30, "Chinese gold command updates gold")
	console._execute_command("难度 设置 5")
	_check(run_stats.difficulty_level == 5, "difficulty command uses current difficulty system")

	console._execute_command("card add demon_strike 1")
	_check(character.deck.cards.size() == 1, "card command still supports existing ids")
	console._execute_command("next dealt add 4")
	_check(DebugConsoleState.apply_next_dealt(6) == 10, "next damage command remains compatible")

	_check(console.event_entries.size() == 45, "event console indexes all current events")
	console._execute_command("event list 3")
	_check(console.history[-1].contains("第3章"), "event list supports chapter filtering")
	console._execute_command("status")
	_check(console.history[-1].contains("轮回状态"), "status command prints current run summary")

	console._on_command_submitted("status")
	console._on_command_submitted("status")
	_check(console.command_history.size() == 1, "adjacent duplicate commands share one history entry")
	console.input.text = "sta"
	console._complete_command()
	_check(console.input.text == "status ", "tab completion resolves unique command")

	console.queue_free()
	await get_tree().process_frame
	if _failed:
		get_tree().quit(1)
	else:
		print("DEBUG_CONSOLE_SMOKE_OK")
		get_tree().quit()


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("DEBUG_CONSOLE_SMOKE_FAILED: %s" % message)
