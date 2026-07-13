class_name BattleAutoplayer
extends RefCounted

const MAX_CARDS_PER_TURN := 16
const MAX_WAIT_FRAMES := 2400
const MAX_WALL_TIME_MSEC := 15000

var cards_played := 0
var turns_played := 0
var play_log := PackedStringArray()
var timed_out := false
var _deadline_msec := 0


func run(battle: Battle, max_turns := 18) -> Dictionary:
	_deadline_msec = Time.get_ticks_msec() + MAX_WALL_TIME_MSEC
	while battle and battle.battle_active and turns_played < max_turns:
		if not await _wait_for_player_turn(battle):
			break
		if not battle.battle_active:
			break

		turns_played += 1
		await _play_turn(battle)
		if battle.battle_active and battle.player_handler.battle_running:
			play_log.append("T%s:end(hp=%s,block=%s,incoming=%s,enemy_hp=%s)" % [
				turns_played,
				battle.char_stats.health,
				battle.char_stats.block,
				_incoming_damage(battle),
				_total_enemy_health(battle),
			])
			Events.player_turn_ended.emit()
			await battle.get_tree().process_frame

	await _wait_for_resolution(battle)
	var live_enemies := _get_live_enemies(battle)
	var player_health := battle.char_stats.health if battle and battle.char_stats else 0
	return {
		"won": live_enemies.is_empty() and player_health > 0,
		"turns": turns_played,
		"cards_played": cards_played,
		"player_health": player_health,
		"enemies_remaining": live_enemies.size(),
		"timed_out": timed_out,
		"play_log": play_log.duplicate(),
	}


func _play_turn(battle: Battle) -> void:
	for _play_index in MAX_CARDS_PER_TURN:
		if not battle.battle_active or not battle.player_handler.player_actions_enabled:
			return
		var card_ui := _pick_card(battle)
		if not card_ui:
			return
		var card := card_ui.card
		var targets: Array[Node] = []
		if card.is_single_targeted():
			var target := _pick_target(battle)
			if not target:
				return
			targets.append(target)

		play_log.append("T%s:%s" % [turns_played, card.id])
		cards_played += 1
		await card.play(targets, battle.char_stats, battle.player.modifier_handler)
		if is_instance_valid(card_ui):
			card_ui.queue_free()
		await battle.get_tree().process_frame
		await battle.get_tree().create_timer(0.18).timeout


func _pick_card(battle: Battle) -> CardUI:
	var best: CardUI
	var best_score := -1000000
	for child: Node in battle.player_handler.hand.get_children():
		var card_ui := child as CardUI
		if not card_ui or not card_ui.card:
			continue
		var card := card_ui.card
		if not battle.char_stats.can_play_card(card):
			continue
		if _is_risky_self_damage(card, battle):
			continue
		var score := _score_card(card, battle)
		if score > best_score:
			best = card_ui
			best_score = score
	return best


func _score_card(card: Card, battle: Battle) -> int:
	var score := 0
	if card.type == Card.Type.POWER:
		score += 1000
	elif card.type == Card.Type.SKILL:
		score += 300
	else:
		score += 200

	if card.id.begins_with("demon_flame_"):
		score += {
			"demon_flame_blue": 780,
			"demon_flame_yellow": 700,
			"demon_flame_purple": 620,
			"demon_flame_white": 560,
			"demon_flame_green": 540,
			"demon_flame_black": 500,
			"demon_flame_red": 180,
		}.get(card.id, 0)

	if card.id in ["demon_soul_mark_sense", "demon_soul_rite"]:
		score += 120
	if card.id in ["demon_blood_qi_guard", "demon_bloodthirst"]:
		score += 120
	if card.id in ["demon_soul_armor", "demon_blood_ward", "demon_defend"]:
		score += 80 if _incoming_damage(battle) > battle.char_stats.block else -120
	if card.id == "demon_flesh_rebirth":
		score += 500 if battle.char_stats.health <= battle.char_stats.max_health - 8 else -250
	if card.is_x_cost():
		score -= 500
	else:
		score -= card.cost * 8
	return score


func _is_risky_self_damage(card: Card, battle: Battle) -> bool:
	if not card.has_any_mechanic_tag(["献祭"]):
		return false
	if card.id in ["demon_blood_debt", "demon_desperate_burst"]:
		return false
	if card.id in ["demon_blood_ward", "demon_blood_forge_armor"]:
		return battle.char_stats.health <= 4
	var unblocked_incoming := maxi(_incoming_damage(battle) - battle.char_stats.block, 0)
	return battle.char_stats.health <= maxi(8, unblocked_incoming + 5)


func _incoming_damage(battle: Battle) -> int:
	var total := 0
	for enemy: Enemy in _get_live_enemies(battle):
		if enemy.current_action and enemy.current_action.intent:
			total += _parse_intent_damage(enemy.current_action.intent)
	return total


func _parse_intent_damage(intent: Intent) -> int:
	if not intent or intent.category in [
		Intent.Category.DEFEND,
		Intent.Category.BUFF,
		Intent.Category.UNKNOWN,
		Intent.Category.SUMMON,
		Intent.Category.HEAL,
		Intent.Category.ESCAPE,
		Intent.Category.SLEEP,
	]:
		return 0
	var matcher := RegEx.new()
	if matcher.compile("^\\s*(\\d+)(?:\\s*[xX×]\\s*(\\d+))?") != OK:
		return 0
	var result := matcher.search(intent.current_text)
	if not result:
		return 0
	var damage := int(result.get_string(1))
	var hits_text := result.get_string(2)
	if not hits_text.is_empty():
		damage *= int(hits_text)
	return damage


func _pick_target(battle: Battle) -> Enemy:
	var target: Enemy
	for enemy: Enemy in _get_live_enemies(battle):
		if not target or enemy.stats.health + enemy.stats.block < target.stats.health + target.stats.block:
			target = enemy
	return target


func _total_enemy_health(battle: Battle) -> int:
	var total := 0
	for enemy: Enemy in _get_live_enemies(battle):
		total += enemy.stats.health + enemy.stats.block
	return total


func _wait_for_player_turn(battle: Battle) -> bool:
	for _frame in MAX_WAIT_FRAMES:
		if _wall_time_expired():
			return false
		if not battle or not is_instance_valid(battle) or not battle.battle_active:
			return false
		if battle.player_handler.player_actions_enabled:
			return true
		await battle.get_tree().process_frame
	return false


func _wait_for_resolution(battle: Battle) -> void:
	for _frame in 240:
		if _wall_time_expired():
			return
		if not battle or not is_instance_valid(battle):
			return
		if _get_live_enemies(battle).is_empty() or not battle.player_handler.battle_running:
			return
		await battle.get_tree().process_frame


func _wall_time_expired() -> bool:
	if _deadline_msec <= 0 or Time.get_ticks_msec() <= _deadline_msec:
		return false
	timed_out = true
	return true


func _get_live_enemies(battle: Battle) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	if not battle or not battle.enemy_handler:
		return enemies
	for child: Node in battle.enemy_handler.get_children():
		var enemy := child as Enemy
		if enemy and not enemy.is_queued_for_deletion() and enemy.stats and enemy.stats.health > 0:
			enemies.append(enemy)
	return enemies
