extends Node

const RUN_SCENE_PATH := "res://scenes/run/run.tscn"
const GENERIC_EVENT_SMOKE_PATH := "res://scenes/event_rooms/spirit_beast_tracks_event.tscn"

var failures: PackedStringArray = []
var previous_save: SaveGame
var event_choice_resolved_seen := false
var campfire_rested_seen := false
var player_turn_ended_seen := false


func _ready() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	print("RUN_FLOW_SMOKE_STEP:backup")
	previous_save = SaveGame.load_data()

	print("RUN_FLOW_SMOKE_STEP:instantiate_run")
	var run_scene := load(RUN_SCENE_PATH) as PackedScene
	_check(run_scene != null, "run scene loads")
	if not run_scene:
		_finish()
		return

	var run := run_scene.instantiate() as Run
	add_child(run)
	await get_tree().process_frame
	await get_tree().process_frame

	print("RUN_FLOW_SMOKE_STEP:basic_checks")
	_check(run != null, "run scene instantiates")
	_check(run.character != null, "new run has character")
	_check(run.stats != null, "new run has run stats")
	_check(run.map != null and not run.map.map_data.is_empty(), "new run generates map")
	_check(SaveGame.load_data() != null, "new run save can be loaded")

	var rooms := _collect_rooms_by_type(run.map.map_data)
	_check_required_room(rooms, Room.Type.BLESSING, "blessing")
	_check_required_room(rooms, Room.Type.MONSTER, "monster")
	_check_required_room(rooms, Room.Type.ELITE, "elite")
	_check_required_room(rooms, Room.Type.TREASURE, "treasure")
	_check_required_room(rooms, Room.Type.CAMPFIRE, "campfire")
	_check_required_room(rooms, Room.Type.SHOP, "shop")
	_check_required_room(rooms, Room.Type.EVENT, "event")
	_check_required_room(rooms, Room.Type.BOSS, "boss")

	_check_battle_room_data(rooms.get(Room.Type.MONSTER), "monster battle")
	_check_battle_room_data(rooms.get(Room.Type.ELITE), "elite battle")
	_check_battle_room_data(rooms.get(Room.Type.BOSS), "boss battle")
	_check(rooms.has(Room.Type.EVENT) and rooms[Room.Type.EVENT].event_scene != null, "event room has event scene")

	print("RUN_FLOW_SMOKE_STEP:battle")
	await _check_battle_entry(run, rooms.get(Room.Type.MONSTER))
	print("RUN_FLOW_SMOKE_STEP:battle_victory")
	await _check_battle_victory_resolution(run, rooms.get(Room.Type.MONSTER))
	print("RUN_FLOW_SMOKE_STEP:boss_resolution")
	await _check_boss_room_resolution(run, rooms.get(Room.Type.BOSS))
	print("RUN_FLOW_SMOKE_STEP:reward")
	await _check_reward_entry(run, rooms.get(Room.Type.MONSTER))
	print("RUN_FLOW_SMOKE_STEP:treasure")
	await _check_treasure_entry(run, rooms.get(Room.Type.TREASURE))
	print("RUN_FLOW_SMOKE_STEP:shop")
	await _check_shop_entry(run, rooms.get(Room.Type.SHOP))
	print("RUN_FLOW_SMOKE_STEP:event")
	await _check_event_entry(run, rooms.get(Room.Type.EVENT))
	print("RUN_FLOW_SMOKE_STEP:campfire")
	await _check_campfire_entry(run, rooms.get(Room.Type.CAMPFIRE))

	print("RUN_FLOW_SMOKE_STEP:restore")
	_restore_previous_save()

	_finish()


func _collect_rooms_by_type(map_data: Array[Array]) -> Dictionary:
	var rooms := {}
	for row: Array in map_data:
		for room: Room in row:
			if not room or room.type == Room.Type.NOT_ASSIGNED:
				continue
			if not rooms.has(room.type):
				rooms[room.type] = room
	return rooms


func _check_required_room(rooms: Dictionary, type: Room.Type, label: String) -> void:
	_check(rooms.has(type), "map has %s room" % label)


func _check_battle_room_data(room: Room, label: String) -> void:
	_check(room != null and room.battle_stats != null, "%s has battle stats" % label)
	_check(room != null and room.battle_stats and room.battle_stats.enemies != null, "%s has enemy scene" % label)


