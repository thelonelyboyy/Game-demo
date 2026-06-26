# AI UI Asset Plan

## Product Design Brief

- 目标：为 Godot 项目重绘一套可独立组合的游戏 UI 素材库。
- 视觉来源：两张用户提供的游戏成品目标截图，仅作为风格参考，不裁切、不复用截图内容。
- 产品用途：图鉴/目录界面与战斗 HUD，可动态替换文字、数字、头像、卡图、血量、资源数值。
- 交互层级：素材级静态 PNG + Godot 控件状态，覆盖 normal / hover / pressed / disabled / selected 等需要动态切换的状态。
- 输出方式：透明背景 PNG，按类别保存到 `res://assets/ui/generated/`，最后补充 manifest 和 Godot 使用说明。

## 0. 参考与硬性约束

参考图：
- `F:/download/临时美术-图片/AI目标图/图鉴目标.png`：图鉴/目录界面，黑金暗红、卷轴式边框、金属雕花、暗纹面板。
- `F:/download/临时美术-图片/AI目标图/target.png`：战斗 HUD，暗黑修仙、紫蓝法力光、黑金卡框、红色操作按钮、状态徽章。
- `F:/download/临时美术-图片/AI目标图/主页目标.png`：主菜单界面，中心菜单框、纵向菜单按钮、全屏外框、吊牌装饰、龙首/法阵风格。
- `F:/download/临时美术-图片/AI目标图/选人界面目标.png`：选人界面，角色详情面板、职业卡框、选中高亮框、返回按钮、大号入山按钮。

生成原则：
- 只重新绘制 UI 控件，不裁切、不复用截图。
- 不生成角色、场景、头像、完整截图背景、文字、数字、伪文字或 AI 字符。
- 所有素材导出透明背景 PNG；可拉伸控件额外生成 `_9slice` 版本。
- 同类别控件统一边框厚度、金属高光方向、圆角、纹理密度和阴影方向。
- 文字与数值全部由 Godot 动态渲染，图片中只保留空白文字区域。
- 每个控件先生成 3 个候选版本，选最接近参考的一张作为正式版本。
- 每批完成后用 Python 检查：文件名、PNG 尺寸、RGBA/透明通道、九宫格尺寸一致性。

目标目录：

```text
res://assets/ui/generated/
  panels/
  buttons/
  cards/
  battle/
  icons/
  decorations/
  states/
```

## 1. 统一美术规格

- 风格：国风暗黑修仙、黑金、暗红、暗紫、金属雕花、轻度腐化纹理。
- 金属：暗金/古铜外沿，局部磨损，右上或上方暖金高光，左下深阴影。
- 面板底：近黑石纹、烟雾暗纹、低对比度云纹/符纹，不含可读字符。
- 边框：主面板 4-8 px 视觉厚度；小控件 2-4 px；卡牌 5-7 px。
- 圆角：主面板小圆角或切角；按钮和列表项以切角/尖角金属端饰为主。
- 透明策略：内框和装饰保持透明外缘；可拉伸面板中心可半透明暗底。
- 推荐九宫格边距：大型面板 48 px；中型面板 32 px；小列表/按钮 18-24 px；卡牌框不建议拉伸，按固定规格使用。

## 2. 图鉴界面 UI 控件清单

