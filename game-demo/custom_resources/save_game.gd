class_name SaveGame
extends Resource

const SAVE_PATH := "user://savegame.tres"
const MIGRATED_CARD_PATHS := {
	"sword_blood_curse": "res://characters/sword_cultivator/cards/sword_blood_curse.tres",
	"sword_energy_charge": "res://characters/sword_cultivator/cards/sword_energy_charge.tres",
	"sword_guard_formation": "res://characters/sword_cultivator/cards/sword_guard_formation.tres",
	"sword_nurture": "res://characters/sword_cultivator/cards/sword_nurture.tres",
	"sword_qi_draw": "res://characters/sword_cultivator/cards/sword_qi_draw.tres",
	"sword_star_shatter": "res://characters/sword_cultivator/cards/sword_star_shatter.tres",
	"sword_wanjian": "res://characters/sword_cultivator/cards/sword_wanjian.tres",
	"toxin": "res://common_cards/toxin.tres",
}

@export var rng_seed: int
@export var rng_state: int
@export var run_stats: RunStats
@export var char_stats: CharacterStats
@export var spirit_root: Card.Element = Card.Element.NONE
@export var current_deck: CardPile
@export var current_health: int
@export var relics: Array[Relic]
@export var potions: Array[Potion]
@export var map_data: Array[Array]
@export var last_room: Room
@export var floors_climbed: int
@export var current_chapter := 1
@export var was_on_map: bool


func save_data() -> void:
	var err := ResourceSaver.save(self, SAVE_PATH)
	assert(err == OK, "Couldn't save the game!")


static func load_data() -> SaveGame:
	if not FileAccess.file_exists(SAVE_PATH):
		return null

	# 存档以路径方式内嵌了大量资源引用（卡牌贴图、立绘、脚本等）。
	# 若其中任意资源被移动/重命名/删除，整个存档会在解析阶段直接报错且无法加载。
	# 先检查依赖是否齐全，缺失则当作损坏存档清理掉，避免每次启动刷错误、且让“继续游戏”自动失效。
	if _has_missing_dependencies():
		push_warning("存档引用的资源已缺失（可能因资源移动或重命名），无法加载，已清理该存档。")
		delete_data()
		return null

	var save := ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveGame
	if not save:
		push_warning("存档损坏或不兼容，无法加载，已清理该存档。")
		delete_data()
		return null

	save._migrate_card_resources()
	return save


static func _has_missing_dependencies() -> bool:
	for dependency in ResourceLoader.get_dependencies(SAVE_PATH):
		var has_path := false
		var resolvable := false
		for part in dependency.split("::"):
			if part.begins_with("res://") or part.begins_with("uid://"):
				has_path = true
				if ResourceLoader.exists(part):
					resolvable = true
					break
		if has_path and not resolvable:
			return true
	return false


static func delete_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func _migrate_card_resources() -> void:
	if current_deck:
		_migrate_card_pile(current_deck)

	if char_stats:
		_migrate_card_pile(char_stats.deck)
		_migrate_card_pile(char_stats.draw_pile)
		_migrate_card_pile(char_stats.discard)


func _migrate_card_pile(card_pile: CardPile) -> void:
	if not card_pile:
		return

	for i: int in range(card_pile.cards.size()):
		var card := card_pile.cards[i]
		var migrated_card := _migrate_card(card)
		if migrated_card:
			card_pile.cards[i] = migrated_card


func _migrate_card(card: Card) -> Card:
	if not card or not MIGRATED_CARD_PATHS.has(card.id):
		return null

	var script := card.get_script() as Script
	if script and script.resource_path == "res://custom_resources/cultivation_card.gd":
		return null

	var card_resource := ResourceLoader.load(MIGRATED_CARD_PATHS[card.id]) as Card
	if not card_resource:
		return null

	var migrated_card := card_resource.duplicate(true) as Card
	migrated_card.cost = card.cost
	migrated_card.upgraded = card.upgraded
	migrated_card.element = card.element
	migrated_card.fusion_level = card.fusion_level
	migrated_card.temporary_cost_reduction = card.temporary_cost_reduction
	return migrated_card
