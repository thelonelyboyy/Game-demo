# UI Asset Manifest

生成目录：`res://assets/ui/generated/`

视觉规范：国风暗黑修仙、黑金金属边框、暗红与暗紫光效、轻度腐化纹理。所有正式素材均为透明背景 PNG，不包含角色、头像、场景、文字、数字或伪文字。

九宫格边距格式：`left/top/right/bottom`，单位为像素。标记为“否”的素材建议固定尺寸使用。

## Godot 通用接入

- 可拉伸面板：使用 `NinePatchRect`，把 `_9slice.png` 设置到 `texture`，并按表内边距设置 `patch_margin_*`。
- 按钮：使用 `TextureButton`，把 normal/hover/pressed/disabled 对应贴图分别绑定到同名状态。按钮文字用子 `Label` 动态渲染。
- 卡牌：使用 `TextureButton` 或 `Control` 根节点，卡框作为底层 `TextureRect`，卡图、标题、费用、描述全部用子节点动态填充。
- 血条/法力条：使用 `TextureProgressBar`，frame 贴图放 `under` 或额外 `TextureRect`，fill 贴图放 `progress`。
- 图标与装饰：使用 `TextureRect`，保持 `expand_mode` 与 `stretch_mode` 由具体布局决定。禁用态图标直接替换 disabled 文件。
- 推荐导入：Godot Import 中关闭 Mipmaps；像素需要更锐利时关闭 Filter，偏高清 UI 可保留 Filter。

## Panels

| 文件 | 用途 | 尺寸 | 九宫格 | Godot 节点 |
|---|---:|---:|---:|---|
| `panels/codex_screen_outer_frame_9slice.png` | 图鉴全屏外框 | 1920x1080 | 64/64/64/64 | `NinePatchRect` |
| `panels/codex_main_content_panel_9slice.png` | 图鉴主内容面板 | 1400x900 | 48/48/48/48 | `NinePatchRect` |
| `panels/codex_left_nav_panel_9slice.png` | 左侧目录面板 | 420x900 | 48/48/48/48 | `NinePatchRect` |
| `panels/codex_title_plaque_empty.png` | 页面标题空牌 | 520x120 | 否 | `TextureRect` + `Label` |
| `panels/codex_section_title_backplate_9slice.png` | 小节标题底板 | 360x72 | 32/24/32/24 | `NinePatchRect` |
| `panels/codex_preview_scroll_frame.png` | 卷轴预览外框 | 620x500 | 否 | `TextureRect` |
| `panels/codex_preview_image_mask_frame.png` | 图鉴预览图遮罩框 | 560x410 | 否 | `TextureRect` |
| `panels/codex_resource_stat_row_9slice.png` | 资源统计行 normal | 660x96 | 32/24/32/24 | `NinePatchRect` |
| `panels/codex_resource_stat_row_hover_9slice.png` | 资源统计行 hover | 660x96 | 32/24/32/24 | `NinePatchRect` |
| `panels/codex_resource_stat_row_pressed_9slice.png` | 资源统计行 pressed | 660x96 | 32/24/32/24 | `NinePatchRect` |

## Buttons

| 控件组 | 文件 | 用途 | 尺寸 | 九宫格 | Godot 节点 |
|---|---|---:|---:|---:|---|
| 图鉴返回按钮 | `codex_back_button_normal_9slice.png`, `codex_back_button_hover_9slice.png`, `codex_back_button_pressed_9slice.png`, `codex_back_button_disabled_9slice.png` | 返回按钮四态 | 260x74 | 36/24/36/24 | `TextureButton` |
| 目录分组按钮 | `codex_nav_header_normal_9slice.png`, `codex_nav_header_hover_9slice.png`, `codex_nav_header_pressed_9slice.png`, `codex_nav_header_expanded_9slice.png` | 可展开目录 header | 350x58 | 28/18/28/18 | `TextureButton` |
| 目录条目按钮 | `codex_nav_item_normal_9slice.png`, `codex_nav_item_hover_9slice.png`, `codex_nav_item_selected_9slice.png`, `codex_nav_item_disabled_9slice.png` | 子分类列表项 | 330x44 | 24/14/24/14 | `TextureButton` |

## Battle HUD