func _check_battle_entry(run: Run, room: Room) -> void:
	if not run or not room:
		_check(false, "battle entry has run and room")
		return

	run._on_battle_room_entered(room)
	await get_tree().process_frame
	await get_tree().process_frame

	var battle := _current_view_child(run) as Battle
	_check(battle != null, "battle view opens")
	_check(battle != null and battle.enemy_handler.get_child_count() > 0, "battle spawns enemies")
	_check(battle != null and battle.player != null and battle.player.stats != null, "battle has player stats")
	if not battle:
		return

	await get_tree().create_timer(1.6).timeout
	_check(battle.battle_ui.hand.get_child_count() > 0, "battle draws a starting hand")
	_check(battle.battle_ui.end_turn_button.disabled == false, "end turn enables after hand draw")
	_check(_enemies_have_intents(battle), "enemies show intents")
	await _check_targeting_feedback(battle)
	await _check_end_turn_button(battle)


func _check_battle_victory_resolution(run: Run, room: Room) -> void:
	if not run or not room:
		_check(false, "battle victory has run and room")
		return

	run._on_battle_room_entered(room)
	await get_tree().process_frame
	await get_tree().process_frame

	var battle := _current_view_child(run) as Battle
	_check(battle != null, "victory smoke battle opens")
	if not battle:
		return

	await get_tree().create_timer(0.4).timeout
	var enemies := _get_live_battle_enemies(battle)
	_check(not enemies.is_empty(), "victory smoke has enemies to kill")
	for enemy: Enemy in enemies:
		enemy.take_damage(enemy.stats.health + enemy.stats.block + 999, Modifier.Type.DMG_TAKEN)

	await get_tree().create_timer(1.0).timeout
	var battle_over_panel := battle.get_node_or_null("BattleOverLayer/BattleOverPanel") as BattleOverPanel
	_check(battle_over_panel != null and battle_over_panel.visible, "battle victory panel appears after all enemies die")
	_check(not battle.battle_active, "battle deactivates after victory")
	get_tree().paused = false


func _check_boss_room_resolution(run: Run, room: Room) -> void:
	if not run or not room:
		_check(false, "boss resolution has run and room")
		return

	run.map.last_room = room
	run.map.floors_climbed = run.map.get_floor_count()
	run._on_battle_room_entered(room)
	await get_tree().process_frame
	await get_tree().process_frame

	var battle := _current_view_child(run) as Battle
	_check(battle != null, "boss battle view opens")
	if not battle:
		return

	await get_tree().create_timer(0.4).timeout
	var enemies := _get_live_battle_enemies(battle)
	_check(not enemies.is_empty(), "boss battle has enemies to kill")
	for enemy: Enemy in enemies:
		enemy.take_damage(enemy.stats.health + enemy.stats.block + 999, Modifier.Type.DMG_TAKEN)

	await get_tree().create_timer(1.0).timeout
	var battle_over_panel := battle.get_node_or_null("BattleOverLayer/BattleOverPanel") as BattleOverPanel
	_check(battle_over_panel != null and battle_over_panel.visible, "boss victory panel appears")
	if battle_over_panel:
		battle_over_panel.continue_button.pressed.emit()

	await get_tree().process_frame
	await get_tree().process_frame
	var current_view := _current_view_child(run)
	if current_view is BattleReward:
		var reward := current_view as BattleReward
		_check(run.pending_chapter_advance, "boss victory marks pending chapter advance")
		_check(reward.rewards.get_child_count() >= 3, "boss reward offers gold, card and relic choice")
		var relic_choice: RewardButton
		for child in reward.rewards.get_children():
			if child is RewardButton and child.has_meta("relic_choice"):
				relic_choice = child
				break
		_check(relic_choice != null, "boss reward includes mandatory relic choice")
		if relic_choice:
			relic_choice.pressed.emit()
			await get_tree().process_frame
		reward.back_button.pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		current_view = _current_view_child(run)
	_check(run.current_chapter == 2 or current_view is WinScreen, "boss reward exit advances chapter or shows win screen")
	_check(run.map.visible or current_view is WinScreen, "boss reward flow leaves battle cleanly")
	get_tree().paused = false


