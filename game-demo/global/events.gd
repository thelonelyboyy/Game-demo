extends Node

# Card-related events
signal card_drag_started(card_ui: CardUI)
signal card_drag_ended(card_ui: CardUI)
signal card_aim_started(card_ui: CardUI)
signal card_aim_ended(card_ui: CardUI)
signal card_play_preview_requested(card: Card, start_global_center: Vector2)
# 回合结束弃牌时发出，战斗 UI 用它播放"幽灵卡飞向弃牌堆"动画。
signal card_discarded(card: Card, from_global_center: Vector2)
# 弃牌堆洗回抽牌堆时发出（携带洗入张数），战斗 UI 播放洗牌提示动画。
signal deck_reshuffled(card_count: int)
signal card_played(card: Card)
signal card_drawn(card: Card)
signal card_extra_drawn(card: Card)
signal spirit_root_fire_choice_requested(choice)
signal card_tooltip_requested(icon: Texture, text: String)
signal tooltip_hide_requested

# Player-related events
signal player_hand_drawn
signal player_hand_discarded
signal player_turn_started
signal player_turn_ended
signal player_hit
signal player_self_damaged(amount: int)
signal player_died
# Emitted when the player's attack animation finishes (or immediately when the
# player has no attack animation). Gates attack-card damage so it lands at the
# end of the swing instead of the start.
signal attack_animation_finished
# 魔焰焰轮变化（携带本回合已点亮的颜色 int 数组），战斗内焰轮 UI 监听刷新。
signal flame_wheel_changed(colors: Array)
# 煞气档位变化（0=无 1=≥3卡伤+1 2=≥6伤害×2 3=天魔降世×3），战斗 UI 播放阈值演出。
signal sha_qi_tier_changed(tier: int, stacks: int)
# 商店购卡等场合获得新卡，UI 播放"卡牌飞向总牌库"动画。
signal card_acquired_animation_requested(card: Card, from_global_center: Vector2)

# Enemy-related events
signal enemy_action_completed(enemy: Enemy)
signal enemy_turn_ended
signal enemy_died(enemy: Enemy)

# Battle-related events
signal battle_over_screen_requested(text: String, type: BattleOverPanel.Type)
signal battle_won
signal status_tooltip_requested(statuses: Array[Status])

# Map-related events
signal map_exited(room: Room)

# Shop-related events
signal shop_entered(shop: Shop)
signal shop_relic_bought(relic: Relic, gold_cost: int)
signal shop_card_bought(card: Card, gold_cost: int)
signal shop_potion_bought(potion: Potion, gold_cost: int)
signal shop_exited

# Campfire-related events
signal campfire_rested(character: CharacterStats, heal_amount: int)
signal campfire_card_upgraded(character: CharacterStats, card: Card)
signal campfire_exited

# Battle Reward-related events
signal battle_reward_exited

# Treasure Room-related events
signal treasure_room_exited(found_relics: Array[Relic])

# Relic-related events
signal relic_tooltip_requested(relic: Relic)
signal relic_tooltip_hide_requested

# Random Event room-related events
signal event_choice_resolved(effect: String, amount: int, character: CharacterStats, run_stats: RunStats)
signal event_room_exited

# Blessing room-related events
signal blessing_exited