| 文件 | 用途 | 尺寸 | 九宫格 | Godot 节点 |
|---|---:|---:|---:|---|
| `battle/battle_top_hud_bar_9slice.png` | 顶部 HUD 横条 | 1920x110 | 64/24/64/24 | `NinePatchRect` |
| `battle/battle_round_banner_9slice.png` | 回合数横牌空底 | 340x120 | 56/36/56/36 | `NinePatchRect` + `Label` |
| `battle/battle_player_identity_plate_9slice.png` | 玩家身份信息底板 | 360x88 | 32/24/32/24 | `NinePatchRect` |
| `battle/battle_avatar_empty_frame.png` | 空头像/徽章框 | 120x120 | 否 | `TextureRect` |
| `battle/battle_intent_badge_attack_9slice.png` | 攻击意图徽章 normal | 190x58 | 28/18/28/18 | `NinePatchRect` |
| `battle/battle_intent_badge_attack_hover_9slice.png` | 攻击意图徽章 hover | 190x58 | 28/18/28/18 | `NinePatchRect` |
| `battle/battle_hp_bar_frame_9slice.png` | 生命条金属外框 | 220x30 | 16/8/16/8 | `TextureProgressBar` under |
| `battle/battle_hp_bar_fill.png` | 生命条红色填充 | 192x18 | 否 | `TextureProgressBar` progress |
| `battle/battle_mana_bar_frame_9slice.png` | 法力条金属外框 | 180x24 | 14/7/14/7 | `TextureProgressBar` under |
| `battle/battle_mana_bar_fill.png` | 法力条蓝色填充 | 156x14 | 否 | `TextureProgressBar` progress |
| `battle/battle_energy_orb_frame.png` | 能量球外框 | 230x230 | 否 | `TextureRect` |
| `battle/battle_energy_orb_fill_mask.png` | 能量球紫色填充遮罩 | 180x180 | 否 | `TextureProgressBar` 或 shader mask |
| `battle/battle_draw_pile_panel_9slice.png` | 抽牌堆面板 | 190x92 | 24/20/24/20 | `TextureButton` |
| `battle/battle_discard_pile_panel_9slice.png` | 弃牌堆面板 | 190x92 | 24/20/24/20 | `TextureButton` |
| `battle/battle_element_wheel_base.png` | 元素轮盘底座 | 280x220 | 否 | `TextureRect` |
| `battle/battle_element_slot_empty.png` | 元素槽空态 | 54x54 | 否 | `TextureRect` |
| `battle/battle_element_slot_glow_red.png` | 红元素激活光 | 72x72 | 否 | `TextureRect` |
| `battle/battle_element_slot_glow_blue.png` | 蓝元素激活光 | 72x72 | 否 | `TextureRect` |
| `battle/battle_element_slot_glow_green.png` | 绿元素激活光 | 72x72 | 否 | `TextureRect` |
| `battle/battle_element_slot_glow_yellow.png` | 黄元素激活光 | 72x72 | 否 | `TextureRect` |
| `battle/battle_element_slot_glow_purple.png` | 紫元素激活光 | 72x72 | 否 | `TextureRect` |
| `battle/battle_element_slot_glow_orange.png` | 橙元素激活光 | 72x72 | 否 | `TextureRect` |

## Battle Buttons

| 控件组 | 文件 | 用途 | 尺寸 | 九宫格 | Godot 节点 |
|---|---|---:|---:|---:|---|
| 结束回合按钮 | `battle_end_turn_button_normal_9slice.png`, `battle_end_turn_button_hover_9slice.png`, `battle_end_turn_button_pressed_9slice.png`, `battle_end_turn_button_disabled_9slice.png` | 主操作按钮四态 | 300x96 | 42/28/42/28 | `TextureButton` |
| 牌库按钮 | `battle_deck_button_normal_9slice.png`, `battle_deck_button_hover_9slice.png`, `battle_deck_button_pressed_9slice.png` | 牌库入口三态 | 300x82 | 36/24/36/24 | `TextureButton` |
| 设置按钮 | `battle_settings_button_normal.png`, `battle_settings_button_hover.png`, `battle_settings_button_pressed.png` | 圆形设置入口三态 | 64x64 | 否 | `TextureButton` |
| 功法菱形按钮 | `battle_skill_diamond_button_normal.png`, `battle_skill_diamond_button_hover.png`, `battle_skill_diamond_button_pressed.png` | 功法入口三态 | 96x96 | 否 | `TextureButton` |

## Cards

