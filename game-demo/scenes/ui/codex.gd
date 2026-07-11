extends Control

const CARD_MENU_UI_SCENE := preload("res://scenes/ui/card_menu_ui.tscn")

const BACKGROUND_TEXTURE := preload("res://art/backgrounds/main_menu_background_v2.png")
const OVERVIEW_PREVIEW_TEXTURE := preload("res://art/backgrounds/main_menu_background_v2.png")
const OUTER_FRAME_TEXTURE := preload("res://assets/ui/generated/panels/codex_screen_outer_frame_9slice.png")
const LEFT_NAV_PANEL_TEXTURE := preload("res://assets/ui/generated/panels/codex_left_nav_panel_9slice.png")
const MAIN_CONTENT_PANEL_TEXTURE := preload("res://assets/ui/generated/panels/codex_main_content_panel_9slice.png")
const TITLE_PLAQUE_TEXTURE := preload("res://assets/ui/generated/panels/codex_title_plaque_empty.png")
const SECTION_TITLE_TEXTURE := preload("res://assets/ui/generated/panels/codex_section_title_backplate_9slice.png")
const PREVIEW_SCROLL_TEXTURE := preload("res://assets/ui/generated/panels/codex_preview_scroll_frame.png")
const STAT_ROW_TEXTURE := preload("res://assets/ui/generated/panels/codex_resource_stat_row_9slice.png")
const STAT_ROW_HOVER_TEXTURE := preload("res://assets/ui/generated/panels/codex_resource_stat_row_hover_9slice.png")
const BACK_BUTTON_NORMAL_TEXTURE := preload("res://assets/ui/generated/buttons/codex_back_button_normal_9slice.png")
const BACK_BUTTON_HOVER_TEXTURE := preload("res://assets/ui/generated/buttons/codex_back_button_hover_9slice.png")
const BACK_BUTTON_PRESSED_TEXTURE := preload("res://assets/ui/generated/buttons/codex_back_button_pressed_9slice.png")
const BACK_BUTTON_DISABLED_TEXTURE := preload("res://assets/ui/generated/buttons/codex_back_button_disabled_9slice.png")
const NAV_HEADER_NORMAL_TEXTURE := preload("res://assets/ui/generated/buttons/codex_nav_header_normal_9slice.png")
const NAV_HEADER_HOVER_TEXTURE := preload("res://assets/ui/generated/buttons/codex_nav_header_hover_9slice.png")
const NAV_HEADER_EXPANDED_TEXTURE := preload("res://assets/ui/generated/buttons/codex_nav_header_expanded_9slice.png")
const NAV_ITEM_NORMAL_TEXTURE := preload("res://assets/ui/generated/buttons/codex_nav_item_normal_9slice.png")
const NAV_ITEM_HOVER_TEXTURE := preload("res://assets/ui/generated/buttons/codex_nav_item_hover_9slice.png")
const NAV_ITEM_SELECTED_TEXTURE := preload("res://assets/ui/generated/buttons/codex_nav_item_selected_9slice.png")
const CORNER_TL_TEXTURE := preload("res://assets/ui/generated/decorations/codex_corner_dragon_tl.png")
const CORNER_TR_TEXTURE := preload("res://assets/ui/generated/decorations/codex_corner_dragon_tr.png")
const CORNER_BL_TEXTURE := preload("res://assets/ui/generated/decorations/codex_corner_dragon_bl.png")
const CORNER_BR_TEXTURE := preload("res://assets/ui/generated/decorations/codex_corner_dragon_br.png")
const TOP_DIVIDER_TEXTURE := preload("res://assets/ui/generated/decorations/codex_top_divider_ornament_9slice.png")
const HEADER_RING_TEXTURE := preload("res://assets/ui/generated/decorations/codex_header_ring_ornament.png")
const ICON_OVERVIEW := preload("res://assets/ui/generated/icons/icon_codex_overview.png")
const ICON_CARDS := preload("res://assets/ui/generated/icons/icon_codex_cards.png")
const ICON_RELICS := preload("res://assets/ui/generated/icons/icon_codex_treasures.png")
const ICON_ENEMIES := preload("res://assets/ui/generated/icons/icon_codex_monsters.png")
const ICON_STATUS := preload("res://assets/ui/generated/icons/icon_codex_terms.png")
const ICON_POTIONS := preload("res://assets/ui/generated/icons/icon_codex_potions.png")
const ICON_ARROW_RIGHT := preload("res://assets/ui/generated/icons/icon_codex_arrow_right.png")
const ICON_ARROW_DOWN := preload("res://assets/ui/generated/icons/icon_codex_arrow_down.png")

