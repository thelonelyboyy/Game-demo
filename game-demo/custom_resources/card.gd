class_name Card
extends Resource

enum Type {ATTACK, SKILL, POWER}
enum Rarity {COMMON, UNCOMMON, RARE, MYTHIC}
enum Target {SELF, SINGLE_ENEMY, ALL_ENEMIES, EVERYONE}
enum UpgradeType {NONE, STAT_BOOST, COST_REDUCTION}
enum Element {NONE, METAL, WOOD, WATER, FIRE, EARTH}
enum Profession {COMMON, BODY, SWORD, DEMONIC, BEASTMASTER}
enum LifecycleTrigger {PLAYED, DISCARDED, EXHAUSTED, DRAWN, TURN_ENDED_IN_HAND}

const RARITY_COLORS := {
	Card.Rarity.COMMON: Color("e8e1cc"),
	Card.Rarity.UNCOMMON: Color("4c9fd6"),
	Card.Rarity.RARE: Color("d7a93f"),
	Card.Rarity.MYTHIC: Color("7a3a18"),
}

const RARITY_NAMES := {
	Card.Rarity.COMMON: "白卡",
	Card.Rarity.UNCOMMON: "蓝卡",
	Card.Rarity.RARE: "金卡",
	Card.Rarity.MYTHIC: "暗金卡",
}

const PROFESSION_COLORS := {
	Card.Profession.COMMON: Color("645f4e"),
	Card.Profession.BODY: Color("8f3d32"),
	Card.Profession.SWORD: Color("2e718b"),
	Card.Profession.DEMONIC: Color("6f2b49"),
	Card.Profession.BEASTMASTER: Color("2f7a55"),
}

const PROFESSION_NAMES := {
	Card.Profession.COMMON: "通用",
	Card.Profession.BODY: "体修",
	Card.Profession.SWORD: "剑修",
	Card.Profession.DEMONIC: "魔修",
	Card.Profession.BEASTMASTER: "驭兽师",
}

const SPIRIT_ROOT_FIRE_CHOICE := preload("res://custom_resources/spirit_root_fire_choice.gd")
const META_SPIRIT_ROOT_FIRE_CHOICE := "spirit_root_fire_choice"
const META_SPIRIT_ROOT_FIRE_CHOICE_USED := "spirit_root_fire_choice_used"
const TEMPORARY_MECHANIC_TAG := "临时"
const CONSUMABLE_MECHANIC_TAG := "消耗"
const RETAIN_MECHANIC_TAG := "保留"
const INNATE_MECHANIC_TAG := "固有"
const ETHEREAL_MECHANIC_TAG := "虚无"
const UNPLAYABLE_MECHANIC_TAG := "不可打出"
const STATUS_MECHANIC_TAG := "状态"
const CURSE_MECHANIC_TAG := "诅咒"
const DISCARD_TRIGGER_MECHANIC_TAG := "弃牌触发"
const EXHAUST_TRIGGER_MECHANIC_TAG := "消耗触发"
const GROWTH_MECHANIC_TAG := "成长"
const DRAW_TRIGGER_MECHANIC_TAG := "抽牌触发"
const END_TURN_TRIGGER_MECHANIC_TAG := "滞留触发"
const TEMPORARY_MECHANIC_TAGS := [TEMPORARY_MECHANIC_TAG, "临时牌", "temporary", "temp"]
const CONSUMABLE_MECHANIC_TAGS := [CONSUMABLE_MECHANIC_TAG, "消耗牌", "exhaust", "exhausts", "consume"]
const RETAIN_MECHANIC_TAGS := [RETAIN_MECHANIC_TAG, "保留牌", "retain", "retained"]
const INNATE_MECHANIC_TAGS := [INNATE_MECHANIC_TAG, "固有牌", "innate"]
const ETHEREAL_MECHANIC_TAGS := [ETHEREAL_MECHANIC_TAG, "虚无牌", "ethereal"]
const UNPLAYABLE_MECHANIC_TAGS := [UNPLAYABLE_MECHANIC_TAG, "不能打出", "无法打出", "unplayable"]
const STATUS_MECHANIC_TAGS := [STATUS_MECHANIC_TAG, "状态牌", "status"]
const CURSE_MECHANIC_TAGS := [CURSE_MECHANIC_TAG, "诅咒牌", "curse", "cursed"]
const DISCARD_TRIGGER_MECHANIC_TAGS := [DISCARD_TRIGGER_MECHANIC_TAG, "弃置触发", "discard_trigger", "discard"]
const EXHAUST_TRIGGER_MECHANIC_TAGS := [EXHAUST_TRIGGER_MECHANIC_TAG, "消耗时触发", "exhaust_trigger", "on_exhaust"]
const GROWTH_MECHANIC_TAGS := [GROWTH_MECHANIC_TAG, "成长牌", "grow", "growth"]
const DRAW_TRIGGER_MECHANIC_TAGS := [DRAW_TRIGGER_MECHANIC_TAG, "抽到时触发", "draw_trigger", "on_draw"]
const END_TURN_TRIGGER_MECHANIC_TAGS := [END_TURN_TRIGGER_MECHANIC_TAG, "回合结束触发", "end_turn_trigger", "on_turn_end_in_hand"]
const PLAYABLE_MECHANIC_TAGS := ["可打出", "可使用", "playable"]