| 文件 | 用途 | 尺寸 | 九宫格 | Godot 节点 |
|---|---:|---:|---:|---|
| `cards/card_frame_normal.png` | 卡牌外框 normal | 260x380 | 否 | `TextureButton` 或 `TextureRect` |
| `cards/card_frame_hover.png` | 卡牌外框 hover | 260x380 | 否 | `TextureButton` |
| `cards/card_frame_pressed.png` | 卡牌外框 pressed | 260x380 | 否 | `TextureButton` |
| `cards/card_frame_selected.png` | 卡牌外框 selected | 260x380 | 否 | `TextureButton` |
| `cards/card_frame_disabled.png` | 卡牌外框 disabled | 260x380 | 否 | `TextureButton` |
| `cards/card_art_window_frame.png` | 卡图窗口框 | 224x160 | 否 | `TextureRect` |
| `cards/card_title_backplate_9slice.png` | 卡牌标题底板 | 220x44 | 24/12/24/12 | `NinePatchRect` |
| `cards/card_text_box_9slice.png` | 卡牌描述文本框 | 220x116 | 24/18/24/18 | `NinePatchRect` |
| `cards/card_cost_gem_normal.png` | 费用宝石 normal | 76x76 | 否 | `TextureRect` |
| `cards/card_cost_gem_highlight.png` | 费用宝石 highlight | 76x76 | 否 | `TextureRect` |
| `cards/card_type_ribbon_attack.png` | 攻击类型飘带空底 | 120x30 | 否 | `TextureRect` + `Label` |
| `cards/card_type_ribbon_skill.png` | 技能类型飘带空底 | 120x30 | 否 | `TextureRect` + `Label` |

推荐卡牌层级：

```text
CardRoot TextureButton
  Frame TextureRect
  Art TextureRect
  ArtWindowFrame TextureRect
  CostGem TextureRect
  CostLabel Label
  TitleBackplate NinePatchRect
  TitleLabel Label
  TextBox NinePatchRect
  DescriptionLabel RichTextLabel
  TypeRibbon TextureRect
  TypeLabel Label
```

## Icons

| 文件 | 用途 | 尺寸 | 九宫格 | Godot 节点 |
|---|---:|---:|---:|---|
| `icons/icon_resource_heart.png` | 生命资源图标 | 48x48 | 否 | `TextureRect` |
| `icons/icon_resource_coin.png` | 金币资源图标 | 48x48 | 否 | `TextureRect` |
| `icons/icon_resource_book.png` | 功法/书卷入口图标 | 64x64 | 否 | `TextureButton` |
| `icons/icon_settings_gear.png` | 设置齿轮图标 | 48x48 | 否 | `TextureButton` |
| `icons/icon_intent_attack.png` | 攻击意图小图标 | 42x42 | 否 | `TextureRect` |
| `icons/icon_card_deck_stack.png` | 卡组堆叠图标 | 96x64 | 否 | `TextureRect` |
| `icons/icon_codex_overview.png` | 图鉴总览图标 | 64x64 | 否 | `TextureRect` |
| `icons/icon_codex_cards.png` | 图鉴卡牌分类图标 | 64x64 | 否 | `TextureRect` |
| `icons/icon_codex_treasures.png` | 图鉴法宝分类图标 | 64x64 | 否 | `TextureRect` |
| `icons/icon_codex_monsters.png` | 图鉴怪物分类图标 | 64x64 | 否 | `TextureRect` |
| `icons/icon_codex_terms.png` | 图鉴词条分类图标 | 64x64 | 否 | `TextureRect` |
| `icons/icon_codex_potions.png` | 图鉴丹药分类图标 | 64x64 | 否 | `TextureRect` |
| `icons/icon_codex_arrow_right.png` | 折叠箭头右 | 32x32 | 否 | `TextureRect` |
| `icons/icon_codex_arrow_down.png` | 展开箭头下 | 32x32 | 否 | `TextureRect` |
| `icons/icon_codex_overview_disabled.png` | 图鉴总览禁用态 | 64x64 | 否 | `TextureRect` |
| `icons/icon_codex_cards_disabled.png` | 图鉴卡牌禁用态 | 64x64 | 否 | `TextureRect` |
| `icons/icon_codex_treasures_disabled.png` | 图鉴法宝禁用态 | 64x64 | 否 | `TextureRect` |
| `icons/icon_codex_monsters_disabled.png` | 图鉴怪物禁用态 | 64x64 | 否 | `TextureRect` |
| `icons/icon_codex_terms_disabled.png` | 图鉴词条禁用态 | 64x64 | 否 | `TextureRect` |
| `icons/icon_codex_potions_disabled.png` | 图鉴丹药禁用态 | 64x64 | 否 | `TextureRect` |
| `icons/icon_codex_arrow_right_disabled.png` | 折叠箭头右禁用态 | 32x32 | 否 | `TextureRect` |
| `icons/icon_codex_arrow_down_disabled.png` | 展开箭头下禁用态 | 32x32 | 否 | `TextureRect` |