const REFERENCE_SIZE := Vector2(1672.0, 941.0)
const PANEL_TEXTURE_MARGINS := Vector4(48.0, 48.0, 48.0, 48.0)
const OUTER_FRAME_MARGINS := Vector4(64.0, 64.0, 64.0, 64.0)
const BUTTON_TEXTURE_MARGINS := Vector4(36.0, 24.0, 36.0, 24.0)
const NAV_HEADER_MARGINS := Vector4(28.0, 18.0, 28.0, 18.0)
const NAV_ITEM_MARGINS := Vector4(24.0, 14.0, 24.0, 14.0)
const SECTION_TITLE_MARGINS := Vector4(32.0, 24.0, 32.0, 24.0)
const STAT_ROW_MARGINS := Vector4(32.0, 24.0, 32.0, 24.0)

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
@onready var background: TextureRect = $Background
@onready var atmosphere: ColorRect = $Atmosphere
@onready var root_content: Control = $RootContent
@onready var directory_panel: PanelContainer = %DirectoryPanel
@onready var directory_margin: MarginContainer = %DirectoryMargin
@onready var directory_vbox: VBoxContainer = %DirectoryVBox
@onready var directory_title: Label = %DirectoryTitle
@onready var directory: Tree = %Directory
@onready var detail_panel: PanelContainer = %DetailPanel
@onready var detail_margin: MarginContainer = %DetailMargin
@onready var detail_vbox: VBoxContainer = %DetailVBox
@onready var detail_header: HBoxContainer = %DetailHeader
@onready var header_ring: TextureRect = %HeaderRing
@onready var detail_icon: TextureRect = %DetailIcon
@onready var detail_title: Label = %DetailTitle
@onready var detail_meta: Label = %DetailMeta
@onready var detail_body: HBoxContainer = %DetailBody
@onready var detail_left_column: VBoxContainer = %DetailLeftColumn
@onready var detail_scroll: ScrollContainer = %DetailScroll
@onready var detail_text: RichTextLabel = %DetailText
@onready var preview_panel: Control = %PreviewPanel
@onready var preview_slot: CenterContainer = %PreviewSlot
@onready var preview_frame: TextureRect = %PreviewFrame
@onready var overview_stats_panel: VBoxContainer = %OverviewStatsPanel
@onready var overview_stats_title: Label = %OverviewStatsTitle
@onready var overview_stats: VBoxContainer = %OverviewStats
@onready var back_button: Button = %BackButton

var all_cards: Array = []
var cards_by_scope := {}
var all_relics: Array = []
var all_enemies: Array = []
var all_statuses: Array = []
var all_potions: Array = []
var display_font: SystemFont


var _detail_swap_tween: Tween


func _ready() -> void:
	InkTheme.animate_screen_entrance(self)
	InkTheme.wire_button_sfx(back_button)
	back_button.pressed.connect(_on_back_pressed)
	directory.item_selected.connect(_on_directory_item_selected)
	get_viewport().size_changed.connect(_apply_layout)
	_polish_scene()
	_collect_all_data()
	_build_directory()
	_show_summary("图鉴总览", _format_overview())


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


func _polish_scene() -> void:
	_setup_fonts()
	_apply_background()
	_apply_decorations()
	_apply_panel_styles()
	_apply_tree_style()
	_apply_text_style()
	_apply_layout()


func _setup_fonts() -> void:
	display_font = SystemFont.new()
	display_font.font_names = PackedStringArray([
		"STKaiti",
		"KaiTi",
		"FZKai-Z03",
		"Microsoft YaHei UI",
		"Microsoft YaHei",
		"Noto Sans CJK SC",
		"SimHei",
	])


func _apply_background() -> void:
	background.texture = BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.modulate = Color(0.58, 0.54, 0.50, 0.92)
	background.z_index = -100

	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	atmosphere.color = Color(0.012, 0.010, 0.008, 0.62)
	atmosphere.z_index = -80