func _check_reward_entry(run: Run, room: Room) -> void:
	if not run or not room:
		_check(false, "reward entry has run and room")
		return

	run.map.last_room = room
	run._show_regular_battle_rewards()
	await get_tree().process_frame
	await get_tree().process_frame

	var reward := _current_view_child(run) as BattleReward
	_check(reward != null, "battle reward view opens")
	if not reward:
		return

	_check(reward.rewards.get_child_count() >= 2, "battle reward generates gold and card choices")

	var gold_before := run.stats.gold
	var deck_count_before := run.character.deck.cards.size()
	var gold_reward := _find_reward_button(reward, true)
	var card_reward := _find_reward_button(reward, false)
	_check(gold_reward != null, "gold reward button is present")
	_check(card_reward != null, "card reward button is present")

	if gold_reward:
		gold_reward.pressed.emit()
		await get_tree().process_frame
		_check(run.stats.gold > gold_before, "gold reward can be collected")

	if card_reward:
		card_reward.pressed.emit()
		await get_tree().process_frame
		var card_rewards := reward.active_card_rewards
		_check(card_rewards != null, "card reward picker opens")
		_check(card_rewards != null and not card_rewards.rewards.is_empty(), "card reward picker has choices")
		if card_rewards and not card_rewards.rewards.is_empty():
			card_rewards._show_tooltip(card_rewards.rewards[0])
			card_rewards.take_button.pressed.emit()
			await get_tree().process_frame
			_check(run.character.deck.cards.size() == deck_count_before + 1, "card reward can be taken")

	reward._on_back_button_pressed()
	await get_tree().process_frame
	await get_tree().process_frame
	_check_returned_to_map(run, "battle reward")


func _check_shop_entry(run: Run, _room: Room) -> void:
	if not run:
		_check(false, "shop entry has run")
		return

	run._on_shop_entered()
	await get_tree().process_frame

	var shop := _current_view_child(run) as Shop
	_check(shop != null, "shop view opens")
	_check(shop != null and shop.cards.get_child_count() > 0, "shop generates cards")
	_check(shop != null and shop.relics.get_child_count() > 0, "shop generates relics")
	_check(shop != null and shop.potions.get_child_count() > 0, "shop generates consumables")
	if not shop:
		return
	_check_shop_pricing(shop, run.stats)

	run.stats.gold = 10000
	shop._update_items()

	var deck_count_before := run.character.deck.cards.size()
	var relic_count_before := run.relic_handler.get_all_relics().size()
	var gold_before := run.stats.gold
	var shop_card := shop.cards.get_child(0) as ShopCard if shop.cards.get_child_count() > 0 else null
	var shop_relic := shop.relics.get_child(0) as ShopRelic if shop.relics.get_child_count() > 0 else null

	_check(shop_card != null, "shop card item exists")
	if shop_card:
		shop_card._on_buy_button_pressed()
		await get_tree().process_frame
		_check(run.character.deck.cards.size() == deck_count_before + 1, "shop card can be bought")
		_check(run.stats.gold < gold_before, "shop card purchase spends gold")

	gold_before = run.stats.gold
	_check(shop_relic != null, "shop relic item exists")
	if shop_relic:
		shop_relic._on_buy_button_pressed()
		await get_tree().process_frame
		_check(run.relic_handler.get_all_relics().size() == relic_count_before + 1, "shop relic can be bought")
		_check(run.stats.gold < gold_before, "shop relic purchase spends gold")

	shop._on_back_button_pressed()
	await get_tree().process_frame
	await get_tree().process_frame
	_check_returned_to_map(run, "shop")


func _check_shop_pricing(shop: Shop, stats: RunStats) -> void:
	var sale_cards: Array[ShopCard] = []
	for shop_card: ShopCard in shop.cards.get_children():
		_check(shop_card.base_gold_cost > 0, "shop cards preserve a positive base price")
		if shop_card.is_on_sale:
			sale_cards.append(shop_card)
	_check(sale_cards.size() == 1, "each shop offers exactly one half-price card")
	if not sale_cards.is_empty():
		_check(sale_cards[0].gold_cost == shop._get_item_cost(sale_cards[0].base_gold_cost, 0.5), "sale card uses half of its final price")

	for shop_relic: ShopRelic in shop.relics.get_children():
		_check(shop_relic.base_gold_cost > 0, "shop relics preserve a positive base price")
	for shop_potion: ShopPotion in shop.potions.get_children():
		_check(shop_potion.base_gold_cost > 0, "shop consumables preserve a positive base price")

	stats.shop_cost_multiplier = 1.25
	shop._update_item_costs()
	var before_coupon := _snapshot_shop_costs(shop)
	var modifier := shop.modifier_handler.get_modifier(Modifier.Type.SHOP_COST)
	var coupon := ModifierValue.create_new_modifier("smoke_coupon", ModifierValue.Type.PERCENT_BASED)
	coupon.percent_value = -0.5
	modifier.add_new_value(coupon)
	shop._update_item_costs()
	var first_refresh := _snapshot_shop_costs(shop)
	for index in first_refresh.size():
		_check(first_refresh[index] < before_coupon[index], "coupon lowers every current shop item")
	if not sale_cards.is_empty():
		_check(sale_cards[0].gold_cost == shop._get_item_cost(sale_cards[0].base_gold_cost, 0.5), "sale and coupon stack from the original card price")
	shop._update_item_costs()
	_check(first_refresh == _snapshot_shop_costs(shop), "shop price refresh always recomputes from base prices")
	stats.shop_cost_multiplier = 1.0