## States

| 文件 | 用途 | 尺寸 | 九宫格 | Godot 节点 |
|---|---:|---:|---:|---|
| `states/state_badge_frame_blue.png` | 蓝色状态徽章框 | 56x56 | 否 | `TextureRect` |
| `states/state_badge_frame_red.png` | 红色状态徽章框 | 56x56 | 否 | `TextureRect` |
| `states/state_badge_frame_purple.png` | 紫色状态徽章框 | 56x56 | 否 | `TextureRect` |
| `states/state_icon_shield.png` | 护盾状态图标 | 48x48 | 否 | `TextureRect` |
| `states/state_icon_flame.png` | 灼烧状态图标 | 48x48 | 否 | `TextureRect` |
| `states/state_icon_sword_mark.png` | 剑痕/攻击标记图标 | 48x48 | 否 | `TextureRect` |
| `states/state_icon_soul_drop.png` | 魂滴/灵魂状态图标 | 48x48 | 否 | `TextureRect` |

## Decorations

| 文件 | 用途 | 尺寸 | 九宫格 | Godot 节点 |
|---|---:|---:|---:|---|
| `decorations/codex_corner_dragon_tl.png` | 图鉴左上角龙纹装饰 | 220x180 | 否 | `TextureRect` |
| `decorations/codex_corner_dragon_tr.png` | 图鉴右上角龙纹装饰 | 220x180 | 否 | `TextureRect` |
| `decorations/codex_corner_dragon_bl.png` | 图鉴左下角龙纹装饰 | 220x180 | 否 | `TextureRect` |
| `decorations/codex_corner_dragon_br.png` | 图鉴右下角龙纹装饰 | 220x180 | 否 | `TextureRect` |
| `decorations/codex_top_divider_ornament_9slice.png` | 顶部分割金属花纹 | 900x64 | 96/16/96/16 | `NinePatchRect` |
| `decorations/codex_header_ring_ornament.png` | 标题环形装饰 | 72x72 | 否 | `TextureRect` |
| `decorations/codex_scrollbar_track_9slice.png` | 图鉴滚动条轨道 | 16x680 | 4/24/4/24 | `VScrollBar` theme texture |
| `decorations/codex_scrollbar_thumb_9slice.png` | 图鉴滚动条滑块 | 16x120 | 4/24/4/24 | `VScrollBar` theme texture |

## Main Menu

| 文件 | 用途 | 尺寸 | 九宫格 | Godot 节点 |
|---|---:|---:|---:|---|
| `panels/main_menu_center_panel_9slice.png` | 主菜单中心按钮容器 | 430x520 | 48/48/48/48 | `NinePatchRect` |
| `panels/main_menu_version_plate_9slice.png` | 版本信息空底板 | 360x86 | 28/18/28/18 | `NinePatchRect` + `Label` |
| `buttons/main_menu_button_normal_9slice.png` | 主菜单按钮 normal | 330x72 | 32/22/32/22 | `TextureButton` |
| `buttons/main_menu_button_hover_9slice.png` | 主菜单按钮 hover | 330x72 | 32/22/32/22 | `TextureButton` |
| `buttons/main_menu_button_pressed_9slice.png` | 主菜单按钮 pressed | 330x72 | 32/22/32/22 | `TextureButton` |
| `buttons/main_menu_button_disabled_9slice.png` | 主菜单按钮 disabled | 330x72 | 32/22/32/22 | `TextureButton` |
| `decorations/main_menu_outer_frame_9slice.png` | 主菜单全屏外框 | 1920x1080 | 72/72/72/72 | `NinePatchRect` |
| `decorations/main_menu_top_dragon_ornament.png` | 顶部龙首装饰 | 360x190 | 否 | `TextureRect` |
| `decorations/main_menu_bottom_center_ornament.png` | 底部中心装饰 | 240x96 | 否 | `TextureRect` |
| `decorations/main_menu_hanging_tag_left.png` | 左侧吊牌空容器 | 150x360 | 否 | `TextureRect` + `Label` |
| `decorations/main_menu_hanging_tag_right.png` | 右侧吊牌空容器 | 150x360 | 否 | `TextureRect` + `Label` |
| `decorations/main_menu_corner_ornament_tl.png` | 主菜单左上角饰 | 190x190 | 否 | `TextureRect` |
| `decorations/main_menu_corner_ornament_tr.png` | 主菜单右上角饰 | 190x190 | 否 | `TextureRect` |
| `decorations/main_menu_corner_ornament_bl.png` | 主菜单左下角饰 | 190x190 | 否 | `TextureRect` |
| `decorations/main_menu_corner_ornament_br.png` | 主菜单右下角饰 | 190x190 | 否 | `TextureRect` |