| 类别 | 文件名 | 推荐画布尺寸 | 透明背景 | 九宫格 | 状态 | Godot 推荐节点 |
|---|---:|---:|---|---|---|---|
| panels | `codex_screen_outer_frame_9slice.png` | 1920x1080 | 是 | 是，64/64/64/64 | 无 | `NinePatchRect` |
| panels | `codex_main_content_panel_9slice.png` | 1400x900 | 是 | 是，48/48/48/48 | 无 | `NinePatchRect` |
| panels | `codex_left_nav_panel_9slice.png` | 420x900 | 是 | 是，48/48/48/48 | 无 | `NinePatchRect` |
| panels | `codex_title_plaque_empty.png` | 520x120 | 是 | 否 | 无 | `TextureRect` + `Label` |
| panels | `codex_section_title_backplate_9slice.png` | 360x72 | 是 | 是，32/24/32/24 | 无 | `NinePatchRect` |
| panels | `codex_preview_scroll_frame.png` | 620x500 | 是 | 否 | 无 | `TextureRect` |
| panels | `codex_preview_image_mask_frame.png` | 560x410 | 是 | 否 | 无 | `TextureRect` + `TextureRect` child |
| panels | `codex_resource_stat_row_9slice.png` | 660x96 | 是 | 是，32/24/32/24 | 无 | `NinePatchRect` |
| panels | `codex_resource_stat_row_hover_9slice.png` | 660x96 | 是 | 是，32/24/32/24 | hover | `NinePatchRect` |
| panels | `codex_resource_stat_row_pressed_9slice.png` | 660x96 | 是 | 是，32/24/32/24 | pressed | `NinePatchRect` |
| buttons | `codex_back_button_normal_9slice.png` | 260x74 | 是 | 是，36/24/36/24 | normal | `TextureButton` |
| buttons | `codex_back_button_hover_9slice.png` | 260x74 | 是 | 是，36/24/36/24 | hover | `TextureButton` |
| buttons | `codex_back_button_pressed_9slice.png` | 260x74 | 是 | 是，36/24/36/24 | pressed | `TextureButton` |
| buttons | `codex_back_button_disabled_9slice.png` | 260x74 | 是 | 是，36/24/36/24 | disabled | `TextureButton` |
| buttons | `codex_nav_header_normal_9slice.png` | 350x58 | 是 | 是，28/18/28/18 | normal | `TextureButton` |
| buttons | `codex_nav_header_hover_9slice.png` | 350x58 | 是 | 是，28/18/28/18 | hover | `TextureButton` |
| buttons | `codex_nav_header_pressed_9slice.png` | 350x58 | 是 | 是，28/18/28/18 | pressed | `TextureButton` |
| buttons | `codex_nav_header_expanded_9slice.png` | 350x58 | 是 | 是，28/18/28/18 | toggled | `TextureButton` |
| buttons | `codex_nav_item_normal_9slice.png` | 330x44 | 是 | 是，24/14/24/14 | normal | `TextureButton` |
| buttons | `codex_nav_item_hover_9slice.png` | 330x44 | 是 | 是，24/14/24/14 | hover | `TextureButton` |
| buttons | `codex_nav_item_selected_9slice.png` | 330x44 | 是 | 是，24/14/24/14 | selected | `TextureButton` |
| buttons | `codex_nav_item_disabled_9slice.png` | 330x44 | 是 | 是，24/14/24/14 | disabled | `TextureButton` |
| decorations | `codex_corner_dragon_tl.png` | 220x180 | 是 | 否 | 无 | `TextureRect` |
| decorations | `codex_corner_dragon_tr.png` | 220x180 | 是 | 否 | 无 | `TextureRect` |
| decorations | `codex_corner_dragon_bl.png` | 220x180 | 是 | 否 | 无 | `TextureRect` |
| decorations | `codex_corner_dragon_br.png` | 220x180 | 是 | 否 | 无 | `TextureRect` |
| decorations | `codex_top_divider_ornament_9slice.png` | 900x64 | 是 | 是，96/16/96/16 | 无 | `NinePatchRect` |
| decorations | `codex_header_ring_ornament.png` | 72x72 | 是 | 否 | 无 | `TextureRect` |
| decorations | `codex_scrollbar_track_9slice.png` | 16x680 | 是 | 是，4/24/4/24 | 无 | `NinePatchRect` |
| decorations | `codex_scrollbar_thumb_9slice.png` | 16x120 | 是 | 是，4/24/4/24 | normal/hover/pressed 可选 | `VScrollBar` theme texture |
| icons | `icon_codex_overview.png` | 64x64 | 是 | 否 | normal/disabled | `TextureRect` |
| icons | `icon_codex_cards.png` | 64x64 | 是 | 否 | normal/disabled | `TextureRect` |
| icons | `icon_codex_treasures.png` | 64x64 | 是 | 否 | normal/disabled | `TextureRect` |
| icons | `icon_codex_monsters.png` | 64x64 | 是 | 否 | normal/disabled | `TextureRect` |
| icons | `icon_codex_terms.png` | 64x64 | 是 | 否 | normal/disabled | `TextureRect` |
| icons | `icon_codex_potions.png` | 64x64 | 是 | 否 | normal/disabled | `TextureRect` |
| icons | `icon_codex_arrow_right.png` | 32x32 | 是 | 否 | normal/hover | `TextureRect` |
| icons | `icon_codex_arrow_down.png` | 32x32 | 是 | 否 | normal/hover | `TextureRect` |

## 3. 战斗界面 UI 控件清单