func _apply_decorations() -> void:
	_ensure_nine_patch("OuterFrame", OUTER_FRAME_TEXTURE, OUTER_FRAME_MARGINS, false, 1)
	_ensure_nine_patch("TopDivider", TOP_DIVIDER_TEXTURE, Vector4(96.0, 16.0, 96.0, 16.0), false, 7)
	_ensure_texture_rect("TitlePlaque", TITLE_PLAQUE_TEXTURE, 5)
	_ensure_texture_rect("CornerTopLeft", CORNER_TL_TEXTURE, 9)
	_ensure_texture_rect("CornerTopRight", CORNER_TR_TEXTURE, 9)
	_ensure_texture_rect("CornerBottomLeft", CORNER_BL_TEXTURE, 9)
	_ensure_texture_rect("CornerBottomRight", CORNER_BR_TEXTURE, 9)
	root_content.z_index = 20
	header_ring.texture = HEADER_RING_TEXTURE
	preview_frame.texture = PREVIEW_SCROLL_TEXTURE
	preview_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_frame.stretch_mode = TextureRect.STRETCH_SCALE
	preview_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _apply_panel_styles() -> void:
	directory_panel.add_theme_stylebox_override(
		"panel",
		_make_texture_style(LEFT_NAV_PANEL_TEXTURE, PANEL_TEXTURE_MARGINS, Vector4(28.0, 28.0, 26.0, 28.0), Color(0.98, 0.94, 0.84, 0.98))
	)
	detail_panel.add_theme_stylebox_override(
		"panel",
		_make_texture_style(MAIN_CONTENT_PANEL_TEXTURE, PANEL_TEXTURE_MARGINS, Vector4(52.0, 46.0, 46.0, 38.0), Color(0.94, 0.91, 0.84, 0.94))
	)
	back_button.flat = false
	back_button.focus_mode = Control.FOCUS_ALL
	back_button.add_theme_stylebox_override("normal", _make_texture_style(BACK_BUTTON_NORMAL_TEXTURE, BUTTON_TEXTURE_MARGINS, Vector4(28.0, 8.0, 28.0, 8.0), Color(1, 1, 1, 0.98)))
	back_button.add_theme_stylebox_override("hover", _make_texture_style(BACK_BUTTON_HOVER_TEXTURE, BUTTON_TEXTURE_MARGINS, Vector4(28.0, 8.0, 28.0, 8.0), Color(1.08, 1.02, 0.92, 1.0), Vector4(7.0, 0.0, 7.0, 0.0)))
	back_button.add_theme_stylebox_override("pressed", _make_texture_style(BACK_BUTTON_PRESSED_TEXTURE, BUTTON_TEXTURE_MARGINS, Vector4(28.0, 8.0, 28.0, 8.0), Color(0.84, 0.72, 0.62, 1.0)))
	back_button.add_theme_stylebox_override("disabled", _make_texture_style(BACK_BUTTON_DISABLED_TEXTURE, BUTTON_TEXTURE_MARGINS, Vector4(28.0, 8.0, 28.0, 8.0), Color(0.55, 0.50, 0.45, 0.62)))


func _apply_tree_style() -> void:
	directory.hide_root = true
	directory.scroll_horizontal_enabled = false
	directory.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	directory.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	directory.add_theme_stylebox_override("selected", _make_texture_style(NAV_ITEM_SELECTED_TEXTURE, NAV_ITEM_MARGINS, Vector4(12.0, 4.0, 12.0, 4.0), Color(1.05, 0.96, 0.78, 1.0), Vector4(8.0, 0.0, 8.0, 0.0)))
	directory.add_theme_stylebox_override("selected_focus", _make_texture_style(NAV_ITEM_SELECTED_TEXTURE, NAV_ITEM_MARGINS, Vector4(12.0, 4.0, 12.0, 4.0), Color(1.08, 0.98, 0.80, 1.0), Vector4(8.0, 0.0, 8.0, 0.0)))
	directory.add_theme_stylebox_override("hovered", _make_texture_style(NAV_ITEM_HOVER_TEXTURE, NAV_ITEM_MARGINS, Vector4(12.0, 4.0, 12.0, 4.0), Color(1.0, 0.98, 0.90, 0.96), Vector4(6.0, 0.0, 6.0, 0.0)))
	directory.add_theme_icon_override("arrow", ICON_ARROW_DOWN)
	directory.add_theme_icon_override("arrow_collapsed", ICON_ARROW_RIGHT)
	directory.add_theme_color_override("font_color", Color("cdbb8a"))
	directory.add_theme_color_override("font_hovered_color", Color("ffe5a2"))
	directory.add_theme_color_override("font_selected_color", Color("fff0bd"))
	directory.add_theme_color_override("guide_color", Color(0.74, 0.47, 0.22, 0.18))