## Character Select

| 文件 | 用途 | 尺寸 | 九宫格 | Godot 节点 |
|---|---:|---:|---:|---|
| `panels/character_select_info_panel_9slice.png` | 角色详情左面板 | 460x760 | 56/56/56/56 | `NinePatchRect` |
| `panels/character_select_stat_row_9slice.png` | 属性行空底板 | 350x52 | 24/14/24/14 | `NinePatchRect` |
| `panels/character_select_skill_row_9slice.png` | 技能描述行空底板 | 380x112 | 32/24/32/24 | `NinePatchRect` |
| `cards/character_card_frame_normal.png` | 职业卡框 normal | 150x260 | 否 | `TextureButton` |
| `cards/character_card_frame_hover.png` | 职业卡框 hover | 150x260 | 否 | `TextureButton` |
| `cards/character_card_frame_selected.png` | 职业卡框 selected | 150x260 | 否 | `TextureButton` |
| `cards/character_card_frame_disabled.png` | 职业卡框 disabled | 150x260 | 否 | `TextureButton` |
| `cards/character_card_portrait_mask_frame.png` | 职业卡头像窗口框 | 132x190 | 否 | `TextureRect` |
| `buttons/character_select_enter_button_normal_9slice.png` | 入山按钮 normal | 320x104 | 44/30/44/30 | `TextureButton` |
| `buttons/character_select_enter_button_hover_9slice.png` | 入山按钮 hover | 320x104 | 44/30/44/30 | `TextureButton` |
| `buttons/character_select_enter_button_pressed_9slice.png` | 入山按钮 pressed | 320x104 | 44/30/44/30 | `TextureButton` |
| `buttons/character_select_enter_button_disabled_9slice.png` | 入山按钮 disabled | 320x104 | 44/30/44/30 | `TextureButton` |
| `buttons/character_select_back_button_normal_9slice.png` | 返回按钮 normal | 260x74 | 36/24/36/24 | `TextureButton` |
| `buttons/character_select_back_button_hover_9slice.png` | 返回按钮 hover | 260x74 | 36/24/36/24 | `TextureButton` |
| `buttons/character_select_back_button_pressed_9slice.png` | 返回按钮 pressed | 260x74 | 36/24/36/24 | `TextureButton` |
| `icons/character_class_badge_frame.png` | 职业徽章空框 | 96x96 | 否 | `TextureRect` |
| `icons/character_skill_icon_frame.png` | 技能图标空框 | 72x72 | 否 | `TextureRect` |
| `decorations/character_select_card_selected_glow.png` | 职业卡选中光效覆盖层 | 180x290 | 否 | `TextureRect` |

## 验收记录

- Batch 1 和 Batch 2 已完成并登记。
- Batch 3/4/5 已按用户反馈重新使用内置 `image_gen` 源图生成；本地步骤仅做 chroma 抠底、裁切/缩放与尺寸校验。
- 旧程序候选稿已移入 `art/tmp/procedural_batch345_rejected_candidates/`，正式稿不再使用程序绘制造型。
- Batch 3/4/5 本次正式验收文件数：71。
- Batch 6/7 已使用内置 `image_gen` 源图生成；本地步骤仅做 chroma 抠底、裁切/缩放与尺寸校验。
- Batch 6/7 本次正式验收文件数：33。
- 自动检查项：文件存在、`__candidate_a` 存在、PNG 尺寸、`RGBA` 模式、alpha 非空、四角透明。
- 检查结果：`errors=0`。
- 预览图：`art/tmp/imagegen_batch345/batch3_battle_imagegen_preview.png`、`art/tmp/imagegen_batch345/batch4_cards_imagegen_preview.png`、`art/tmp/imagegen_batch345/batch5_imagegen_preview.png`。
- Batch 6/7 预览图：`art/tmp/imagegen_batch67/batch6_main_menu_preview.png`、`art/tmp/imagegen_batch67/batch7_character_select_preview.png`。