func _snapshot_shop_costs(shop: Shop) -> Array[int]:
	var costs: Array[int] = []
	for shop_card: ShopCard in shop.cards.get_children():
		costs.append(shop_card.gold_cost)
	for shop_relic: ShopRelic in shop.relics.get_children():
		costs.append(shop_relic.gold_cost)
	for shop_potion: ShopPotion in shop.potions.get_children():
		costs.append(shop_potion.gold_cost)
	return costs


func _check_treasure_entry(run: Run, _room: Room) -> void:
	if not run:
		_check(false, "treasure entry has run")
		return

	run._on_treasure_room_entered()
	await get_tree().process_frame
	await get_tree().process_frame

	var treasure := _current_view_child(run) as Treasure
	_check(treasure != null, "treasure view opens")
	if not treasure:
		return

	_check(treasure.found_relics.size() == 2, "treasure generates two relic choices")
	if treasure.found_relics.size() == 2:
		_check(treasure.found_relics[0] != treasure.found_relics[1], "treasure relic choices are different")

	var relic_count_before := run.relic_handler.get_all_relics().size()
	treasure._on_treasure_opened()
	await get_tree().process_frame
	await get_tree().process_frame

	var reward := _current_view_child(run) as BattleReward
	_check(reward != null, "treasure opens relic choice reward view")
	if not reward:
		return

	_check(reward.rewards.get_child_count() == 2, "treasure reward view shows two relic choices")
	_check(reward.back_button.disabled, "treasure reward requires choosing a relic")
	var choice := reward.rewards.get_child(0) as RewardButton if reward.rewards.get_child_count() > 0 else null
	_check(choice != null, "treasure relic choice button exists")
	if choice:
		choice.pressed.emit()
		await get_tree().process_frame
		_check(run.relic_handler.get_all_relics().size() == relic_count_before + 1, "treasure choice grants one relic")
		_check(not reward.back_button.disabled, "treasure reward can continue after choosing")

	reward._on_back_button_pressed()
	await get_tree().process_frame
	await get_tree().process_frame
	_check_returned_to_map(run, "treasure")


func _check_event_entry(run: Run, room: Room) -> void:
	if not run or not room:
		_check(false, "event entry has run and room")
		return

	room.event_scene = load(GENERIC_EVENT_SMOKE_PATH) as PackedScene
	run._on_event_room_entered(room)
	await get_tree().process_frame

	var event_room := _current_view_child(run) as EventRoom
	_check(event_room != null, "event view opens")

	var generic_event = event_room
	_check(generic_event != null and generic_event.has_method("_apply_choice"), "generic event scene opens")
	if not generic_event or not generic_event.has_method("_apply_choice"):
		return

	event_choice_resolved_seen = false
	Events.event_choice_resolved.connect(_on_event_choice_resolved, CONNECT_ONE_SHOT)
	var gold_before := run.stats.gold
	generic_event.choice_buttons[0]._on_pressed()
	await get_tree().process_frame
	_check(event_choice_resolved_seen, "event choice emits resolved signal")
	_check(run.stats.gold >= gold_before, "event choice applies reward")
	await get_tree().process_frame
	_check_returned_to_map(run, "event")


func _check_campfire_entry(run: Run, room: Room) -> void:
	if not run or not room:
		_check(false, "campfire entry has run and room")
		return

	run._on_campfire_entered()
	await get_tree().process_frame

	var campfire := _current_view_child(run) as Campfire
	_check(campfire != null, "campfire view opens")
	if not campfire:
		return

	campfire_rested_seen = false
	Events.campfire_rested.connect(_on_campfire_rested, CONNECT_ONE_SHOT)
	var health_before := run.character.health
	campfire._on_rest_button_pressed()
	await get_tree().process_frame
	_check(campfire_rested_seen, "campfire rest emits signal")
	_check(run.character.health >= health_before, "campfire rest does not reduce health")
	campfire._on_fade_out_finished()
	await get_tree().process_frame
	await get_tree().process_frame
	_check_returned_to_map(run, "campfire")