func _apply_text_style() -> void:
	title.add_theme_font_override("font", display_font)
	title.add_theme_color_override("font_color", Color("ffe3a4"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.90))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 5)
	title.add_theme_constant_override("outline_size", 2)
	title.add_theme_color_override("font_outline_color", Color(0.15, 0.06, 0.02, 0.92))

	directory_title.add_theme_font_override("font", display_font)
	directory_title.add_theme_color_override("font_color", Color("f1cf86"))
	directory_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.76))
	directory_title.add_theme_constant_override("shadow_offset_x", 2)
	directory_title.add_theme_constant_override("shadow_offset_y", 2)

	detail_title.add_theme_font_override("font", display_font)
	InkTheme.apply_body_label(detail_title, 34)
	InkTheme.apply_body_label(detail_meta, 20)
	detail_title.add_theme_color_override("font_color", Color("f0c85b"))
	detail_meta.add_theme_color_override("font_color", Color("cdbf92"))
	detail_text.add_theme_color_override("default_color", Color("eee7d2"))
	overview_stats_title.add_theme_font_override("font", display_font)
	overview_stats_title.add_theme_color_override("font_color", Color("efcf86"))
	overview_stats_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.78))
	overview_stats_title.add_theme_constant_override("shadow_offset_x", 2)
	overview_stats_title.add_theme_constant_override("shadow_offset_y", 2)
	back_button.add_theme_font_override("font", display_font)
	back_button.add_theme_color_override("font_color", Color("ffe6b0"))
	back_button.add_theme_color_override("font_hover_color", Color("fff3c8"))
	back_button.add_theme_color_override("font_pressed_color", Color("d9aa63"))
	back_button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.82))
	back_button.add_theme_constant_override("shadow_offset_x", 2)
	back_button.add_theme_constant_override("shadow_offset_y", 2)


func _apply_layout() -> void:
	var view_size := get_viewport_rect().size
	var scale := _ui_scale(view_size)

	_set_control_rect(background, Vector2.ZERO, view_size)
	_set_control_rect(atmosphere, Vector2.ZERO, view_size)
	_set_control_rect(root_content, Vector2.ZERO, view_size)
	_layout_decorations(view_size, scale)

	var content_pos := Vector2(22.0, 38.0) * scale
	var bottom_reserved := 18.0 * scale
	var content_size := Vector2(
		maxf(720.0 * scale, view_size.x - content_pos.x * 2.0),
		maxf(430.0 * scale, view_size.y - content_pos.y - bottom_reserved)
	)
	var left_width: float = minf(430.0 * scale, content_size.x * 0.30)
	var gap := 18.0 * scale
	var detail_width: float = maxf(460.0 * scale, content_size.x - left_width - gap)
	var detail_x := content_pos.x + left_width + gap - 110.0 * scale

	_set_control_rect(directory_panel, content_pos, Vector2(left_width, content_size.y))
	_set_control_rect(detail_panel, Vector2(detail_x, content_pos.y), Vector2(detail_width, content_size.y))
	directory_panel.z_index = 2
	detail_panel.z_index = 1

	var title_size := Vector2(560.0, 104.0) * scale
	_set_control_rect(title, Vector2((view_size.x - title_size.x) * 0.5, 11.0 * scale), title_size)
	title.add_theme_font_size_override("font_size", int(round(58.0 * scale)))

	var back_size := Vector2(260.0, 74.0) * scale
	_set_control_rect(back_button, Vector2((view_size.x - back_size.x) * 0.5, view_size.y - back_size.y - 18.0 * scale), back_size)
	back_button.add_theme_font_size_override("font_size", int(round(31.0 * scale)))

	directory_margin.add_theme_constant_override("margin_left", int(round(28.0 * scale)))
	directory_margin.add_theme_constant_override("margin_top", int(round(22.0 * scale)))
	directory_margin.add_theme_constant_override("margin_right", int(round(24.0 * scale)))
	directory_margin.add_theme_constant_override("margin_bottom", int(round(20.0 * scale)))
	directory_vbox.add_theme_constant_override("separation", int(round(10.0 * scale)))
	directory_title.custom_minimum_size = Vector2(0, 44.0 * scale)
	directory_title.add_theme_font_size_override("font_size", int(round(28.0 * scale)))
	directory.add_theme_font_size_override("font_size", int(round(20.0 * scale)))
	directory.add_theme_constant_override("item_margin", int(round(12.0 * scale)))
	directory.add_theme_constant_override("inner_item_margin_top", int(round(5.0 * scale)))
	directory.add_theme_constant_override("inner_item_margin_bottom", int(round(5.0 * scale)))
	directory.add_theme_constant_override("h_separation", int(round(8.0 * scale)))
	directory.add_theme_constant_override("v_separation", int(round(3.0 * scale)))

	detail_margin.add_theme_constant_override("margin_left", int(round(54.0 * scale)))
	detail_margin.add_theme_constant_override("margin_top", int(round(56.0 * scale)))
	detail_margin.add_theme_constant_override("margin_right", int(round(48.0 * scale)))
	detail_margin.add_theme_constant_override("margin_bottom", int(round(34.0 * scale)))
	detail_vbox.add_theme_constant_override("separation", int(round(18.0 * scale)))
	detail_header.add_theme_constant_override("separation", int(round(12.0 * scale)))
	detail_body.add_theme_constant_override("separation", int(round(34.0 * scale)))
	detail_left_column.add_theme_constant_override("separation", int(round(18.0 * scale)))

	header_ring.custom_minimum_size = Vector2(46.0, 46.0) * scale
	detail_icon.custom_minimum_size = Vector2(62.0, 62.0) * scale
	detail_title.add_theme_font_size_override("font_size", int(round(33.0 * scale)))
	detail_meta.add_theme_font_size_override("font_size", int(round(18.0 * scale)))
	detail_text.add_theme_font_size_override("normal_font_size", int(round(20.0 * scale)))
	detail_text.add_theme_font_size_override("bold_font_size", int(round(22.0 * scale)))
	detail_text.add_theme_constant_override("line_separation", int(round(5.0 * scale)))

	preview_panel.custom_minimum_size = Vector2(520.0, 365.0) * scale
	preview_slot.offset_left = 40.0 * scale
	preview_slot.offset_top = 42.0 * scale
	preview_slot.offset_right = -40.0 * scale
	preview_slot.offset_bottom = -42.0 * scale
	overview_stats_panel.custom_minimum_size = Vector2(555.0, 0.0) * scale
	overview_stats_panel.add_theme_constant_override("separation", int(round(18.0 * scale)))
	overview_stats_title.custom_minimum_size = Vector2(0, 44.0 * scale)
	overview_stats_title.add_theme_font_size_override("font_size", int(round(25.0 * scale)))
	overview_stats.add_theme_constant_override("separation", int(round(14.0 * scale)))

	_build_overview_stats()
	_apply_mode_layout(overview_stats_panel.visible)