| 类别 | 文件名 | 推荐画布尺寸 | 透明背景 | 九宫格 | 状态 | Godot 推荐节点 |
|---|---:|---:|---|---|---|---|
| battle | `battle_top_hud_bar_9slice.png` | 1920x110 | 是 | 是，64/24/64/24 | 无 | `NinePatchRect` |
| battle | `battle_round_banner_9slice.png` | 340x120 | 是 | 是，56/36/56/36 | 无 | `NinePatchRect` + `Label` |
| battle | `battle_player_identity_plate_9slice.png` | 360x88 | 是 | 是，32/24/32/24 | 无 | `NinePatchRect` |
| battle | `battle_avatar_empty_frame.png` | 120x120 | 是 | 否 | 无 | `TextureRect` |
| battle | `battle_skill_diamond_button_normal.png` | 96x96 | 是 | 否 | normal | `TextureButton` |
| battle | `battle_skill_diamond_button_hover.png` | 96x96 | 是 | 否 | hover | `TextureButton` |
| battle | `battle_skill_diamond_button_pressed.png` | 96x96 | 是 | 否 | pressed | `TextureButton` |
| battle | `battle_deck_button_normal_9slice.png` | 300x82 | 是 | 是，36/24/36/24 | normal | `TextureButton` |
| battle | `battle_deck_button_hover_9slice.png` | 300x82 | 是 | 是，36/24/36/24 | hover | `TextureButton` |
| battle | `battle_deck_button_pressed_9slice.png` | 300x82 | 是 | 是，36/24/36/24 | pressed | `TextureButton` |
| battle | `battle_settings_button_normal.png` | 64x64 | 是 | 否 | normal | `TextureButton` |
| battle | `battle_settings_button_hover.png` | 64x64 | 是 | 否 | hover | `TextureButton` |
| battle | `battle_settings_button_pressed.png` | 64x64 | 是 | 否 | pressed | `TextureButton` |
| battle | `battle_intent_badge_attack_9slice.png` | 190x58 | 是 | 是，28/18/28/18 | normal | `NinePatchRect` |
| battle | `battle_intent_badge_attack_hover_9slice.png` | 190x58 | 是 | 是，28/18/28/18 | hover | `NinePatchRect` |
| battle | `battle_hp_bar_frame_9slice.png` | 220x30 | 是 | 是，16/8/16/8 | 无 | `TextureProgressBar` under/over |
| battle | `battle_hp_bar_fill.png` | 192x18 | 是 | 否 | 无 | `TextureProgressBar` progress |
| battle | `battle_mana_bar_frame_9slice.png` | 180x24 | 是 | 是，14/7/14/7 | 无 | `TextureProgressBar` under/over |
| battle | `battle_mana_bar_fill.png` | 156x14 | 是 | 否 | 无 | `TextureProgressBar` progress |
| battle | `battle_energy_orb_frame.png` | 230x230 | 是 | 否 | 无 | `TextureRect` |
| battle | `battle_energy_orb_fill_mask.png` | 180x180 | 是 | 否 | 无 | `TextureProgressBar` radial or shader mask |
| battle | `battle_draw_pile_panel_9slice.png` | 190x92 | 是 | 是，24/20/24/20 | normal/hover | `TextureButton` |
| battle | `battle_discard_pile_panel_9slice.png` | 190x92 | 是 | 是，24/20/24/20 | normal/hover | `TextureButton` |
| battle | `battle_end_turn_button_normal_9slice.png` | 300x96 | 是 | 是，42/28/42/28 | normal | `TextureButton` |
| battle | `battle_end_turn_button_hover_9slice.png` | 300x96 | 是 | 是，42/28/42/28 | hover | `TextureButton` |
| battle | `battle_end_turn_button_pressed_9slice.png` | 300x96 | 是 | 是，42/28/42/28 | pressed | `TextureButton` |
| battle | `battle_end_turn_button_disabled_9slice.png` | 300x96 | 是 | 是，42/28/42/28 | disabled | `TextureButton` |
| battle | `battle_element_wheel_base.png` | 280x220 | 是 | 否 | 无 | `TextureRect` |
| battle | `battle_element_slot_empty.png` | 54x54 | 是 | 否 | normal/active | `TextureRect` |
| battle | `battle_element_slot_glow_red.png` | 72x72 | 是 | 否 | active | `TextureRect` |
| battle | `battle_element_slot_glow_blue.png` | 72x72 | 是 | 否 | active | `TextureRect` |
| battle | `battle_element_slot_glow_green.png` | 72x72 | 是 | 否 | active | `TextureRect` |
| battle | `battle_element_slot_glow_yellow.png` | 72x72 | 是 | 否 | active | `TextureRect` |
| battle | `battle_element_slot_glow_purple.png` | 72x72 | 是 | 否 | active | `TextureRect` |
| battle | `battle_element_slot_glow_orange.png` | 72x72 | 是 | 否 | active | `TextureRect` |
| cards | `card_frame_normal.png` | 260x380 | 是 | 否 | normal | `TextureButton` or `Control` |
| cards | `card_frame_hover.png` | 260x380 | 是 | 否 | hover | `TextureButton` |
| cards | `card_frame_pressed.png` | 260x380 | 是 | 否 | pressed | `TextureButton` |
| cards | `card_frame_selected.png` | 260x380 | 是 | 否 | selected | `TextureButton` |
| cards | `card_frame_disabled.png` | 260x380 | 是 | 否 | disabled | `TextureButton` |
| cards | `card_art_window_frame.png` | 224x160 | 是 | 否 | 无 | `TextureRect` |
| cards | `card_title_backplate_9slice.png` | 220x44 | 是 | 是，24/12/24/12 | 无 | `NinePatchRect` |
| cards | `card_text_box_9slice.png` | 220x116 | 是 | 是，24/18/24/18 | 无 | `NinePatchRect` |
| cards | `card_cost_gem_normal.png` | 76x76 | 是 | 否 | normal | `TextureRect` |
| cards | `card_cost_gem_highlight.png` | 76x76 | 是 | 否 | highlight | `TextureRect` |
| cards | `card_type_ribbon_attack.png` | 120x30 | 是 | 否 | 无 | `TextureRect` |
| cards | `card_type_ribbon_skill.png` | 120x30 | 是 | 否 | 无 | `TextureRect` |
| icons | `icon_resource_heart.png` | 48x48 | 是 | 否 | normal | `TextureRect` |
| icons | `icon_resource_coin.png` | 48x48 | 是 | 否 | normal | `TextureRect` |
| icons | `icon_resource_book.png` | 64x64 | 是 | 否 | normal | `TextureButton` |
| icons | `icon_card_deck_stack.png` | 96x64 | 是 | 否 | normal | `TextureRect` |
| icons | `icon_settings_gear.png` | 48x48 | 是 | 否 | normal | `TextureButton` |
| icons | `icon_intent_attack.png` | 42x42 | 是 | 否 | normal | `TextureRect` |
| states | `state_badge_frame_blue.png` | 56x56 | 是 | 否 | normal | `TextureRect` |
| states | `state_badge_frame_red.png` | 56x56 | 是 | 否 | normal | `TextureRect` |
| states | `state_badge_frame_purple.png` | 56x56 | 是 | 否 | normal | `TextureRect` |
| states | `state_icon_shield.png` | 48x48 | 是 | 否 | normal | `TextureRect` |
| states | `state_icon_flame.png` | 48x48 | 是 | 否 | normal | `TextureRect` |
| states | `state_icon_sword_mark.png` | 48x48 | 是 | 否 | normal | `TextureRect` |
| states | `state_icon_soul_drop.png` | 48x48 | 是 | 否 | normal | `TextureRect` |