func _current_view_child(run: Run) -> Node:
	if not run or run.current_view.get_child_count() == 0:
		return null
	return run.current_view.get_child(0)


func _find_reward_button(reward: BattleReward, auto_consume: bool) -> RewardButton:
	for child: Node in reward.rewards.get_children():
		var reward_button := child as RewardButton
		if reward_button and reward_button.auto_consume == auto_consume:
			return reward_button
	return null


func _check_returned_to_map(run: Run, source: String) -> void:
	_check(run.current_view.get_child_count() == 0, "%s exits current view" % source)
	_check(run.map.visible, "%s returns to map" % source)
	var save := SaveGame.load_data()
	_check(save != null and save.was_on_map, "%s saves on map" % source)


func _enemies_have_intents(battle: Battle) -> bool:
	if not battle or not battle.enemy_handler:
		return false

	for child: Node in battle.enemy_handler.get_children():
		var enemy := child as Enemy
		if enemy and enemy.current_action == null:
			return false
	return battle.enemy_handler.get_child_count() > 0


func _check_targeting_feedback(battle: Battle) -> void:
	var card_ui := _find_single_target_card_ui(battle)
	if not card_ui:
		var strike := load("res://common_cards/strike.tres") as Card
		if strike:
			battle.battle_ui.hand.add_card(strike.duplicate(true) as Card)
			await get_tree().process_frame
			card_ui = _find_single_target_card_ui(battle)
		_check(card_ui != null, "single-target card exists for aim smoke")
		if not card_ui:
			return

	var enemy := _get_first_enemy(battle)
	_check(enemy != null, "enemy target exists for aim smoke")
	if not enemy:
		return

	var target_selector := battle.get_node_or_null("CardTargetSelector")
	_check(target_selector != null, "card target selector exists")
	if not target_selector:
		return

	card_ui.targets.clear()
	Events.card_aim_started.emit(card_ui)
	card_ui.targets.append(enemy)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(target_selector.get("targeting") == true, "card aiming starts target selector")
	var card_arc := target_selector.get("card_arc") as Line2D
	_check(card_arc != null and card_arc.points.size() > 0, "card aiming draws arrow")
	_check(enemy.target_highlight != null and enemy.target_highlight_lines.size() >= 8, "enemy target has corner highlight")
	Events.card_aim_ended.emit(card_ui)
	await get_tree().process_frame
	_check(target_selector.get("targeting") == false, "card aiming ends target selector")


func _check_end_turn_button(battle: Battle) -> void:
	player_turn_ended_seen = false
	Events.player_turn_ended.connect(_on_player_turn_ended_seen, CONNECT_ONE_SHOT)
	battle.battle_ui._on_end_turn_button_pressed()
	await get_tree().process_frame
	_check(player_turn_ended_seen, "end turn button emits player_turn_ended")
	_check(battle.battle_ui.end_turn_button.disabled, "end turn button disables after press")


func _on_event_choice_resolved(_effect: String, _amount: int, _character: CharacterStats, _run_stats: RunStats) -> void:
	event_choice_resolved_seen = true


func _on_campfire_rested(_character: CharacterStats, _heal_amount: int) -> void:
	campfire_rested_seen = true


func _on_player_turn_ended_seen() -> void:
	player_turn_ended_seen = true


func _find_single_target_card_ui(battle: Battle) -> CardUI:
	if not battle or not battle.battle_ui:
		return null

	for child: Node in battle.battle_ui.hand.get_children():
		var card_ui := child as CardUI
		if card_ui and card_ui.card and card_ui.card.is_single_targeted():
			return card_ui
	return null


func _get_first_enemy(battle: Battle) -> Enemy:
	if not battle or not battle.enemy_handler:
		return null

	for child: Node in battle.enemy_handler.get_children():
		if child is Enemy:
			return child as Enemy
	return null


func _get_live_battle_enemies(battle: Battle) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	if not battle or not battle.enemy_handler:
		return enemies

	for child: Node in battle.enemy_handler.get_children():
		var enemy := child as Enemy
		if enemy and not enemy.is_queued_for_deletion() and enemy.stats.health > 0:
			enemies.append(enemy)
	return enemies


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _restore_previous_save() -> void:
	if previous_save:
		previous_save.save_data()
	else:
		SaveGame.delete_data()


func _finish() -> void:
	if failures.is_empty():
		print("RUN_FLOW_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("RUN_FLOW_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)
