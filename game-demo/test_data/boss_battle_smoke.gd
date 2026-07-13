extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/sword_cultivator/sword_cultivator.tres"
const BOSS_BATTLES := [
	"res://battles/demo_b_bone_dragon.tres",
	"res://battles/demo_b_black_lotus.tres",
	"res://battles/demo_b_sky_guardian.tres",
	"res://battles/demo_b_sword_soul.tres",
	"res://battles/demo_b_eclipse_tyrant.tres",
	"res://battles/demo_b_blood_moon_demon_king.tres",
	"res://battles/demo_b_bronze_corpse_king.tres",
	"res://battles/demo_b_venom_broodmother.tres",
	"res://battles/demo_b_underworld_judge.tres",
]

var failures: PackedStringArray = []


func _ready() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	for battle_path: String in BOSS_BATTLES:
		print("BOSS_BATTLE_SMOKE_STEP:%s" % battle_path)
		await _check_boss_battle(battle_path)

	_finish()


func _check_boss_battle(battle_path: String) -> void:
	var battle_stats := load(battle_path) as BattleStats
	_check(battle_stats != null, "%s loads battle stats" % battle_path)
	if not battle_stats:
		return

	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	_check(battle_scene != null and relic_handler_scene != null and character_resource != null, "boss smoke support scenes load")
	if not battle_scene or not relic_handler_scene or not character_resource:
		return

	var relic_handler := relic_handler_scene.instantiate() as RelicHandler
	add_child(relic_handler)
	await get_tree().process_frame

	var battle := battle_scene.instantiate() as Battle
	add_child(battle)
	battle.char_stats = character_resource.create_instance()
	battle.battle_stats = battle_stats
	battle.relics = relic_handler
	battle.start_battle()

	await get_tree().create_timer(1.8).timeout
	_check(battle.enemy_handler.get_child_count() > 0, "%s spawns boss enemy" % battle_path)
	_check(_enemies_have_actions(battle), "%s boss has intent action" % battle_path)

	_check(await _end_turn_and_wait(battle), "%s enemy turn finishes within the smoke timeout" % battle_path)
	_check(battle.player != null and battle.player.stats != null and battle.player.stats.health > 0, "%s enemy turn completes without killing smoke player" % battle_path)
	if battle_path.contains("black_lotus"):
		_check(_discard_contains(battle, "heart_demon"), "%s adds heart demon curse to discard" % battle_path)
	if battle_path.contains("blood_moon_demon_king"):
		var blood_bosses := _get_live_enemies(battle)
		var blood_boss := blood_bosses[0] if not blood_bosses.is_empty() else null
		_check(blood_boss != null and blood_boss.status_handler.get_status_stacks("muscle") >= 3, "%s opens by gaining muscle" % battle_path)
	if battle_path.contains("bronze_corpse_king"):
		var bronze_bosses := _get_live_enemies(battle)
		var bronze_boss := bronze_bosses[0] if not bronze_bosses.is_empty() else null
		_check(bronze_boss != null and bronze_boss.stats.block >= 25, "%s opens with corpse armor" % battle_path)
	if battle_path.contains("venom_broodmother"):
		_check(_find_combat_card(battle, "toxin") != null, "%s mixes toxin into the combat cycle" % battle_path)
	if battle_path.contains("underworld_judge"):
		_check(_find_combat_card(battle, "underworld_writ") != null, "%s adds a persistent writ status" % battle_path)
	if battle_path.contains("eclipse_tyrant"):
		var eclipse_bosses := _get_live_enemies(battle)
		var eclipse_boss := eclipse_bosses[0] if not eclipse_bosses.is_empty() else null
		_check(eclipse_boss != null and eclipse_boss.current_action != null, "%s advances to gather intent" % battle_path)
		_check(eclipse_boss != null and eclipse_boss.current_action != null and eclipse_boss.current_action.name == "GatherAction", "%s uses gather as its second action" % battle_path)
		if eclipse_boss and eclipse_boss.current_action:
			eclipse_boss.current_action.perform_action()
			await get_tree().create_timer(0.8).timeout
		var eclipse_scar := _find_combat_card(battle, "eclipse_scar")
		_check(eclipse_scar != null, "%s gather adds a status to the combat card cycle" % battle_path)
		_check(eclipse_scar != null and eclipse_scar.is_ethereal_card(), "%s eclipse scar is ethereal" % battle_path)

	var live_enemies := _get_live_enemies(battle)
	if not live_enemies.is_empty():
		_check_boss_phase_transition(live_enemies[0], battle_path)

	for enemy: Enemy in _get_live_enemies(battle):
		enemy.take_damage(enemy.stats.health + enemy.stats.block + 999, Modifier.Type.DMG_TAKEN)

	await get_tree().create_timer(1.0).timeout
	var battle_over_panel := battle.get_node_or_null("BattleOverLayer/BattleOverPanel") as BattleOverPanel
	_check(battle_over_panel != null and battle_over_panel.visible, "%s shows victory panel after boss dies" % battle_path)
	get_tree().paused = false

	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame


func _end_turn_and_wait(battle: Battle, timeout_seconds := 12.0) -> bool:
	var state := {"ended": false}
	var on_turn_ended := func() -> void: state.ended = true
	Events.enemy_turn_ended.connect(on_turn_ended, CONNECT_ONE_SHOT)
	battle.battle_ui._on_end_turn_button_pressed()
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while is_instance_valid(battle) and battle.battle_active and not state.ended:
		if Time.get_ticks_msec() >= deadline:
			break
		await get_tree().process_frame
	if Events.enemy_turn_ended.is_connected(on_turn_ended):
		Events.enemy_turn_ended.disconnect(on_turn_ended)
	return state.ended


func _check_boss_phase_transition(boss: Enemy, battle_path: String) -> void:
	_check(boss.stats.phase_two_health_ratio > 0.0, "%s configures a second phase" % battle_path)
	if boss.stats.phase_two_health_ratio <= 0.0:
		return

	boss.stats.health = floori(boss.stats.max_health * boss.stats.phase_two_health_ratio)
	boss._try_enter_phase_two()
	_check(boss._phase_two_triggered, "%s enters second phase at threshold" % battle_path)
	_check(boss.stats.block >= boss.stats.phase_two_block, "%s gains phase transition block" % battle_path)
	var damage_modifier := boss.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	var phase_modifier := damage_modifier.get_value("boss_phase_two") if damage_modifier else null
	_check(phase_modifier != null and phase_modifier.percent_value == boss.stats.phase_two_damage_bonus, "%s gains phase damage modifier" % battle_path)
	_check(boss.current_action != null, "%s refreshes intent after phase transition" % battle_path)


func _enemies_have_actions(battle: Battle) -> bool:
	for enemy: Enemy in _get_live_enemies(battle):
		if enemy.current_action == null:
			return false
	return not _get_live_enemies(battle).is_empty()


func _discard_contains(battle: Battle, card_id: String) -> bool:
	if not battle or not battle.player_handler or not battle.player_handler.character:
		return false
	for card: Card in battle.player_handler.character.discard.cards:
		if card and card.id == card_id:
			return true
	return false


func _find_combat_card(battle: Battle, card_id: String) -> Card:
	if not battle or not battle.player_handler or not battle.player_handler.character:
		return null
	var character := battle.player_handler.character
	for pile: CardPile in [character.draw_pile, character.discard]:
		if not pile:
			continue
		for card: Card in pile.cards:
			if card and card.id == card_id:
				return card
	if battle.player_handler.hand:
		for child: Node in battle.player_handler.hand.get_children():
			var card_ui := child as CardUI
			if card_ui and card_ui.card and card_ui.card.id == card_id:
				return card_ui.card
	return null


func _get_live_enemies(battle: Battle) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	if not battle or not battle.enemy_handler:
		return enemies

	for child: Node in battle.enemy_handler.get_children():
		var enemy := child as Enemy
		if enemy and not enemy.is_queued_for_deletion():
			enemies.append(enemy)
	return enemies


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("BOSS_BATTLE_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("BOSS_BATTLE_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)