## 4. 生成批次计划

### Batch 1: 基础面板与九宫格

输出目录：`res://assets/ui/generated/panels/`

范围：
- 图鉴外框、主内容面板、左侧目录面板、标题空牌、章节标题底板、资源统计行。
- 优先生成 `_9slice` 版本，确保中心区域干净，可承载动态文字。

检查：
- 所有 `_9slice` 文件必须尺寸可被当前边距安全切分。
- 四角透明；中心区域不得含文字、数字或人物。

### Batch 2: 按钮与列表控件

输出目录：`res://assets/ui/generated/buttons/`

范围：
- 图鉴返回按钮、目录 header、目录 item。
- 战斗结束回合按钮、牌库按钮、设置按钮、技能菱形按钮。

状态：
- 必做：`normal`、`hover`、`pressed`。
- 关键操作按钮额外做：`disabled`。

检查：
- 同一按钮族尺寸完全一致。
- hover 只增加金光/暗红亮边；pressed 只降低亮度并内陷。

### Batch 3: 战斗 HUD 与资源条

输出目录：`res://assets/ui/generated/battle/`

范围：
- 顶部 HUD 条、回合横牌、身份底板、空头像框、意图徽章、HP/法力条、能量球、抽牌堆/弃牌堆面板、元素轮盘。

检查：
- 血条/蓝条 frame 与 fill 尺寸对齐。
- 所有条形素材不得烘焙数值。

### Batch 4: 卡牌系统

输出目录：`res://assets/ui/generated/cards/`

范围：
- 卡框 normal/hover/pressed/selected/disabled。
- 卡牌标题底板、文字框、费用宝石、卡图窗口框、类型小飘带。

检查：
- 卡框尺寸统一 `260x380`。
- 卡图与文字区域保持空白，不生成伪文字。

### Batch 5: 图标、状态与装饰

输出目录：
- `res://assets/ui/generated/icons/`
- `res://assets/ui/generated/states/`
- `res://assets/ui/generated/decorations/`

范围：
- 图鉴分类图标、展开箭头、资源图标、意图图标、状态徽章、四角龙纹、分隔 ornament、滚动条素材。

检查：
- 图标必须在 48/64/96 等统一画布内居中。
- 禁止生成文字和字符形符号；用抽象法器、卡牌叠、兽面、卷轴、丹壶等图形表达类别。

