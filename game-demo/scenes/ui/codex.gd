extends Control

const CARD_MENU_UI_SCENE := preload("res://scenes/ui/card_menu_ui.tscn")

const CARD_SCOPES := {
	"全部": "",
	"通用": "common",
	"体修": "body",
	"剑修": "sword",
	"魔修": "demonic",
	"驭兽": "beastmaster",
	"融合": "fusion",
}

const CARD_SCAN_ROOTS := {
	"common": ["res://common_cards/"],
	"body": ["res://characters/body_cultivator/cards/"],
	"sword": ["res://characters/sword_cultivator/cards/"],
	"demonic": ["res://characters/demonic_cultivator/cards/"],
	"beastmaster": ["res://characters/beastmaster/cards/"],
	"fusion": ["res://fusion_cards/"],
}

enum EntryKind {SUMMARY, CARD, RELIC, ENEMY, STATUS, POTION}

@onready var title: Label = %Title
@onready var directory: Tree = %Directory
@onready var detail_panel: PanelContainer = %DetailPanel
@onready var detail_icon: TextureRect = %DetailIcon
@onready var detail_title: Label = %DetailTitle
@onready var detail_meta: Label = %DetailMeta
@onready var detail_text: RichTextLabel = %DetailText
@onready var preview_slot: CenterContainer = %PreviewSlot
@onready var back_button: Button = %BackButton

var all_cards: Array = []
var cards_by_scope := {}
var all_relics: Array = []
var all_enemies: Array = []
var all_statuses: Array = []
var all_potions: Array = []


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	directory.item_selected.connect(_on_directory_item_selected)
	_polish_scene()
	_collect_all_data()
	_build_directory()
	_show_summary("图鉴总览", _format_overview())


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


func _polish_scene() -> void:
	InkTheme.apply_title(title, 44)
	InkTheme.apply_panel(%DirectoryPanel)
	InkTheme.apply_panel(detail_panel)
	InkTheme.apply_button(back_button, true)
	InkTheme.apply_body_label(detail_title, 34)
	InkTheme.apply_body_label(detail_meta, 20)
	detail_title.add_theme_color_override("font_color", Color("f0c85b"))
	detail_meta.add_theme_color_override("font_color", Color("cdbf92"))
	detail_text.add_theme_color_override("default_color", Color("eee7d2"))
	detail_text.add_theme_font_size_override("normal_font_size", 21)
	directory.add_theme_font_size_override("font_size", 20)


func _collect_all_data() -> void:
	_collect_cards()
	all_relics = _collect_resources_of_type(["res://relics/"], Relic)
	all_enemies = _collect_resources_of_type(["res://enemies/"], EnemyStats)
	all_statuses = _collect_resources_of_type(["res://statuses/"], Status)
	all_potions = _collect_resources_of_type(["res://potions/"], Potion)


func _collect_cards() -> void:
	all_cards.clear()
	cards_by_scope.clear()

	for scope_name in CARD_SCOPES.keys():
		cards_by_scope[scope_name] = []

	for scope_name in CARD_SCAN_ROOTS.keys():
		var cards := _collect_resources_of_type(CARD_SCAN_ROOTS[scope_name], Card)
		cards_by_scope[_scope_key_to_label(scope_name)] = cards
		all_cards.append_array(cards)

	all_cards = _dedupe_resources(all_cards)
	all_cards.sort_custom(func(left: Card, right: Card): return _card_sort_key(left) < _card_sort_key(right))
	cards_by_scope["全部"] = all_cards


func _collect_resources_of_type(paths: Array, expected_type) -> Array:
	var result := []
	for path: String in paths:
		result.append_array(_load_resources_in_dir(path, expected_type))

	result = _dedupe_resources(result)
	result.sort_custom(func(left, right): return _resource_sort_name(left) < _resource_sort_name(right))
	return result


func _load_resources_in_dir(path: String, expected_type) -> Array:
	var result := []
	var dir := DirAccess.open(path)
	if not dir:
		return result

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var resource_path := path.path_join(file_name)
		if dir.current_is_dir():
			result.append_array(_load_resources_in_dir(resource_path, expected_type))
		elif file_name.ends_with(".tres"):
			var resource := load(resource_path)
			if is_instance_of(resource, expected_type):
				result.append(resource)

		file_name = dir.get_next()

	return result