@export_group("Card Attributes")
@export var id: String
@export var type: Type
@export var rarity: Rarity
@warning_ignore("shadowed_variable_base_class")
@export var target: Target
@export var cost: int
@export var exhausts: bool = false
@export var upgrade_type: UpgradeType = UpgradeType.NONE
@export var upgraded := false
@export var element: Element = Element.NONE
@export var fusion_level := 0
@export var profession: Profession = Profession.COMMON
@export var mechanic_tags := PackedStringArray()

@export_group("Card Visuals")
@export var display_name: String
@export var icon: Texture
@export_multiline var tooltip_text: String
@export var sound: AudioStream

var spirit_root_owner: CharacterStats
var temporary_cost_reduction := 0
var last_x_paid := 0
var temporary := false


func is_single_targeted() -> bool:
	return target == Target.SINGLE_ENEMY


func _get_targets(targets: Array[Node]) -> Array[Node]:
	var tree: SceneTree
	if not targets.is_empty() and targets[0]:
		tree = targets[0].get_tree()
	else:
		tree = Engine.get_main_loop() as SceneTree

	if not tree:
		return []

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
	last_x_paid = 0
	var mana_cost := cost
	if is_x_cost():
		mana_cost = maxi(char_stats.mana, 0)
		last_x_paid = mana_cost
	char_stats.mana = maxi(char_stats.mana - mana_cost, 0)

	var resolved_targets := targets if is_single_targeted() else _get_targets(targets)
	var fire_choice = _create_spirit_root_fire_choice(resolved_targets, modifiers, char_stats)
	if fire_choice:
		Events.spirit_root_fire_choice_requested.emit(fire_choice)
		if not fire_choice.resolved:
			await fire_choice.completed
		if fire_choice.selected_choice != SPIRIT_ROOT_FIRE_CHOICE.CHOICE_NONE:
			set_meta(META_SPIRIT_ROOT_FIRE_CHOICE, fire_choice.selected_choice)
			set_meta(META_SPIRIT_ROOT_FIRE_CHOICE_USED, false)

	# Attack cards wait for the player's attack animation to finish before
	# dealing damage, so the hit lands at the end of the swing. The player
	# guarantees this signal fires (immediately if it has no attack animation).
	if type == Type.ATTACK:
		await Events.attack_animation_finished

	apply_effects(resolved_targets, modifiers)
	handle_lifecycle_trigger(LifecycleTrigger.PLAYED, resolved_targets, modifiers)
	_clear_spirit_root_fire_choice()


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	pass


func get_display_name() -> String:
	var base_name := display_name if not display_name.is_empty() else id.capitalize()
	if upgraded:
		base_name = "%s+" % base_name
	if fusion_level > 0:
		base_name = "%s·合炼%s" % [base_name, fusion_level]
	return base_name


func get_rarity_name() -> String:
	return RARITY_NAMES.get(rarity, "白卡")


func get_profession() -> Profession:
	if profession != Profession.COMMON:
		return profession

	var path := resource_path
	if path.contains("body_cultivator"):
		return Profession.BODY
	if path.contains("sword_cultivator"):
		return Profession.SWORD
	if path.contains("demonic_cultivator"):
		return Profession.DEMONIC
	if path.contains("beastmaster"):
		return Profession.BEASTMASTER
	return Profession.COMMON


func get_profession_name() -> String:
	return PROFESSION_NAMES.get(get_profession(), "通用")


func get_profession_color() -> Color:
	return PROFESSION_COLORS.get(get_profession(), PROFESSION_COLORS[Profession.COMMON])


func get_default_tooltip() -> String:
	return with_runtime_tooltip(tooltip_text)