### Batch 6: 主菜单控件

输出目录：
- `res://assets/ui/generated/panels/`
- `res://assets/ui/generated/buttons/`
- `res://assets/ui/generated/decorations/`

范围：
- 主菜单中心面板、纵向菜单按钮、主菜单全屏外框、顶部龙首/中轴装饰、左右吊牌、底部版本信息空底板。

检查：
- 不生成标题文字、标语、版本号或伪文字。
- 按钮中心必须留空，供 Godot 动态渲染菜单文字。
- 吊牌只做装饰容器，不烘焙竖排文字。

### Batch 7: 选人界面控件

输出目录：
- `res://assets/ui/generated/panels/`
- `res://assets/ui/generated/buttons/`
- `res://assets/ui/generated/cards/`
- `res://assets/ui/generated/icons/`
- `res://assets/ui/generated/decorations/`

范围：
- 角色详情左面板、职业头像卡框 normal/hover/selected/disabled、选中发光框、职业徽章底座、属性行底板、技能描述行底板、返回按钮复用/变体、大号入山按钮 normal/hover/pressed/disabled。

检查：
- 不生成角色立绘、头像、职业名称、描述文字、血量数字或资源数值。
- 职业卡框必须留出透明/空白图片区，供动态头像或立绘缩略图叠入。
- 入山按钮不得烘焙文字，只保留金色主操作底座。

## 4.1 主菜单界面 UI 控件清单

| 类别 | 文件名 | 推荐画布尺寸 | 透明背景 | 九宫格 | 状态 | Godot 推荐节点 |
|---|---:|---:|---|---|---|---|
| panels | `main_menu_center_panel_9slice.png` | 430x520 | 是 | 是，48/48/48/48 | 无 | `NinePatchRect` |
| panels | `main_menu_version_plate_9slice.png` | 360x86 | 是 | 是，28/18/28/18 | 无 | `NinePatchRect` + `Label` |
| buttons | `main_menu_button_normal_9slice.png` | 330x72 | 是 | 是，32/22/32/22 | normal | `TextureButton` |
| buttons | `main_menu_button_hover_9slice.png` | 330x72 | 是 | 是，32/22/32/22 | hover | `TextureButton` |
| buttons | `main_menu_button_pressed_9slice.png` | 330x72 | 是 | 是，32/22/32/22 | pressed | `TextureButton` |
| buttons | `main_menu_button_disabled_9slice.png` | 330x72 | 是 | 是，32/22/32/22 | disabled | `TextureButton` |
| decorations | `main_menu_outer_frame_9slice.png` | 1920x1080 | 是 | 是，72/72/72/72 | 无 | `NinePatchRect` |
| decorations | `main_menu_top_dragon_ornament.png` | 360x190 | 是 | 否 | 无 | `TextureRect` |
| decorations | `main_menu_bottom_center_ornament.png` | 240x96 | 是 | 否 | 无 | `TextureRect` |
| decorations | `main_menu_hanging_tag_left.png` | 150x360 | 是 | 否 | 无 | `TextureRect` + `Label` |
| decorations | `main_menu_hanging_tag_right.png` | 150x360 | 是 | 否 | 无 | `TextureRect` + `Label` |
| decorations | `main_menu_corner_ornament_tl.png` | 190x190 | 是 | 否 | 无 | `TextureRect` |
| decorations | `main_menu_corner_ornament_tr.png` | 190x190 | 是 | 否 | 无 | `TextureRect` |
| decorations | `main_menu_corner_ornament_bl.png` | 190x190 | 是 | 否 | 无 | `TextureRect` |
| decorations | `main_menu_corner_ornament_br.png` | 190x190 | 是 | 否 | 无 | `TextureRect` |

## 4.2 选人界面 UI 控件清单