func _dedupe_resources(resources: Array) -> Array:
	var result := []
	var seen := {}
	for resource in resources:
		if not resource:
			continue

		var key: String = resource.resource_path
		if key.is_empty():
			key = str(resource.get_instance_id())
		if seen.has(key):
			continue

		seen[key] = true
		result.append(resource)
	return result


func _build_directory() -> void:
	directory.clear()
	directory.hide_root = true

	var root := directory.create_item()
	_add_summary_node(root, "总览", "图鉴总览", _format_overview())

	var cards_root := _add_summary_node(root, "卡牌（%s）" % all_cards.size(), "卡牌", _format_card_summary())
	for scope_name in CARD_SCOPES.keys():
		var cards: Array = cards_by_scope.get(scope_name, [])
		var scope_item := _add_summary_node(
			cards_root,
			"%s（%s）" % [scope_name, cards.size()],
			"%s卡牌" % scope_name,
			_format_card_scope_summary(scope_name, cards)
		)
		for card: Card in cards:
			_add_resource_node(scope_item, card.get_display_name(), EntryKind.CARD, card)

	var relics_root := _add_summary_node(root, "法宝（%s）" % all_relics.size(), "法宝", _format_relic_summary())
	for relic: Relic in all_relics:
		_add_resource_node(relics_root, _relic_display_name(relic), EntryKind.RELIC, relic)

	var enemies_root := _add_summary_node(root, "怪物（%s）" % all_enemies.size(), "怪物", _format_enemy_summary())
	for enemy: EnemyStats in all_enemies:
		_add_resource_node(enemies_root, _enemy_display_name(enemy), EntryKind.ENEMY, enemy)

	var statuses_root := _add_summary_node(root, "词条（%s）" % all_statuses.size(), "词条", _format_status_summary())
	for status: Status in all_statuses:
		_add_resource_node(statuses_root, _status_display_name(status), EntryKind.STATUS, status)

	var potions_root := _add_summary_node(root, "符箓丹药（%s）" % all_potions.size(), "符箓丹药", _format_potion_summary())
	var talismans := all_potions.filter(func(p: Potion): return p.category == Potion.Category.TALISMAN)
	var pills := all_potions.filter(func(p: Potion): return p.category == Potion.Category.PILL)
	_add_potion_group(potions_root, "符箓", talismans)
	_add_potion_group(potions_root, "丹药", pills)

	cards_root.collapsed = false
	relics_root.collapsed = true
	enemies_root.collapsed = true
	statuses_root.collapsed = true
	potions_root.collapsed = true

	var first_card_scope := cards_root.get_first_child()
	if first_card_scope:
		first_card_scope.collapsed = false


func _add_potion_group(parent: TreeItem, label: String, potions: Array) -> void:
	if potions.is_empty():
		return
	var group := _add_summary_node(
		parent,
		"%s（%s）" % [label, potions.size()],
		label,
		_format_potion_group_summary(label, potions)
	)
	for potion: Potion in potions:
		var item := _add_resource_node(group, _potion_display_name(potion), EntryKind.POTION, potion)
		item.set_custom_color(0, _rarity_color(potion.rarity))


func _add_summary_node(parent: TreeItem, label: String, title_text: String, body_text: String) -> TreeItem:
	var item := directory.create_item(parent)
	item.set_text(0, label)
	item.set_metadata(0, {
		"kind": EntryKind.SUMMARY,
		"title": title_text,
		"text": body_text,
	})
	item.set_custom_color(0, Color("f0c85b"))
	return item


func _add_resource_node(parent: TreeItem, label: String, kind: EntryKind, resource: Resource) -> TreeItem:
	var item := directory.create_item(parent)
	item.set_text(0, label)
	item.set_metadata(0, {
		"kind": kind,
		"resource": resource,
	})
	return item


func _on_directory_item_selected() -> void:
	var item := directory.get_selected()
	if not item:
		return

	var data: Variant = item.get_metadata(0)
	if not data is Dictionary:
		return

	match data.get("kind", EntryKind.SUMMARY):
		EntryKind.CARD:
			_show_card_detail(data.resource as Card)
		EntryKind.RELIC:
			_show_relic_detail(data.resource as Relic)
		EntryKind.ENEMY:
			_show_enemy_detail(data.resource as EnemyStats)
		EntryKind.STATUS:
			_show_status_detail(data.resource as Status)
		EntryKind.POTION:
			_show_potion_detail(data.resource as Potion)
		_:
			_show_summary(str(data.get("title", "图鉴")), str(data.get("text", "")))