func is_x_cost() -> bool:
	return cost < 0


func get_cost_text() -> String:
	return "X" if is_x_cost() else str(cost)


func get_x_cost_paid() -> int:
	return last_x_paid


func get_updated_tooltip(_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler) -> String:
	return with_runtime_tooltip(tooltip_text)


func is_temporary_card() -> bool:
	return temporary or has_any_mechanic_tag(TEMPORARY_MECHANIC_TAGS)


func is_consumable_card() -> bool:
	return exhausts or has_any_mechanic_tag(CONSUMABLE_MECHANIC_TAGS)


func is_retained_card() -> bool:
	return has_any_mechanic_tag(RETAIN_MECHANIC_TAGS)


func is_innate_card() -> bool:
	return has_any_mechanic_tag(INNATE_MECHANIC_TAGS)


func is_ethereal_card() -> bool:
	return has_any_mechanic_tag(ETHEREAL_MECHANIC_TAGS)


func is_unplayable_card() -> bool:
	return has_any_mechanic_tag(UNPLAYABLE_MECHANIC_TAGS)


func is_status_card() -> bool:
	return has_any_mechanic_tag(STATUS_MECHANIC_TAGS)


func is_curse_card() -> bool:
	return has_any_mechanic_tag(CURSE_MECHANIC_TAGS)


func has_discard_trigger() -> bool:
	return has_any_mechanic_tag(DISCARD_TRIGGER_MECHANIC_TAGS)


func has_exhaust_trigger() -> bool:
	return has_any_mechanic_tag(EXHAUST_TRIGGER_MECHANIC_TAGS)


func is_growth_card() -> bool:
	return has_any_mechanic_tag(GROWTH_MECHANIC_TAGS)


func has_draw_trigger() -> bool:
	return has_any_mechanic_tag(DRAW_TRIGGER_MECHANIC_TAGS)


func has_end_turn_trigger() -> bool:
	return has_any_mechanic_tag(END_TURN_TRIGGER_MECHANIC_TAGS)


func blocks_manual_play() -> bool:
	if is_unplayable_card():
		return true
	return (is_status_card() or is_curse_card()) and not has_any_mechanic_tag(PLAYABLE_MECHANIC_TAGS)


func handle_lifecycle_trigger(_trigger: LifecycleTrigger, _targets: Array[Node], _modifiers: ModifierHandler) -> void:
	pass


func has_any_mechanic_tag(tags: Array) -> bool:
	if tags.is_empty():
		return false

	for mechanic_tag: String in mechanic_tags:
		var normalized_tag := mechanic_tag.strip_edges().to_lower()
		for candidate in tags:
			if normalized_tag == str(candidate).strip_edges().to_lower():
				return true
	return false


func ensure_mechanic_tag(tag: String) -> void:
	var clean_tag := tag.strip_edges()
	if clean_tag.is_empty() or has_any_mechanic_tag([clean_tag]):
		return
	mechanic_tags.append(clean_tag)


func remove_mechanic_tags(tags: Array) -> void:
	if tags.is_empty():
		return
	var remaining := PackedStringArray()
	for mechanic_tag: String in mechanic_tags:
		var should_remove := false
		var normalized_tag := mechanic_tag.strip_edges().to_lower()
		for candidate in tags:
			if normalized_tag == str(candidate).strip_edges().to_lower():
				should_remove = true
				break
		if not should_remove:
			remaining.append(mechanic_tag)
	mechanic_tags = remaining