| 类别 | 文件名 | 推荐画布尺寸 | 透明背景 | 九宫格 | 状态 | Godot 推荐节点 |
|---|---:|---:|---|---|---|---|
| panels | `character_select_info_panel_9slice.png` | 460x760 | 是 | 是，56/56/56/56 | 无 | `NinePatchRect` |
| panels | `character_select_stat_row_9slice.png` | 350x52 | 是 | 是，24/14/24/14 | 无 | `NinePatchRect` |
| panels | `character_select_skill_row_9slice.png` | 380x112 | 是 | 是，32/24/32/24 | 无 | `NinePatchRect` |
| cards | `character_card_frame_normal.png` | 150x260 | 是 | 否 | normal | `TextureButton` |
| cards | `character_card_frame_hover.png` | 150x260 | 是 | 否 | hover | `TextureButton` |
| cards | `character_card_frame_selected.png` | 150x260 | 是 | 否 | selected | `TextureButton` |
| cards | `character_card_frame_disabled.png` | 150x260 | 是 | 否 | disabled | `TextureButton` |
| cards | `character_card_portrait_mask_frame.png` | 132x190 | 是 | 否 | 无 | `TextureRect` |
| buttons | `character_select_enter_button_normal_9slice.png` | 320x104 | 是 | 是，44/30/44/30 | normal | `TextureButton` |
| buttons | `character_select_enter_button_hover_9slice.png` | 320x104 | 是 | 是，44/30/44/30 | hover | `TextureButton` |
| buttons | `character_select_enter_button_pressed_9slice.png` | 320x104 | 是 | 是，44/30/44/30 | pressed | `TextureButton` |
| buttons | `character_select_enter_button_disabled_9slice.png` | 320x104 | 是 | 是，44/30/44/30 | disabled | `TextureButton` |
| buttons | `character_select_back_button_normal_9slice.png` | 260x74 | 是 | 是，36/24/36/24 | normal | `TextureButton` |
| buttons | `character_select_back_button_hover_9slice.png` | 260x74 | 是 | 是，36/24/36/24 | hover | `TextureButton` |
| buttons | `character_select_back_button_pressed_9slice.png` | 260x74 | 是 | 是，36/24/36/24 | pressed | `TextureButton` |
| icons | `character_class_badge_frame.png` | 96x96 | 是 | 否 | 无 | `TextureRect` |
| icons | `character_skill_icon_frame.png` | 72x72 | 是 | 否 | 无 | `TextureRect` |
| decorations | `character_select_card_selected_glow.png` | 180x290 | 是 | 否 | selected overlay | `TextureRect` |

## 5. 候选生成与命名规则

每个控件先生成 3 个候选：

```text
<category>/<base_name>__candidate_a.png
<category>/<base_name>__candidate_b.png
<category>/<base_name>__candidate_c.png
```

选中后保存正式文件：

```text
<category>/<base_name>.png
```

九宫格正式文件：

```text
<category>/<base_name>_9slice.png
```

状态命名：

```text
<base_name>_normal.png
<base_name>_hover.png
<base_name>_pressed.png
<base_name>_disabled.png
<base_name>_selected.png
```

## 6. Python 自动检查规则

每批生成后执行检查：
- 文件必须为 `.png`。
- 文件名只允许小写英文、数字、下划线。
- 图片模式必须为 `RGBA`。
- 四角 alpha 应为 0，除非明确是全幅半透明底板。
- 同一控件状态组尺寸必须完全一致。
- `_9slice` 文件必须在 manifest 中登记九宫格边距。
- 不检查文字 OCR，但人工复核时发现伪文字需重生成。

## 7. 后续 Manifest 目标

最终写入 `docs/ui_asset_manifest.md`，包括：
- 每个正式控件的用途。
- 文件路径与尺寸。
- 九宫格边距。
- Godot 节点类型。
- TextureButton 状态绑定方式。
- TextureProgressBar 的 under/progress/over 使用方式。
- 卡牌控件的推荐节点层级。

## 8. 生成进度

### 已完成：Batch 1 基础面板与九宫格

输出目录：
- `res://assets/ui/generated/panels/`

已生成正式文件：
- `codex_screen_outer_frame_9slice.png`
- `codex_main_content_panel_9slice.png`
- `codex_left_nav_panel_9slice.png`
- `codex_title_plaque_empty.png`
- `codex_section_title_backplate_9slice.png`
- `codex_preview_scroll_frame.png`
- `codex_preview_image_mask_frame.png`
- `codex_resource_stat_row_9slice.png`
- `codex_resource_stat_row_hover_9slice.png`
- `codex_resource_stat_row_pressed_9slice.png`

检查结果：
- 全部为 `RGBA` PNG。
- 全部四角透明。
- 九宫格/固定尺寸均符合计划。
- 外框与预览框中心透明，普通面板中心可见。

### 已完成：Batch 2 按钮与列表控件

输出目录：
- `res://assets/ui/generated/buttons/`
- `res://assets/ui/generated/battle/`

已生成正式文件：
- `codex_back_button_normal_9slice.png`
- `codex_back_button_hover_9slice.png`
- `codex_back_button_pressed_9slice.png`
- `codex_back_button_disabled_9slice.png`
- `codex_nav_header_normal_9slice.png`
- `codex_nav_header_hover_9slice.png`
- `codex_nav_header_pressed_9slice.png`
- `codex_nav_header_expanded_9slice.png`
- `codex_nav_item_normal_9slice.png`
- `codex_nav_item_hover_9slice.png`
- `codex_nav_item_selected_9slice.png`
- `codex_nav_item_disabled_9slice.png`
- `battle_end_turn_button_normal_9slice.png`
- `battle_end_turn_button_hover_9slice.png`
- `battle_end_turn_button_pressed_9slice.png`
- `battle_end_turn_button_disabled_9slice.png`
- `battle_deck_button_normal_9slice.png`
- `battle_deck_button_hover_9slice.png`
- `battle_deck_button_pressed_9slice.png`
- `battle_settings_button_normal.png`
- `battle_settings_button_hover.png`
- `battle_settings_button_pressed.png`
- `battle_skill_diamond_button_normal.png`
- `battle_skill_diamond_button_hover.png`
- `battle_skill_diamond_button_pressed.png`