func _show_summary(summary_title: String, body_text: String) -> void:
	_clear_preview()
	detail_icon.texture = null
	detail_icon.hide()
	detail_title.text = summary_title
	detail_meta.text = "从左侧目录选择条目查看详情"
	detail_text.text = body_text


func _show_card_detail(card: Card) -> void:
	if not card:
		return

	_clear_preview()
	var preview := CARD_MENU_UI_SCENE.instantiate() as CardMenuUI
	preview.card = card
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.scale = Vector2.ONE * 1.15
	preview_slot.add_child(preview)

	detail_icon.show()
	detail_icon.texture = card.icon
	detail_title.text = card.get_display_name()
	detail_meta.text = "卡牌 / %s / %s / %s费 / %s" % [
		_card_profession_label(card),
		_card_type_name(card.type),
		card.cost,
		_card_rarity_name(card.rarity),
	]
	detail_text.text = _format_card_detail(card)


func _show_relic_detail(relic: Relic) -> void:
	if not relic:
		return

	_show_texture_preview(relic.icon, Vector2(150, 150))
	detail_icon.show()
	detail_icon.texture = relic.icon
	detail_title.text = _relic_display_name(relic)
	detail_meta.text = "法宝 / %s / %s" % [_relic_type_name(relic.type), _relic_character_type_name(relic.character_type)]
	detail_text.text = "[b]说明[/b]\n%s\n\n[color=#cdbf92]资源：%s[/color]" % [
		relic.get_tooltip(),
		relic.resource_path,
	]


func _show_enemy_detail(enemy_stats: EnemyStats) -> void:
	if not enemy_stats:
		return

	_show_texture_preview(enemy_stats.art, Vector2(260, 240))
	detail_icon.show()
	detail_icon.texture = enemy_stats.art
	detail_title.text = _enemy_display_name(enemy_stats)
	detail_meta.text = "怪物 / 生命 %s / ID %s" % [enemy_stats.max_health, enemy_stats.id]
	detail_text.text = "[b]描述[/b]\n%s\n\n[b]基础属性[/b]\n生命：%s\n\n[color=#cdbf92]资源：%s[/color]" % [
		_enemy_description(enemy_stats),
		enemy_stats.max_health,
		enemy_stats.resource_path,
	]


func _show_status_detail(status: Status) -> void:
	if not status:
		return

	_show_texture_preview(status.icon, Vector2(130, 130))
	detail_icon.show()
	detail_icon.texture = status.icon
	detail_title.text = _status_display_name(status)
	detail_meta.text = "词条 / %s / %s" % [_status_type_name(status.type), _status_stack_type_name(status.stack_type)]
	detail_text.text = "[b]说明[/b]\n%s\n\n[color=#cdbf92]资源：%s[/color]" % [
		_status_tooltip(status),
		status.resource_path,
	]


func _show_potion_detail(potion: Potion) -> void:
	if not potion:
		return

	_show_texture_preview(potion.icon, Vector2(140, 140))
	detail_icon.show()
	detail_icon.texture = potion.icon
	detail_title.text = _potion_display_name(potion)
	detail_meta.text = "符箓丹药 / %s / %s / %s / %s" % [
		_potion_category_name(potion.category),
		_card_rarity_name(potion.rarity),
		_potion_target_name(potion.target_kind),
		_relic_character_type_name(potion.character_type),
	]
	var usage := "战斗内外均可使用" if potion.usable_out_of_combat else "仅战斗内可用"
	var lines := PackedStringArray()
	lines.append("[b]说明[/b]")
	lines.append(_potion_tooltip(potion))
	var effects_text := _format_potion_effects(potion)
	if not effects_text.is_empty():
		lines.append("")
		lines.append("[b]效果[/b]")
		lines.append(effects_text)
	lines.append("")
	lines.append("[b]使用[/b]")
	lines.append(usage)
	lines.append("")
	lines.append("[color=#cdbf92]资源：%s[/color]" % potion.resource_path)
	detail_text.text = "\n".join(lines)