func _layout_decorations(view_size: Vector2, scale: float) -> void:
	var outer := get_node_or_null("OuterFrame") as NinePatchRect
	if outer:
		_set_control_rect(outer, Vector2(8.0, 8.0) * scale, view_size - Vector2(16.0, 16.0) * scale)
		outer.modulate = Color(1.0, 0.88, 0.68, 0.74)

	var top_divider := get_node_or_null("TopDivider") as NinePatchRect
	if top_divider:
		var divider_size := Vector2(view_size.x - 280.0 * scale, 58.0 * scale)
		_set_control_rect(top_divider, Vector2((view_size.x - divider_size.x) * 0.5, 43.0 * scale), divider_size)
		top_divider.modulate = Color(1.0, 0.80, 0.55, 0.84)

	var title_plaque := get_node_or_null("TitlePlaque") as TextureRect
	if title_plaque:
		var plaque_size := Vector2(560.0, 112.0) * scale
		_set_control_rect(title_plaque, Vector2((view_size.x - plaque_size.x) * 0.5, -2.0 * scale), plaque_size)
		title_plaque.modulate = Color(1.0, 0.82, 0.56, 0.48)

	var corner_size := Vector2(220.0, 180.0) * scale
	_set_named_rect("CornerTopLeft", Vector2(6.0, 4.0) * scale, corner_size, Color(1.0, 0.82, 0.62, 0.78))
	_set_named_rect("CornerTopRight", Vector2(view_size.x - corner_size.x - 6.0 * scale, 4.0 * scale), corner_size, Color(1.0, 0.82, 0.62, 0.78))
	_set_named_rect("CornerBottomLeft", Vector2(6.0 * scale, view_size.y - corner_size.y - 4.0 * scale), corner_size, Color(1.0, 0.72, 0.50, 0.58))
	_set_named_rect("CornerBottomRight", Vector2(view_size.x - corner_size.x - 6.0 * scale, view_size.y - corner_size.y - 4.0 * scale), corner_size, Color(1.0, 0.72, 0.50, 0.58))


func _build_overview_stats() -> void:
	if not is_instance_valid(overview_stats):
		return

	for child in overview_stats.get_children():
		overview_stats.remove_child(child)
		child.queue_free()

	var entries := [
		{"label": "卡牌", "count": all_cards.size(), "unit": "张", "icon": ICON_CARDS},
		{"label": "法宝", "count": all_relics.size(), "unit": "件", "icon": ICON_RELICS},
		{"label": "怪物", "count": all_enemies.size(), "unit": "个", "icon": ICON_ENEMIES},
		{"label": "词条", "count": all_statuses.size(), "unit": "条", "icon": ICON_STATUS},
		{"label": "符箓丹药", "count": all_potions.size(), "unit": "个", "icon": ICON_POTIONS},
	]
	var scale := _ui_scale(get_viewport_rect().size)
	for entry: Dictionary in entries:
		overview_stats.add_child(_make_stat_row(
			str(entry["label"]),
			int(entry["count"]),
			str(entry["unit"]),
			entry["icon"] as Texture2D,
			scale
		))


