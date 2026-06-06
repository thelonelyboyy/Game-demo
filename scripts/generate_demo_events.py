#!/usr/bin/env python3
"""Generate configurable event rooms and refresh the event room pool."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = REPO_ROOT / "game-demo"
EVENT_ROOT = PROJECT_ROOT / "scenes" / "event_rooms"

GENERIC_EVENT_SCRIPT = "res://scenes/event_rooms/generic_event.gd"
EVENT_BUTTON_SCENE = "res://scenes/event_rooms/event_room_button.tscn"
EVENT_POOL_SCRIPT = "res://custom_resources/event_room_pool.gd"


@dataclass(frozen=True)
class ChoiceDef:
    text: str
    effect: str
    amount: int


@dataclass(frozen=True)
class EventDef:
    event_id: str
    title: str
    body: str
    choices: tuple[ChoiceDef, ...]


EVENTS = [
    EventDef("ancient_sword_tomb_event", "古剑冢", "半截剑碑从云土里露出，剑意仍在低鸣。", (ChoiceDef("参悟剑痕：随机突破一张牌", "upgrade_random", 0), ChoiceDef("取走残铁：获得 55 灵石", "gain_gold", 55), ChoiceDef("离开", "skip", 0))),
    EventDef("wandering_alchemist_event", "游方丹师", "丹师摆着三只玉瓶，笑说有缘者自取。", (ChoiceDef("买回春丹：花 35 灵石，回复 12 生命", "lose_gold:35|heal:12", 0), ChoiceDef("试药：失去 5 生命，生命上限 +4", "damage:5|max_hp:4", 0), ChoiceDef("谢绝", "skip", 0))),
    EventDef("spirit_spring_event", "灵泉", "岩缝间涌出清泉，灵气温润。", (ChoiceDef("饮泉：回复 10 生命", "heal", 10), ChoiceDef("炼体：失去 4 生命，生命上限 +3", "damage:4|max_hp:3", 0), ChoiceDef("装满水囊：获得 25 灵石", "gain_gold", 25))),
    EventDef("broken_seal_event", "破碎封印", "一道裂开的封印下传来轻微呼吸声。", (ChoiceDef("加固封印：随机突破一张牌", "upgrade_random", 0), ChoiceDef("撬开边角：获得 70 灵石，失去 8 生命", "gain_gold:70|damage:8", 0), ChoiceDef("绕路", "skip", 0))),
    EventDef("market_in_clouds_event", "云上小市", "几位散修在云桥旁支起摊位。", (ChoiceDef("出售杂物：获得 45 灵石", "gain_gold", 45), ChoiceDef("买护身符：花 30 灵石，生命上限 +3", "lose_gold:30|max_hp:3", 0), ChoiceDef("看看就走", "skip", 0))),
    EventDef("hungry_ghost_event", "饿鬼叩门", "一只饿鬼捧着空碗，眼神可怜。", (ChoiceDef("施舍灵石：失去 25 灵石，回复 8 生命", "lose_gold:25|heal:8", 0), ChoiceDef("驱散它：失去 6 生命，获得 50 灵石", "damage:6|gain_gold:50", 0), ChoiceDef("不理会", "skip", 0))),
    EventDef("jade_mirror_event", "照心玉镜", "镜中映出的不是你，而是一手未出的牌。", (ChoiceDef("照见破绽：随机突破一张牌", "upgrade_random", 0), ChoiceDef("打碎玉镜：获得 60 灵石", "gain_gold", 60), ChoiceDef("遮住镜面", "skip", 0))),
    EventDef("thunder_tree_event", "雷击木", "焦黑古树仍有电光在年轮中游走。", (ChoiceDef("引雷淬体：失去 7 生命，生命上限 +5", "damage:7|max_hp:5", 0), ChoiceDef("削下木心：获得 40 灵石", "gain_gold", 40), ChoiceDef("远离雷光", "skip", 0))),
    EventDef("lost_disciple_event", "迷路弟子", "一个小宗弟子在雾里打转，快哭出来了。", (ChoiceDef("指路：获得 35 灵石", "gain_gold", 35), ChoiceDef("护送：回复 9 生命", "heal", 9), ChoiceDef("赶路要紧", "skip", 0))),
    EventDef("demonic_whisper_event", "魔念低语", "耳边的低语许诺力量，也索要代价。", (ChoiceDef("接受：生命上限 +6，失去 8 生命", "max_hp:6|damage:8", 0), ChoiceDef("以剑斩念：随机突破一张牌", "upgrade_random", 0), ChoiceDef("静心离开", "skip", 0))),
    EventDef("rusty_cauldron_event", "锈蚀丹炉", "丹炉盖缝里飘出一缕药香。", (ChoiceDef("开炉：获得 65 灵石", "gain_gold", 65), ChoiceDef("吞服残丹：回复 14 生命", "heal", 14), ChoiceDef("不碰古物", "skip", 0))),
    EventDef("bone_bridge_event", "白骨桥", "桥下云海翻涌，桥面由巨兽白骨搭成。", (ChoiceDef("快步通过：失去 4 生命", "damage", 4), ChoiceDef("拆一截骨材：获得 50 灵石，失去 8 生命", "gain_gold:50|damage:8", 0), ChoiceDef("绕远路", "skip", 0))),
    EventDef("ink_monolith_event", "墨石碑", "石碑上的墨迹像活物一样游动。", (ChoiceDef("临摹碑文：随机突破一张牌", "upgrade_random", 0), ChoiceDef("剥落墨玉：获得 45 灵石", "gain_gold", 45), ChoiceDef("作揖离开", "skip", 0))),
    EventDef("sleeping_beast_event", "沉睡灵兽", "巨兽伏在路旁，呼吸间吐出青色灵雾。", (ChoiceDef("汲取灵雾：回复 11 生命", "heal", 11), ChoiceDef("偷取鳞片：获得 80 灵石，失去 10 生命", "gain_gold:80|damage:10", 0), ChoiceDef("安静离开", "skip", 0))),
    EventDef("sword_rain_event", "剑雨残阵", "半空悬着密密麻麻的断剑，只待有人踏入。", (ChoiceDef("闯阵：随机突破一张牌，失去 6 生命", "upgrade_random:0|damage:6", 0), ChoiceDef("收集断剑：获得 55 灵石", "gain_gold", 55), ChoiceDef("退后", "skip", 0))),
    EventDef("moonlit_ferry_event", "月下渡船", "无桨小舟停在云河边，船夫没有影子。", (ChoiceDef("付船钱：失去 20 灵石，回复 10 生命", "lose_gold:20|heal:10", 0), ChoiceDef("讲价：获得 30 灵石", "gain_gold", 30), ChoiceDef("不渡", "skip", 0))),
    EventDef("red_thread_event", "红线仙", "老妪捻着红线，说能替你剪去一段因果。", (ChoiceDef("剪因果：移除随机一张牌", "remove_random", 0), ChoiceDef("买红线：失去 30 灵石，生命上限 +4", "lose_gold:30|max_hp:4", 0), ChoiceDef("婉拒", "skip", 0))),
    EventDef("fallen_star_event", "坠星坑", "一块星铁砸穿山体，周围还烫着。", (ChoiceDef("拾取星屑：获得 75 灵石，失去 7 生命", "gain_gold:75|damage:7", 0), ChoiceDef("借火炼牌：随机突破一张牌", "upgrade_random", 0), ChoiceDef("离开热坑", "skip", 0))),
    EventDef("silent_dojo_event", "无声道场", "空旷道场里摆着蒲团，似乎仍有人讲法。", (ChoiceDef("坐下听法：随机突破一张牌", "upgrade_random", 0), ChoiceDef("调息：回复 12 生命", "heal", 12), ChoiceDef("继续赶路", "skip", 0))),
    EventDef("merchant_debt_event", "欠债商人", "商人被妖物追得狼狈，怀里却护着钱袋。", (ChoiceDef("帮他解围：获得 60 灵石，失去 5 生命", "gain_gold:60|damage:5", 0), ChoiceDef("收下谢礼：回复 8 生命", "heal", 8), ChoiceDef("别惹麻烦", "skip", 0))),
    EventDef("cursed_bell_event", "摄魂铜铃", "铜铃无风自响，声声敲在识海。", (ChoiceDef("镇压铜铃：随机突破一张牌，失去 5 生命", "upgrade_random:0|damage:5", 0), ChoiceDef("卖给黑市：获得 85 灵石", "gain_gold", 85), ChoiceDef("堵住耳朵", "skip", 0))),
    EventDef("lotus_pond_event", "净莲池", "白莲开在污泥中，香气清冷。", (ChoiceDef("采莲：回复 13 生命", "heal", 13), ChoiceDef("挖莲藕：获得 35 灵石", "gain_gold", 35), ChoiceDef("不扰清净", "skip", 0))),
    EventDef("spirit_tax_collector_event", "灵税小吏", "一个纸面小吏拦路，认真摊开账册。", (ChoiceDef("缴税：失去 25 灵石", "lose_gold", 25), ChoiceDef("辩经：随机突破一张牌", "upgrade_random", 0), ChoiceDef("绕开它", "skip", 0))),
    EventDef("old_battlefield_event", "古战场", "残旗与碎甲埋在云砂里，杀意未散。", (ChoiceDef("搜寻战利品：获得 70 灵石，失去 6 生命", "gain_gold", 70), ChoiceDef("静坐化煞：生命上限 +3", "max_hp", 3), ChoiceDef("快步通过", "skip", 0))),
    EventDef("fox_spirit_inn_event", "狐仙客栈", "客栈门口灯火温柔，掌柜笑得过分好看。", (ChoiceDef("住一晚：失去 35 灵石，回复 16 生命", "lose_gold:35|heal:16", 0), ChoiceDef("讲故事抵账：获得 30 灵石", "gain_gold", 30), ChoiceDef("不进门", "skip", 0))),
    EventDef("cracked_jade_slip_event", "裂纹玉简", "玉简里记录的功法只剩半卷。", (ChoiceDef("强行参悟：随机突破一张牌，失去 6 生命", "upgrade_random:0|damage:6", 0), ChoiceDef("转手卖掉：获得 50 灵石", "gain_gold", 50), ChoiceDef("收好以后再看", "skip", 0))),
    EventDef("blood_moon_shrine_event", "血月小庙", "庙中供奉的神像在血月下睁开一只眼。", (ChoiceDef("献祭：失去 9 生命，生命上限 +7", "damage:9|max_hp:7", 0), ChoiceDef("偷香火钱：获得 90 灵石", "gain_gold", 90), ChoiceDef("退出庙门", "skip", 0))),
    EventDef("cloud_library_event", "云中藏书阁", "散落的书页在空中自行翻动。", (ChoiceDef("读完一卷：随机突破一张牌", "upgrade_random", 0), ChoiceDef("整理书架：获得 40 灵石", "gain_gold", 40), ChoiceDef("合上书页", "skip", 0))),
]


def quote(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def generate_event_scene(event: EventDef) -> str:
    res_path = f"res://scenes/event_rooms/{event.event_id}.tscn"
    path = EVENT_ROOT / f"{event.event_id}.tscn"
    choice_texts = ", ".join(f'"{quote(choice.text)}"' for choice in event.choices)
    choice_effects = ", ".join(f'"{choice.effect}"' for choice in event.choices)
    choice_amounts = ", ".join(str(choice.amount) for choice in event.choices)

    lines = [
        "[gd_scene load_steps=3 format=3]",
        "",
        f'[ext_resource type="Script" path="{GENERIC_EVENT_SCRIPT}" id="1_script"]',
        f'[ext_resource type="PackedScene" path="{EVENT_BUTTON_SCENE}" id="2_button"]',
        "",
        f'[node name="{event.event_id}" type="Control"]',
        "layout_mode = 3",
        "anchors_preset = 15",
        "anchor_right = 1.0",
        "anchor_bottom = 1.0",
        "grow_horizontal = 2",
        "grow_vertical = 2",
        'script = ExtResource("1_script")',
        f'event_title = "{quote(event.title)}"',
        f'event_body = "{quote(event.body)}"',
        f"choice_texts = PackedStringArray({choice_texts})",
        f"choice_effects = PackedStringArray({choice_effects})",
        f"choice_amounts = PackedInt32Array({choice_amounts})",
        "",
        '[node name="ColorRect" type="ColorRect" parent="."]',
        "layout_mode = 1",
        "anchors_preset = 15",
        "anchor_right = 1.0",
        "anchor_bottom = 1.0",
        "grow_horizontal = 2",
        "grow_vertical = 2",
        "color = Color(0.035, 0.031, 0.027, 0.92)",
        "",
        '[node name="VBoxContainer" type="VBoxContainer" parent="."]',
        "layout_mode = 1",
        "anchors_preset = 8",
        "anchor_left = 0.5",
        "anchor_top = 0.5",
        "anchor_right = 0.5",
        "anchor_bottom = 0.5",
        "offset_left = -300.0",
        "offset_top = -230.0",
        "offset_right = 300.0",
        "offset_bottom = 230.0",
        "grow_horizontal = 2",
        "grow_vertical = 2",
        "theme_override_constants/separation = 16",
        "",
        '[node name="TitleLabel" type="Label" parent="VBoxContainer"]',
        "unique_name_in_owner = true",
        "layout_mode = 2",
        "horizontal_alignment = 1",
        "",
        '[node name="BodyLabel" type="Label" parent="VBoxContainer"]',
        "unique_name_in_owner = true",
        "custom_minimum_size = Vector2(560, 90)",
        "layout_mode = 2",
        "autowrap_mode = 3",
        "horizontal_alignment = 1",
        "vertical_alignment = 1",
    ]
    for index in range(1, 4):
        lines.extend([
            "",
            f'[node name="ChoiceButton{index}" parent="VBoxContainer" instance=ExtResource("2_button")]',
            "unique_name_in_owner = true",
            "custom_minimum_size = Vector2(560, 64)",
            "layout_mode = 2",
        ])

    write_text(path, "\n".join(lines) + "\n")
    return res_path


def generate_pool(generated_event_paths: list[str]) -> None:
    existing_paths = [
        "res://scenes/event_rooms/helpful_boi_event.tscn",
        "res://scenes/event_rooms/gamble_event.tscn",
    ]
    all_paths = existing_paths + generated_event_paths
    load_steps = len(all_paths) + 2
    lines = [
        f'[gd_resource type="Resource" script_class="EventRoomPool" load_steps={load_steps} format=3 uid="uid://bncylsfojpqyu"]',
        "",
        f'[ext_resource type="Script" path="{EVENT_POOL_SCRIPT}" id="1_pool"]',
    ]
    for index, path in enumerate(all_paths, start=1):
        lines.append(f'[ext_resource type="PackedScene" path="{path}" id="event_{index}"]')
    refs = ", ".join(f'ExtResource("event_{index}")' for index in range(1, len(all_paths) + 1))
    lines.extend([
        "",
        "[resource]",
        'script = ExtResource("1_pool")',
        f"event_rooms = Array[PackedScene]([{refs}])",
        "",
    ])
    write_text(EVENT_ROOT / "event_room_pool.tres", "\n".join(lines))


def main() -> int:
    generated_paths = [generate_event_scene(event) for event in EVENTS]
    generate_pool(generated_paths)
    print(f"Generated {len(generated_paths)} generic events.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