func _show_texture_preview(texture: Texture, minimum_size: Vector2) -> void:
	_clear_preview()
	var rect := TextureRect.new()
	rect.texture = texture
	rect.custom_minimum_size = minimum_size
	rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	preview_slot.add_child(rect)


func _clear_preview() -> void:
	for child in preview_slot.get_children():
		child.queue_free()


func _format_overview() -> String:
	return "[b]已接入资源[/b]\n卡牌：%s 张\n法宝：%s 件\n怪物：%s 个\n词条：%s 条\n符箓丹药：%s 个\n\n左侧目录已按类型展开，卡牌额外按职业分类。" % [
		all_cards.size(),
		all_relics.size(),
		all_enemies.size(),
		all_statuses.size(),
		all_potions.size(),
	]


func _format_card_summary() -> String:
	var lines := PackedStringArray()
	for scope_name in CARD_SCOPES.keys():
		lines.append("%s：%s 张" % [scope_name, cards_by_scope.get(scope_name, []).size()])
	return "[b]卡牌职业分类[/b]\n%s\n\n选择左侧具体卡牌查看费用、类型、稀有度、元素、标签和效果。" % "\n".join(lines)


func _format_card_scope_summary(scope_name: String, cards: Array) -> String:
	return "[b]%s卡牌[/b]\n共 %s 张。\n\n选择下方卡牌名查看详情。" % [scope_name, cards.size()]


func _format_relic_summary() -> String:
	return "[b]法宝总览[/b]\n已扫描 `res://relics/` 下全部法宝资源，共 %s 件。\n\n包含初始法宝、职业法宝、通用法宝和奖励池法宝。" % all_relics.size()


func _format_enemy_summary() -> String:
	return "[b]怪物总览[/b]\n已扫描 `res://enemies/` 下全部敌人资源，共 %s 个。\n\n选择怪物可查看生命、描述与资源路径。" % all_enemies.size()


func _format_status_summary() -> String:
	return "[b]词条总览[/b]\n已扫描 `res://statuses/` 下全部状态词条，共 %s 条。\n\n选择词条可查看触发时机、叠加方式和说明。" % all_statuses.size()


func _format_potion_summary() -> String:
	return "[b]符箓丹药总览[/b]\n已扫描 `res://potions/` 下全部符箓丹药，共 %s 个。\n\n符箓与丹药为可携带的一次性消耗品，战斗中（部分战斗外）使用，从战斗奖励和商店获取。" % all_potions.size()


func _format_potion_group_summary(label: String, potions: Array) -> String:
	return "[b]%s[/b]\n共 %s 个。\n\n选择下方名称查看详情。" % [label, potions.size()]


func _format_potion_effects(potion: Potion) -> String:
	var lines := PackedStringArray()
	for effect in potion.configured_effects:
		var line := _describe_potion_effect(effect)
		if not line.is_empty():
			lines.append("· %s" % line)
	return "\n".join(lines)


func _describe_potion_effect(effect: Resource) -> String:
	if effect is ConfiguredDamageEffect:
		var dmg := effect as ConfiguredDamageEffect
		return "造成 %s 点伤害%s" % [dmg.amount, _effect_scope_suffix(dmg.target_mode)]
	if effect is ConfiguredBlockEffect:
		return "获得 %s 点护体" % (effect as ConfiguredBlockEffect).amount
	if effect is ConfiguredHealEffect:
		return "回复 %s 点生命" % (effect as ConfiguredHealEffect).amount
	if effect is ConfiguredSelfDamageEffect:
		return "失去 %s 点生命" % (effect as ConfiguredSelfDamageEffect).amount
	if effect is ConfiguredDrawEffect:
		return "抽 %s 张牌" % (effect as ConfiguredDrawEffect).amount
	if effect is ConfiguredManaEffect:
		return "获得 %s 点灵气" % (effect as ConfiguredManaEffect).amount
	if effect is ConfiguredStatusEffect:
		var st := effect as ConfiguredStatusEffect
		var status_name := _status_display_name(st.status) if st.status else "状态"
		var unit := "回合" if st.use_duration else "层"
		return "施加 %s %s%s" % [st.amount, status_name, unit]
	return ""