func _make_stat_row(label_text: String, count: int, unit: String, icon: Texture2D, scale: float) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 82.0 * scale)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override(
		"panel",
		_make_texture_style(STAT_ROW_TEXTURE, STAT_ROW_MARGINS, Vector4(32.0, 10.0, 24.0, 10.0), Color(1, 1, 1, 0.94))
	)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", int(round(28.0 * scale)))
	margin.add_theme_constant_override("margin_top", int(round(8.0 * scale)))
	margin.add_theme_constant_override("margin_right", int(round(24.0 * scale)))
	margin.add_theme_constant_override("margin_bottom", int(round(8.0 * scale)))
	row.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", int(round(20.0 * scale)))
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(hbox)

	var icon_rect := TextureRect.new()
	icon_rect.texture = icon
	icon_rect.custom_minimum_size = Vector2(54.0, 54.0) * scale
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon_rect)

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", display_font)
	label.add_theme_font_size_override("font_size", int(round(25.0 * scale)))
	label.add_theme_color_override("font_color", Color("edd49a"))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.76))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	hbox.add_child(label)

	var count_label := Label.new()
	count_label.text = str(count)
	count_label.custom_minimum_size = Vector2(112.0, 0.0) * scale
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_font_override("font", display_font)
	count_label.add_theme_font_size_override("font_size", int(round(45.0 * scale)))
	count_label.add_theme_color_override("font_color", Color("ffd597"))
	count_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.86))
	count_label.add_theme_constant_override("shadow_offset_x", 3)
	count_label.add_theme_constant_override("shadow_offset_y", 3)
	hbox.add_child(count_label)

	var unit_label := Label.new()
	unit_label.text = unit
	unit_label.custom_minimum_size = Vector2(38.0, 0.0) * scale
	unit_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	unit_label.add_theme_font_override("font", display_font)
	unit_label.add_theme_font_size_override("font_size", int(round(22.0 * scale)))
	unit_label.add_theme_color_override("font_color", Color("e2c584"))
	unit_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.76))
	unit_label.add_theme_constant_override("shadow_offset_x", 2)
	unit_label.add_theme_constant_override("shadow_offset_y", 2)
	hbox.add_child(unit_label)

	return row


func _set_overview_mode(is_overview: bool) -> void:
	overview_stats_panel.visible = is_overview
	header_ring.visible = true
	preview_panel.visible = true
	_apply_mode_layout(is_overview)


func _apply_mode_layout(is_overview: bool) -> void:
	if not is_inside_tree():
		return
	var scale := _ui_scale(get_viewport_rect().size)
	if is_overview:
		detail_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		detail_scroll.custom_minimum_size = Vector2(0.0, 84.0 * scale)
		detail_text.fit_content = false
		detail_text.custom_minimum_size = Vector2(0.0, 84.0 * scale)
		preview_panel.custom_minimum_size = Vector2(520.0, 390.0) * scale
	else:
		detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		detail_scroll.custom_minimum_size = Vector2.ZERO
		detail_text.fit_content = true
		detail_text.custom_minimum_size = Vector2.ZERO
		preview_panel.custom_minimum_size = Vector2(500.0, 350.0) * scale


func _show_overview_preview() -> void:
	_clear_preview()
	var scale := _ui_scale(get_viewport_rect().size)
	var rect := TextureRect.new()
	rect.texture = OVERVIEW_PREVIEW_TEXTURE
	rect.custom_minimum_size = Vector2(430.0, 285.0) * scale
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.modulate = Color(0.78, 0.66, 0.50, 0.96)
	preview_slot.add_child(rect)


func _set_named_rect(node_name: String, position: Vector2, size: Vector2, color: Color) -> void:
	var node := get_node_or_null(node_name) as TextureRect
	if not node:
		return
	_set_control_rect(node, position, size)
	node.modulate = color


func _ensure_texture_rect(node_name: String, texture: Texture2D, z: int = 0) -> TextureRect:
	var rect := get_node_or_null(node_name) as TextureRect
	if rect == null:
		rect = TextureRect.new()
		rect.name = node_name
		add_child(rect)
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = z
	return rect


