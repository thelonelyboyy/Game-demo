class_name GameSfx
extends RefCounted

## 通用音效库：从 art/audio/collected_dark_roguelike 精选的 CC0 素材
## （来源与授权见该目录 THIRD_PARTY_AUDIO.md，全部无署名义务）。
## 变体用 randi 随机挑选，刻意不走 RNG autoload——音效不该消耗存档种子影响战斗复现。

# —— 卡牌操作 ——
const DRAW := [
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/kenney_casino-audio/Audio/card-slide-1.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/kenney_casino-audio/Audio/card-slide-2.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/kenney_casino-audio/Audio/card-slide-3.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/kenney_casino-audio/Audio/card-slide-4.ogg"),
]
const PLAY_CARD := preload("res://art/audio/collected_dark_roguelike/sfx_packs/Cardsounds/cockatrice/playcard.wav")
const DISCARD := [
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/kenney_casino-audio/Audio/card-shove-1.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/kenney_casino-audio/Audio/card-shove-2.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/kenney_casino-audio/Audio/card-shove-3.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/kenney_casino-audio/Audio/card-shove-4.ogg"),
]
const SHUFFLE := preload("res://art/audio/collected_dark_roguelike/sfx_packs/Cardsounds/cockatrice/shuffle.wav")
const ERROR := preload("res://art/audio/collected_dark_roguelike/sfx_packs/Cardsounds/cockatrice/error.wav")
const END_TURN := preload("res://art/audio/collected_dark_roguelike/sfx_packs/Cardsounds/cockatrice/Passturn.wav")

# —— 打击/防御 ——
const HIT := [
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/100-CC0-SFX/hit_01.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/100-CC0-SFX/hit_02.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/100-CC0-SFX/hit_03.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/100-CC0-SFX/hit_04.ogg"),
]
const HEAVY_HIT := [
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/100-CC0-SFX/slam_02.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/100-CC0-SFX/slam_05.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/100-CC0-SFX/slam_07.ogg"),
]
const BLOCK := [
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/80-CC0-RPG-SFX/metal_01.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/80-CC0-RPG-SFX/metal_02.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/80-CC0-RPG-SFX/metal_03.ogg"),
]
const SWISH := [
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/battle_sound_effects_0/battle_sound_effects/swish_2.wav"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/battle_sound_effects_0/battle_sound_effects/swish_3.wav"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/battle_sound_effects_0/battle_sound_effects/swish_4.wav"),
]
const ENEMY_DIE := preload("res://art/audio/collected_dark_roguelike/sfx_packs/80-CC0-RPG-SFX/creature_die_01.ogg")

# —— 法术/资源 ——
const HEAL := preload("res://art/audio/collected_dark_roguelike/sfx_packs/80-CC0-RPG-SFX/spell_01.ogg")
const POWER_UP := preload("res://art/audio/collected_dark_roguelike/sfx_packs/80-CC0-RPG-SFX/spell_02.ogg")
const COINS := [
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/80-CC0-RPG-SFX/item_coins_01.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/80-CC0-RPG-SFX/item_coins_02.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/80-CC0-RPG-SFX/item_coins_03.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/80-CC0-RPG-SFX/item_coins_04.ogg"),
]

# —— 国风重音/提示 ——
const GONG := preload("res://art/audio/collected_dark_roguelike/sfx_packs/100-CC0-SFX/gong_01.ogg")
const GONG_HEAVY := preload("res://art/audio/collected_dark_roguelike/sfx_packs/100-CC0-SFX/gong_02.ogg")
const BOSS_BELL := preload("res://art/audio/collected_dark_roguelike/sfx_packs/100-CC0-SFX/bell_03.ogg")
const MAP_SELECT := preload("res://art/audio/collected_dark_roguelike/sfx_packs/100-CC0-SFX/paper_01.ogg")

# —— 通用界面 ——
const UI_HOVER := preload("res://art/audio/collected_dark_roguelike/sfx_packs/Cardsounds/cockatrice/tap.wav")
const UI_CLICK := [
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/kenney_casino-audio/Audio/card-place-1.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/kenney_casino-audio/Audio/card-place-2.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/kenney_casino-audio/Audio/card-place-3.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/kenney_casino-audio/Audio/card-place-4.ogg"),
]
const CHEST_OPEN := preload("res://art/audio/collected_dark_roguelike/sfx_packs/100-CC0-SFX/wooded_box_open.ogg")
const GEM := [
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/80-CC0-RPG-SFX/item_gem_01.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/80-CC0-RPG-SFX/item_gem_02.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/80-CC0-RPG-SFX/item_gem_03.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/80-CC0-RPG-SFX/item_gem_04.ogg"),
]
const BOOK := [
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/80-CC0-RPG-SFX/book_01.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/80-CC0-RPG-SFX/book_02.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/80-CC0-RPG-SFX/book_03.ogg"),
	preload("res://art/audio/collected_dark_roguelike/sfx_packs/80-CC0-RPG-SFX/book_04.ogg"),
]


## sound 可以是单个 AudioStream，也可以是变体数组（随机挑一个）。
static func play(sound: Variant, volume_db := 0.0) -> void:
	if sound is Array:
		if (sound as Array).is_empty():
			return
		sound = sound[randi() % (sound as Array).size()]
	if not (sound is AudioStream):
		return

	var sfx := _sfx_player()
	if sfx:
		sfx.play(sound, false, volume_db)


static func _sfx_player() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return null
	return tree.root.get_node_or_null("SFXPlayer")
