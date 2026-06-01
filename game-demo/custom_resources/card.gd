class_name Card
extends Resource

enum Type {ATTACK, SKILL, POWER}
enum Rarity {COMMON, UNCOMMON, RARE}
enum Target {SELF, SINGLE_ENEMY, ALL_ENEMIES, EVERYONE}
enum UpgradeType {NONE, STAT_BOOST, COST_REDUCTION}

const RARITY_COLORS := {
	Card.Rarity.COMMON: Color("2f3430"),
	Card.Rarity.UNCOMMON: Color("2f6f73"),
	Card.Rarity.RARE: Color("c79a3b"),
}

@export_group("Card Attributes")
@export var id: String
@export var type: Type
@export var rarity: Rarity
@export var target: Target
@export var cost: int
@export var exhausts: bool = false
@export var upgrade_type: UpgradeType = UpgradeType.NONE
@export var upgraded := false

@export_group("Card Visuals")
@export var display_name: String
@export var icon: Texture
@export_multiline var tooltip_text: String
@export var sound: AudioStream


func is_single_targeted() -> bool:
	return target == Target.SINGLE_ENEMY


func _get_targets(targets: Array[Node]) -> Array[Node]:
	if not targets:
		return []
		
	var tree := targets[0].get_tree()
	
	match target:
		Target.SELF:
			return tree.get_nodes_in_group("player")
		Target.ALL_ENEMIES:
			return tree.get_nodes_in_group("enemies")
		Target.EVERYONE:
			return tree.get_nodes_in_group("player") + tree.get_nodes_in_group("enemies")
		_:
			return []


func play(targets: Array[Node], char_stats: CharacterStats, modifiers: ModifierHandler) -> void:
	Events.card_played.emit(self)
	char_stats.mana -= cost
	
	if is_single_targeted():
		apply_effects(targets, modifiers)
	else:
		apply_effects(_get_targets(targets), modifiers)


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	pass


func get_display_name() -> String:
	var base_name := display_name if not display_name.is_empty() else id.capitalize()
	return "%s+" % base_name if upgraded else base_name


func get_default_tooltip() -> String:
	return tooltip_text


func get_updated_tooltip(_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler) -> String:
	return tooltip_text


func can_upgrade() -> bool:
	if upgraded or upgrade_type == UpgradeType.NONE:
		return false

	if upgrade_type == UpgradeType.COST_REDUCTION:
		return cost > 0

	return true


func upgrade() -> bool:
	if not can_upgrade():
		return false

	match upgrade_type:
		UpgradeType.STAT_BOOST:
			_upgrade_values()
		UpgradeType.COST_REDUCTION:
			cost = maxi(cost - 1, 0)

	upgraded = true
	return true


func get_upgrade_description() -> String:
	if upgraded:
		return "已突破"

	match upgrade_type:
		UpgradeType.STAT_BOOST:
			return "突破方向：数值提升 50%，向上取整"
		UpgradeType.COST_REDUCTION:
			return "突破方向：费用减少 1 点"
		_:
			return "此卡暂未设置突破方向"


func _upgrade_values() -> void:
	pass


func _upgrade_number(value: int) -> int:
	if value <= 0:
		return value

	return ceili(value * 1.5)
	
