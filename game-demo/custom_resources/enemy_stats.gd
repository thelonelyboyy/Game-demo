class_name EnemyStats
extends Stats

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var ai: PackedScene

@export_group("Phase Two")
@export_range(0.0, 1.0) var phase_two_health_ratio := 0.0
@export var phase_two_name := ""
@export var phase_two_block := 0
@export_range(0.0, 2.0) var phase_two_damage_bonus := 0.0
@export var phase_two_sequence: Array[int] = []