检查结果：
- 全部为 `RGBA` PNG。
- 全部四角透明。
- 同一控件状态组尺寸完全一致。
- 所有按钮均未烘焙文字、数字或图标。

### 已完成：Batch 3 战斗 HUD 与资源条

输出目录：
- `res://assets/ui/generated/battle/`

已生成正式文件：
- `battle_top_hud_bar_9slice.png`
- `battle_round_banner_9slice.png`
- `battle_player_identity_plate_9slice.png`
- `battle_avatar_empty_frame.png`
- `battle_intent_badge_attack_9slice.png`
- `battle_intent_badge_attack_hover_9slice.png`
- `battle_hp_bar_frame_9slice.png`
- `battle_hp_bar_fill.png`
- `battle_mana_bar_frame_9slice.png`
- `battle_mana_bar_fill.png`
- `battle_energy_orb_frame.png`
- `battle_energy_orb_fill_mask.png`
- `battle_draw_pile_panel_9slice.png`
- `battle_discard_pile_panel_9slice.png`
- `battle_element_wheel_base.png`
- `battle_element_slot_empty.png`
- `battle_element_slot_glow_red.png`
- `battle_element_slot_glow_blue.png`
- `battle_element_slot_glow_green.png`
- `battle_element_slot_glow_yellow.png`
- `battle_element_slot_glow_purple.png`
- `battle_element_slot_glow_orange.png`

检查结果：
- 正式文件共 22 个，全部为 `RGBA` PNG。
- 尺寸全部符合计划。
- 四角 alpha 全部为 0。
- 血条/法力条 frame 与 fill 已按计划尺寸对齐。
- 未烘焙文字、数字、头像、角色或场景。
- 已按用户反馈重新使用内置 `image_gen` 源图生成；本地步骤仅做 chroma 抠底、裁切/缩放与尺寸校验。

### 已完成：Batch 4 卡牌系统

输出目录：
- `res://assets/ui/generated/cards/`

已生成正式文件：
- `card_frame_normal.png`
- `card_frame_hover.png`
- `card_frame_pressed.png`
- `card_frame_selected.png`
- `card_frame_disabled.png`
- `card_art_window_frame.png`
- `card_title_backplate_9slice.png`
- `card_text_box_9slice.png`
- `card_cost_gem_normal.png`
- `card_cost_gem_highlight.png`
- `card_type_ribbon_attack.png`
- `card_type_ribbon_skill.png`

检查结果：
- 正式文件共 12 个，全部为 `RGBA` PNG。
- 卡框状态组尺寸统一为 `260x380`。
- 卡图、标题和描述区域均为空，不包含伪文字。
- hover/selected 使用紫色法力边光，pressed 降亮并保留黑金结构。
- 已按用户反馈重新使用内置 `image_gen` 源图生成；本地步骤仅做 chroma 抠底、裁切/缩放与尺寸校验。

### 已完成：Batch 5 图标、状态与装饰

输出目录：
- `res://assets/ui/generated/icons/`
- `res://assets/ui/generated/states/`
- `res://assets/ui/generated/decorations/`

已生成正式文件：
- `icon_resource_heart.png`
- `icon_resource_coin.png`
- `icon_resource_book.png`
- `icon_settings_gear.png`
- `icon_intent_attack.png`
- `icon_codex_overview.png`
- `icon_codex_cards.png`
- `icon_codex_treasures.png`
- `icon_codex_monsters.png`
- `icon_codex_terms.png`
- `icon_codex_potions.png`
- `icon_card_deck_stack.png`
- `icon_codex_arrow_right.png`
- `icon_codex_arrow_down.png`
- `icon_codex_overview_disabled.png`
- `icon_codex_cards_disabled.png`
- `icon_codex_treasures_disabled.png`
- `icon_codex_monsters_disabled.png`
- `icon_codex_terms_disabled.png`
- `icon_codex_potions_disabled.png`
- `icon_codex_arrow_right_disabled.png`
- `icon_codex_arrow_down_disabled.png`
- `state_badge_frame_blue.png`
- `state_badge_frame_red.png`
- `state_badge_frame_purple.png`
- `state_icon_shield.png`
- `state_icon_flame.png`
- `state_icon_sword_mark.png`
- `state_icon_soul_drop.png`
- `codex_corner_dragon_tl.png`
- `codex_corner_dragon_tr.png`
- `codex_corner_dragon_bl.png`
- `codex_corner_dragon_br.png`
- `codex_top_divider_ornament_9slice.png`
- `codex_header_ring_ornament.png`
- `codex_scrollbar_track_9slice.png`
- `codex_scrollbar_thumb_9slice.png`