func _effect_scope_suffix(target_mode: int) -> String:
	match target_mode:
		CardEffect.TargetMode.ALL_ENEMIES:
			return "（所有敌人）"
		CardEffect.TargetMode.EVERYONE:
			return "（全体）"
		CardEffect.TargetMode.PLAYER:
			return "（自身）"
		_:
			return ""


func _format_card_detail(card: Card) -> String:
	var lines := PackedStringArray()
	lines.append("[b]基础信息[/b]")
	lines.append("职业：%s" % _card_profession_label(card))
	lines.append("类型：%s" % _card_type_name(card.type))
	lines.append("稀有度：%s" % _card_rarity_name(card.rarity))
	lines.append("目标：%s" % _card_target_name(card.target))
	lines.append("元素：%s" % _card_element_name(card.element))
	lines.append("费用：%s" % card.cost)
	if card.exhausts:
		lines.append("特性：消耗")
	if card.mechanic_tags.size() > 0:
		lines.append("标签：%s" % "、".join(card.mechanic_tags))
	lines.append("")
	lines.append("[b]效果[/b]")
	lines.append(_card_tooltip(card))
	lines.append("")
	lines.append("[color=#cdbf92]资源：%s[/color]" % card.resource_path)
	return "\n".join(lines)


func _card_tooltip(card: Card) -> String:
	if card is CultivationCard:
		return (card as CultivationCard).get_default_tooltip()
	if not card.tooltip_text.is_empty():
		return card.tooltip_text
	return "暂无说明。"


func _resource_sort_name(resource) -> String:
	if resource is Card:
		return _card_sort_key(resource)
	if resource is Relic:
		return _relic_display_name(resource)
	if resource is EnemyStats:
		return _enemy_display_name(resource)
	if resource is Status:
		return _status_display_name(resource)
	if resource is Potion:
		return _potion_sort_key(resource)
	return str(resource.resource_path)


func _card_sort_key(card: Card) -> String:
	return "%02d_%s_%s" % [card.cost, _card_profession_label(card), card.get_display_name()]


func _scope_key_to_label(scope_key: String) -> String:
	match scope_key:
		"common":
			return "通用"
		"body":
			return "体修"
		"sword":
			return "剑修"
		"demonic":
			return "魔修"
		"beastmaster":
			return "驭兽"
		"fusion":
			return "融合"
		_:
			return "全部"


func _card_profession_label(card: Card) -> String:
	if card.resource_path.contains("fusion_cards"):
		return "融合"

	match card.get_profession():
		Card.Profession.BODY:
			return "体修"
		Card.Profession.SWORD:
			return "剑修"
		Card.Profession.DEMONIC:
			return "魔修"
		Card.Profession.BEASTMASTER:
			return "驭兽"
		_:
			return "通用"


func _card_type_name(type: Card.Type) -> String:
	match type:
		Card.Type.ATTACK:
			return "攻击"
		Card.Type.SKILL:
			return "技能"
		Card.Type.POWER:
			return "能力"
		_:
			return "未知"


func _card_rarity_name(rarity: Card.Rarity) -> String:
	match rarity:
		Card.Rarity.COMMON:
			return "白卡"
		Card.Rarity.UNCOMMON:
			return "蓝卡"
		Card.Rarity.RARE:
			return "金卡"
		Card.Rarity.MYTHIC:
			return "暗金"
		_:
			return "未知"


func _rarity_color(rarity: Card.Rarity) -> Color:
	match rarity:
		Card.Rarity.UNCOMMON:
			return Color("5a9bf0")  # 蓝卡
		Card.Rarity.RARE:
			return Color("f0c85b")  # 金卡
		Card.Rarity.MYTHIC:
			return Color("d98a3d")  # 暗金
		_:
			return Color("e8e6dd")  # 白卡


func _card_target_name(target: Card.Target) -> String:
	match target:
		Card.Target.SELF:
			return "自身"
		Card.Target.SINGLE_ENEMY:
			return "单个敌人"
		Card.Target.ALL_ENEMIES:
			return "所有敌人"
		Card.Target.EVERYONE:
			return "全体"
		_:
			return "未知"


