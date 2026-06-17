# Tile Replacement Icon Directory

This directory replaces the old shared `art/tiles/tile_XXXX.png` references with
semantic image files generated from the consuming resource names.

The source of truth is the referencing `.tres` or `.tscn` file, not the old tile
appearance. For example, `common_cards/strike.tres` receives a strike-themed
card icon even though it used to share `tile_0118.png` with several other files.

## Mapping

| New file | Generated from | Intended use |
|---|---|---|
| `common_cards/toxin.png` | `common_cards/toxin.tres` | Card icon for 浊气 |
| `common_cards/strike.png` | `common_cards/strike.tres` | Card icon for 打击 |
| `common_cards/defend.png` | `common_cards/defend.tres` | Card icon for 防御 |
| `common_cards/muscle_resonance_strike.png` | `common_cards/muscle_resonance_strike.tres` | Card icon for 劲气共鸣 |
| `common_cards/ink_flow_slash.png` | `common_cards/ink_flow_slash.tres` | Card icon for 墨流斩 |
| `fusion_cards/sword_shield_chime.png` | `fusion_cards/sword_shield_chime.tres` | Card icon for 剑盾合鸣 |
| `fusion_cards/demon_rain_swordfire.png` | `fusion_cards/demon_rain_swordfire.tres` | Card icon for 魔雨剑火 |
| `fusion_cards/blood_beast_rend.png` | `fusion_cards/blood_beast_rend.tres` | Card icon for 血兽撕咬 |
| `fusion_cards/attack_guard_unity.png` | `fusion_cards/attack_guard_unity.tres` | Card icon for 攻守合一 |
| `body_cultivator/vajra_body.png` | `characters/body_cultivator/cards/vajra_body.tres` | Card icon for 金刚不坏 |
| `body_cultivator/mountain_breath.png` | `characters/body_cultivator/cards/mountain_breath.tres` | Card icon for 山息 |
| `body_cultivator/iron_bone_fist.png` | `characters/body_cultivator/cards/iron_bone_fist.tres` | Card icon for 铁骨拳 |
| `body_cultivator/collapsing_palm.png` | `characters/body_cultivator/cards/collapsing_palm.tres` | Card icon for 崩山掌 |
| `body_cultivator/bone_tempering.png` | `characters/body_cultivator/cards/bone_tempering.tres` | Card icon for 淬骨 |
| `beastmaster/wolf_pack.png` | `characters/beastmaster/cards/wolf_pack.tres` | Card icon for 群狼逐月 |
| `beastmaster/turtle_shell.png` | `characters/beastmaster/cards/turtle_shell.tres` | Card icon for 玄龟甲 |
| `beastmaster/tiger_claw.png` | `characters/beastmaster/cards/tiger_claw.tres` | Card icon for 虎爪 |
| `beastmaster/beast_bond.png` | `characters/beastmaster/cards/beast_bond.tres` | Card icon for 万兽同心 |
| `enemy_intents/bat_attack.png` | `enemies/bat/bat_enemy_ai.tscn` | Bat attack intent |
| `enemy_intents/bat_block.png` | `enemies/bat/bat_enemy_ai.tscn` | Bat block intent |
| `enemy_intents/crab_attack.png` | `enemies/crab/crab_enemy_ai.tscn` | Crab attack intent |
| `enemy_intents/crab_block.png` | `enemies/crab/crab_enemy_ai.tscn` | Crab block intent |
| `enemy_intents/crab_mega_block.png` | `enemies/crab/crab_enemy_ai.tscn` | Crab mega block intent |
| `enemy_intents/toxic_ghost_muscle_buff.png` | `enemies/toxic_ghost/toxic_ghost_ai.tscn` | Toxic ghost buff intent |
| `enemy_intents/toxic_ghost_block.png` | `enemies/toxic_ghost/toxic_ghost_ai.tscn` | Toxic ghost block intent |
| `scene_defaults/player_default.png` | `scenes/player/player.tscn` | Default player scene texture |
| `scene_defaults/enemy_default.png` | `scenes/enemy/enemy.tscn` | Default enemy scene texture |
| `scene_defaults/win_screen_character_default.png` | `scenes/win_screen/win_screen.tscn` | Default win screen portrait |
| `scene_defaults/map_room_default.png` | `scenes/map/map_room.tscn` | Default map room icon |
| `scene_defaults/card_visuals_default.png` | `scenes/ui/card_visuals.tscn` | Default card art preview |
| `ui/tooltip_default.png` | `scenes/ui/tooltip.tscn` | Default card tooltip icon |
| `ui/relic_ui_default.png` | `scenes/relic_handler/relic_ui.tscn` | Default relic UI icon |
| `ui/relic_tooltip_default.png` | `scenes/relic_handler/relic_tooltip.tscn` | Default relic tooltip icon |
| `scenes/shop_shopkeeper.png` | `scenes/shop/shop.tscn` | Shopkeeper normal frame |
| `scenes/helpful_boi_event.png` | `scenes/event_rooms/helpful_boi_event.tscn` | Event room illustration |