检查结果：
- 正式文件共 37 个，全部为 `RGBA` PNG。
- 尺寸全部符合计划。
- 四角 alpha 全部为 0，贴边小图标已内缩修正。
- 禁用态图标统一降低亮度和饱和度。
- 未生成文字、数字、头像、角色或场景。
- 已按用户反馈重新使用内置 `image_gen` 源图生成；本地步骤仅做 chroma 抠底、裁切/缩放与尺寸校验。
- 旧程序候选稿已移入 `art/tmp/procedural_batch345_rejected_candidates/`，正式稿不再使用程序绘制造型。
- 预览图：`art/tmp/imagegen_batch345/batch3_battle_imagegen_preview.png`、`art/tmp/imagegen_batch345/batch4_cards_imagegen_preview.png`、`art/tmp/imagegen_batch345/batch5_imagegen_preview.png`。

### 已完成：Batch 6 主菜单控件

输出目录：
- `res://assets/ui/generated/panels/`
- `res://assets/ui/generated/buttons/`
- `res://assets/ui/generated/decorations/`

已生成正式文件：
- `main_menu_center_panel_9slice.png`
- `main_menu_version_plate_9slice.png`
- `main_menu_button_normal_9slice.png`
- `main_menu_button_hover_9slice.png`
- `main_menu_button_pressed_9slice.png`
- `main_menu_button_disabled_9slice.png`
- `main_menu_outer_frame_9slice.png`
- `main_menu_top_dragon_ornament.png`
- `main_menu_bottom_center_ornament.png`
- `main_menu_hanging_tag_left.png`
- `main_menu_hanging_tag_right.png`
- `main_menu_corner_ornament_tl.png`
- `main_menu_corner_ornament_tr.png`
- `main_menu_corner_ornament_bl.png`
- `main_menu_corner_ornament_br.png`

检查结果：
- 正式文件共 15 个，全部为 `RGBA` PNG。
- 尺寸全部符合计划，均保留 `__candidate_a`。
- 四角 alpha 全部小于等于 32。
- 未生成标题文字、标语、版本号、菜单文字或伪文字。
- 使用内置 `image_gen` 源图生成；本地步骤仅做 chroma 抠底、裁切/缩放与尺寸校验。
- 预览图：`art/tmp/imagegen_batch67/batch6_main_menu_preview.png`。

### 已完成：Batch 7 选人界面控件

输出目录：
- `res://assets/ui/generated/panels/`
- `res://assets/ui/generated/buttons/`
- `res://assets/ui/generated/cards/`
- `res://assets/ui/generated/icons/`
- `res://assets/ui/generated/decorations/`

已生成正式文件：
- `character_select_info_panel_9slice.png`
- `character_select_stat_row_9slice.png`
- `character_select_skill_row_9slice.png`
- `character_card_frame_normal.png`
- `character_card_frame_hover.png`
- `character_card_frame_selected.png`
- `character_card_frame_disabled.png`
- `character_card_portrait_mask_frame.png`
- `character_select_enter_button_normal_9slice.png`
- `character_select_enter_button_hover_9slice.png`
- `character_select_enter_button_pressed_9slice.png`
- `character_select_enter_button_disabled_9slice.png`
- `character_select_back_button_normal_9slice.png`
- `character_select_back_button_hover_9slice.png`
- `character_select_back_button_pressed_9slice.png`
- `character_class_badge_frame.png`
- `character_skill_icon_frame.png`
- `character_select_card_selected_glow.png`

检查结果：
- 正式文件共 18 个，全部为 `RGBA` PNG。
- 尺寸全部符合计划，均保留 `__candidate_a`。
- 四角 alpha 全部小于等于 32。
- 职业卡框与头像窗口均保留透明开窗，按钮未烘焙文字。
- 未生成角色立绘、头像、职业名称、描述文字、血量数字或资源数值。
- 使用内置 `image_gen` 源图生成；本地步骤仅做 chroma 抠底、裁切/缩放与尺寸校验。
- `character_select_card_selected_glow.png` 使用 `character_card_frame_selected` 的 Image Gen 源图生成 overlay 版本，以保持选中态风格一致。
- 预览图：`art/tmp/imagegen_batch67/batch7_character_select_preview.png`。