func _card_element_name(element: Card.Element) -> String:
	match element:
		Card.Element.METAL:
			return "金"
		Card.Element.WOOD:
			return "木"
		Card.Element.WATER:
			return "水"
		Card.Element.FIRE:
			return "火"
		Card.Element.EARTH:
			return "土"
		_:
			return "无"


func _relic_display_name(relic: Relic) -> String:
	if not relic.relic_name.is_empty():
		return relic.relic_name
	return relic.id.capitalize()


func _relic_type_name(type: Relic.Type) -> String:
	match type:
		Relic.Type.START_OF_TURN:
			return "回合开始"
		Relic.Type.START_OF_COMBAT:
			return "战斗开始"
		Relic.Type.END_OF_TURN:
			return "回合结束"
		Relic.Type.END_OF_COMBAT:
			return "战斗结束"
		Relic.Type.EVENT_BASED:
			return "事件触发"
		_:
			return "未知"


func _relic_character_type_name(character_type: Relic.CharacterType) -> String:
	match character_type:
		Relic.CharacterType.BODY:
			return "体修专属"
		Relic.CharacterType.SWORD:
			return "剑修专属"
		Relic.CharacterType.DEMONIC:
			return "魔修专属"
		Relic.CharacterType.BEASTMASTER:
			return "驭兽专属"
		_:
			return "通用"


func _enemy_display_name(enemy_stats: EnemyStats) -> String:
	if not enemy_stats.display_name.is_empty():
		return enemy_stats.display_name
	if not enemy_stats.id.is_empty():
		return enemy_stats.id.capitalize()
	return "未知怪物"


func _enemy_description(enemy_stats: EnemyStats) -> String:
	if enemy_stats.description.is_empty():
		return "暂无描述。"
	return enemy_stats.description


func _status_display_name(status: Status) -> String:
	match status.id:
		"exposed":
			return "破绽"
		"muscle":
			return "劲气"
		"qi_flow":
			return "灵息"
		"true_strength_form":
			return "真武形"
		"bleed":
			return "流血"
		"sword_intent":
			return "剑意"
		"energy_charge":
			return "凝气"
		"sword_guard":
			return "剑阵"
		"true_essence":
			return "真元"
		"forge_sword":
			return "铸剑"
		"gold_body":
			return "金身"
		"soul_mark":
			return "魂印"
		"spirit_beast":
			return "灵兽"
		"beast_pack":
			return "兽群"
		_:
			return status.id


func _status_tooltip(status: Status) -> String:
	var tooltip := status.get_tooltip()
	if tooltip.is_empty() and not status.tooltip.is_empty():
		tooltip = status.tooltip
	if tooltip.is_empty():
		return "暂无说明。"
	return tooltip


func _status_type_name(type: Status.Type) -> String:
	match type:
		Status.Type.START_OF_TURN:
			return "回合开始"
		Status.Type.END_OF_TURN:
			return "回合结束"
		Status.Type.EVENT_BASED:
			return "事件触发"
		_:
			return "未知"


func _status_stack_type_name(stack_type: Status.StackType) -> String:
	match stack_type:
		Status.StackType.INTENSITY:
			return "层数叠加"
		Status.StackType.DURATION:
			return "持续回合"
		_:
			return "不可叠加"


func _potion_display_name(potion: Potion) -> String:
	if not potion.potion_name.is_empty():
		return potion.potion_name
	return potion.id.capitalize()


func _potion_sort_key(potion: Potion) -> String:
	# 先符箓后丹药，同类按名称
	return "%d_%s" % [potion.category, _potion_display_name(potion)]


func _potion_tooltip(potion: Potion) -> String:
	if potion.tooltip.is_empty():
		return "暂无说明。"
	return potion.tooltip


func _potion_category_name(category: Potion.Category) -> String:
	match category:
		Potion.Category.TALISMAN:
			return "符箓"
		Potion.Category.PILL:
			return "丹药"
		_:
			return "未知"


func _potion_target_name(target_kind: Potion.TargetKind) -> String:
	match target_kind:
		Potion.TargetKind.SELF:
			return "自身"
		Potion.TargetKind.SINGLE_ENEMY:
			return "单个敌人"
		Potion.TargetKind.ALL_ENEMIES:
			return "所有敌人"
		_:
			return "未知"


func _on_back_pressed() -> void:
	hide()
	get_tree().paused = false
