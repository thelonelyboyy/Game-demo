class_name StatsUI
extends Control

const HEALTH_FILL_WIDTH := 158.0

@onready var block: HBoxContainer = %Block
@onready var block_label: Label = %BlockLabel
@onready var health_bar_fill: ColorRect = %HealthBarFill
@onready var health_bar_highlight: ColorRect = %HealthBarHighlight
@onready var health_label: Label = %HealthLabel


func update_stats(stats: Stats) -> void:
	var max_health := maxi(stats.max_health, 1)
	var health_ratio := clampf(float(stats.health) / float(max_health), 0.0, 1.0)

	block_label.text = str(stats.block)
	health_label.text = "%s/%s" % [stats.health, stats.max_health]
	health_bar_fill.size.x = HEALTH_FILL_WIDTH * health_ratio
	health_bar_highlight.size.x = HEALTH_FILL_WIDTH * health_ratio
	
	block.visible = stats.block > 0
	visible = stats.health > 0