func _ensure_nine_patch(node_name: String, texture: Texture2D, margins: Vector4, draw_center: bool, z: int = 0) -> NinePatchRect:
	var rect := get_node_or_null(node_name) as NinePatchRect
	if rect == null:
		rect = NinePatchRect.new()
		rect.name = node_name
		add_child(rect)
	rect.texture = texture
	rect.patch_margin_left = int(margins.x)
	rect.patch_margin_top = int(margins.y)
	rect.patch_margin_right = int(margins.z)
	rect.patch_margin_bottom = int(margins.w)
	rect.draw_center = draw_center
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = z
	return rect


func _set_control_rect(control: Control, position: Vector2, size: Vector2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	control.position = position
	control.size = size


func _make_texture_style(
	texture: Texture2D,
	texture_margins: Vector4,
	content_margins: Vector4 = Vector4(12.0, 8.0, 12.0, 8.0),
	tint: Color = Color.WHITE,
	expand_margins: Vector4 = Vector4.ZERO,
	draw_center: bool = true
) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = tint
	style.draw_center = draw_center
	style.expand_margin_left = expand_margins.x
	style.expand_margin_top = expand_margins.y
	style.expand_margin_right = expand_margins.z
	style.expand_margin_bottom = expand_margins.w
	style.set_texture_margin(SIDE_LEFT, texture_margins.x)
	style.set_texture_margin(SIDE_TOP, texture_margins.y)
	style.set_texture_margin(SIDE_RIGHT, texture_margins.z)
	style.set_texture_margin(SIDE_BOTTOM, texture_margins.w)
	style.set_content_margin(SIDE_LEFT, content_margins.x)
	style.set_content_margin(SIDE_TOP, content_margins.y)
	style.set_content_margin(SIDE_RIGHT, content_margins.z)
	style.set_content_margin(SIDE_BOTTOM, content_margins.w)
	return style


func _ui_scale(view_size: Vector2) -> float:
	var width_scale: float = view_size.x / REFERENCE_SIZE.x
	var height_scale: float = view_size.y / REFERENCE_SIZE.y
	var raw_scale: float = width_scale if width_scale < height_scale else height_scale
	return clampf(raw_scale, 0.62, 1.16)


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
		scope_item.collapsed = true
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
	while first_card_scope and first_card_scope.get_text(0).begins_with("全部"):
		first_card_scope = first_card_scope.get_next()
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
	var icon := _icon_for_summary(title_text)
	if icon:
		item.set_icon(0, icon)
		item.set_icon_max_width(0, int(round(28.0 * _ui_scale(get_viewport_rect().size))))
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
	var icon := _icon_for_entry_kind(kind)
	if icon:
		item.set_icon(0, icon)
		item.set_icon_max_width(0, int(round(22.0 * _ui_scale(get_viewport_rect().size))))
	item.set_metadata(0, {
		"kind": kind,
		"resource": resource,
	})
	match kind:
		EntryKind.CARD:
			item.set_custom_color(0, Color("e8d2a0"))
		EntryKind.RELIC:
			item.set_custom_color(0, Color("f0d28a"))
		EntryKind.ENEMY:
			item.set_custom_color(0, Color("d7aa78"))
		EntryKind.STATUS:
			item.set_custom_color(0, Color("cdbf92"))
		EntryKind.POTION:
			item.set_custom_color(0, Color("dfc783"))
	return item


func _icon_for_summary(title_text: String) -> Texture2D:
	match title_text:
		"图鉴总览":
			return ICON_OVERVIEW
		"卡牌":
			return ICON_CARDS
		"法宝":
			return ICON_RELICS
		"怪物":
			return ICON_ENEMIES
		"词条":
			return ICON_STATUS
		"符箓丹药":
			return ICON_POTIONS
		_:
			return null


func _icon_for_entry_kind(kind: EntryKind) -> Texture2D:
	match kind:
		EntryKind.CARD:
			return ICON_CARDS
		EntryKind.RELIC:
			return ICON_RELICS
		EntryKind.ENEMY:
			return ICON_ENEMIES
		EntryKind.STATUS:
			return ICON_STATUS
		EntryKind.POTION:
			return ICON_POTIONS
		_:
			return null


func _on_directory_item_selected() -> void:
	var item := directory.get_selected()
	if not item:
		return

	var data: Variant = item.get_metadata(0)
	if not data is Dictionary:
		return

	# 翻页感：条目切换时详情面板淡入 + 翻书音。
	GameSfx.play(GameSfx.BOOK, -8.0)
	_animate_detail_swap()

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


func _animate_detail_swap() -> void:
	if not detail_vbox:
		return
	if _detail_swap_tween and _detail_swap_tween.is_running():
		_detail_swap_tween.kill()
	detail_vbox.modulate = Color(1, 1, 1, 0.0)
	_detail_swap_tween = detail_vbox.create_tween()
	_detail_swap_tween.tween_property(detail_vbox, "modulate:a", 1.0, 0.18) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _show_summary(summary_title: String, body_text: String) -> void:
	var is_overview := summary_title == "图鉴总览"
	_set_overview_mode(is_overview)
	detail_icon.texture = null
	detail_icon.hide()
	detail_title.text = summary_title
	detail_meta.text = "大道三千，万物皆可入道。" if is_overview else "从左侧目录选择条目查看详情"
	detail_text.text = _format_overview_intro() if is_overview else body_text
	if is_overview:
		_build_overview_stats()
		_show_overview_preview()
	else:
		_clear_preview()


func _show_card_detail(card: Card) -> void:
	if not card:
		return

	_clear_preview()
	var preview := CARD_MENU_UI_SCENE.instantiate() as CardMenuUI
	preview.card = card
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.scale = Vector2.ONE * (1.05 * _ui_scale(get_viewport_rect().size))
	preview_slot.add_child(preview)

	_set_overview_mode(false)
	detail_icon.show()
	detail_icon.texture = card.icon
	detail_title.text = card.get_display_name()
	detail_meta.text = "卡牌 / %s / %s / %s / %s" % [
		_card_profession_label(card),
		_card_display_type_name(card),
		_card_cost_label(card),
		_card_rarity_name(card.rarity),
	]
	detail_text.text = _format_card_detail(card)


func _show_relic_detail(relic: Relic) -> void:
	if not relic:
		return

	_set_overview_mode(false)
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

	_set_overview_mode(false)
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

	_set_overview_mode(false)
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

	_set_overview_mode(false)
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
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	preview_slot.add_child(rect)


func _clear_preview() -> void:
	for child in preview_slot.get_children():
		preview_slot.remove_child(child)
		child.queue_free()


func _format_overview_intro() -> String:
	return "大道三千，万物皆可入道。此间收录修真界中所见所闻，包括各类卡牌、法宝、怪物、词条、符箓丹药等详尽资料，助道友明心见性，问鼎长生。"


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
	if _is_discover_effect(effect):
		var discover = effect
		return "发现：展示 %s 张，选择 %s 张加入手牌" % [
			discover.choices_to_show,
			maxi(1, discover.amount),
		]
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


func _is_discover_effect(effect: Resource) -> bool:
	return (
		effect
		and effect.get_script()
		and str(effect.get_script().resource_path).ends_with("configured_discover_effect.gd")
	)


func _format_card_detail(card: Card) -> String:
	var lines := PackedStringArray()
	lines.append("[b]基础信息[/b]")
	lines.append("职业：%s" % _card_profession_label(card))
	lines.append("类型：%s" % _card_display_type_name(card))
	lines.append("稀有度：%s" % _card_rarity_name(card.rarity))
	lines.append("目标：%s" % _card_target_name(card.target))
	lines.append("元素：%s" % _card_element_name(card.element))
	lines.append("费用：%s" % ("不可打出" if card.blocks_manual_play() else card.get_cost_text()))
	var traits := PackedStringArray()
	if card.is_status_card():
		traits.append("状态牌")
	if card.is_curse_card():
		traits.append("诅咒牌")
	if card.is_retained_card():
		traits.append("保留")
	if card.is_innate_card():
		traits.append("固有")
	if card.is_temporary_card():
		traits.append("临时")
	if card.is_consumable_card():
		traits.append("消耗")
	if card.is_ethereal_card():
		traits.append("虚无")
	if card.is_unplayable_card():
		traits.append("不可打出")
	if card.has_discard_trigger():
		traits.append("弃牌触发")
	if card.has_exhaust_trigger():
		traits.append("消耗触发")
	if card.is_growth_card():
		traits.append("成长")
	if not traits.is_empty():
		lines.append("特性：%s" % "、".join(traits))
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
	var sort_cost := 99 if card.is_x_cost() else card.cost
	return "%02d_%s_%s" % [sort_cost, _card_profession_label(card), card.get_display_name()]


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


func _card_display_type_name(card: Card) -> String:
	if card.is_curse_card():
		return "诅咒牌"
	if card.is_status_card():
		return "状态牌"
	return _card_type_name(card.type)


func _card_cost_label(card: Card) -> String:
	if card.blocks_manual_play():
		return "不可打出"
	return "%s费" % card.get_cost_text()


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