func with_runtime_tooltip(text: String) -> String:
	var runtime_notes := PackedStringArray()
	if is_retained_card():
		runtime_notes.append("保留：回合结束时不会弃置，留到下回合。")
	if is_innate_card():
		runtime_notes.append("固有：战斗开始时优先进入起手。")
	if is_temporary_card():
		runtime_notes.append("临时：打出后移除；回合结束留在手牌也会移除，不进入抽牌堆或弃牌堆。")
	if is_consumable_card():
		runtime_notes.append("消耗：打出后移除，不进入抽牌堆或弃牌堆；未打出时正常弃置。")
	if is_ethereal_card():
		runtime_notes.append("虚无：回合结束若仍在手牌中，则移除。")
	if blocks_manual_play():
		runtime_notes.append("不可打出：不能主动使用这张牌。")
	if is_status_card():
		runtime_notes.append("状态牌：用于污染抽牌循环；默认不可打出，可用“可打出”标签覆盖。")
	if is_curse_card():
		runtime_notes.append("诅咒牌：负面牌库污染；默认不可打出，可用“可打出”标签覆盖。")
	if has_discard_trigger():
		runtime_notes.append("弃牌触发：从手牌进入弃牌堆时触发额外效果。")
	if has_exhaust_trigger():
		runtime_notes.append("消耗触发：被消耗移除时触发额外效果。")
	if is_growth_card():
		runtime_notes.append("成长：在本场战斗中按配置触发成长，提升本牌数值。")
	if has_draw_trigger():
		runtime_notes.append("抽牌触发：从抽牌堆进入手牌时触发额外效果。")
	if has_end_turn_trigger():
		runtime_notes.append("滞留触发：回合结束时若仍在手牌中，先触发额外效果再结算弃牌、保留或消耗。")

	if runtime_notes.is_empty():
		return text

	var runtime_text := "\n".join(runtime_notes)
	if text.contains("[/center]"):
		return text.replace("[/center]", "\n\n%s[/center]" % runtime_text)
	if text.is_empty():
		return runtime_text
	return "%s\n\n%s" % [text, runtime_text]


func bind_spirit_root_owner(owner: CharacterStats) -> void:
	spirit_root_owner = owner


func create_runtime_copy() -> Card:
	# Runtime owner links can lead back into the entire combat object graph.
	var copy := duplicate(false) as Card
	if copy:
		copy.spirit_root_owner = null
	return copy


func is_selected_spirit_root_element() -> bool:
	return spirit_root_owner and spirit_root_owner.has_spirit_root() and element == spirit_root_owner.spirit_root


func get_spirit_root_modified_value(value: int) -> int:
	if value <= 0 or not is_selected_spirit_root_element():
		return value

	return spirit_root_owner.get_spirit_root_modified_value(value)


func get_spirit_root_primary_value() -> int:
	return 0


func consume_spirit_root_fire_choice() -> int:
	if not has_meta(META_SPIRIT_ROOT_FIRE_CHOICE):
		return SPIRIT_ROOT_FIRE_CHOICE.CHOICE_NONE

	if get_meta(META_SPIRIT_ROOT_FIRE_CHOICE_USED, false):
		return SPIRIT_ROOT_FIRE_CHOICE.CHOICE_NONE

	set_meta(META_SPIRIT_ROOT_FIRE_CHOICE_USED, true)
	return int(get_meta(META_SPIRIT_ROOT_FIRE_CHOICE, SPIRIT_ROOT_FIRE_CHOICE.CHOICE_NONE))


func reduce_cost_for_turn(amount: int) -> void:
	if amount <= 0 or cost <= 0:
		return

	var reduction := mini(amount, cost)
	cost -= reduction
	temporary_cost_reduction += reduction


func reset_temporary_cost() -> void:
	if temporary_cost_reduction <= 0:
		return

	cost += temporary_cost_reduction
	temporary_cost_reduction = 0


func _create_spirit_root_fire_choice(
	targets: Array[Node],
	modifiers: ModifierHandler,
	char_stats: CharacterStats
):
	if not char_stats or not char_stats.should_request_spirit_root_fire_choice(self):
		return null

	if Events.spirit_root_fire_choice_requested.get_connections().is_empty():
		return null

	var choice = SPIRIT_ROOT_FIRE_CHOICE.new()
	choice.card = self
	choice.targets = targets
	choice.modifiers = modifiers
	return choice


func _clear_spirit_root_fire_choice() -> void:
	if has_meta(META_SPIRIT_ROOT_FIRE_CHOICE):
		remove_meta(META_SPIRIT_ROOT_FIRE_CHOICE)
	if has_meta(META_SPIRIT_ROOT_FIRE_CHOICE_USED):
		remove_meta(META_SPIRIT_ROOT_FIRE_CHOICE_USED)


func get_element_name() -> String:
	match element:
		Element.METAL:
			return "金"
		Element.WOOD:
			return "木"
		Element.WATER:
			return "水"
		Element.FIRE:
			return "火"
		Element.EARTH:
			return "土"
		_:
			return "无"


func get_element_tooltip() -> String:
	var text := "[center]元素：%s" % get_element_name()
	if is_selected_spirit_root_element():
		text += "  |  灵根%s  |  同元素牌：%s" % [
			spirit_root_owner.get_spirit_root_stage_name(),
			spirit_root_owner.count_spirit_root_cards()
		]
	text += "[/center]"
	return text


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
			return "突破方向：数值提高 50%，向上取整"
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
