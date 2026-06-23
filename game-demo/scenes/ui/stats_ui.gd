class_name StatsUI
extends Control

const HEALTH_FILL_WIDTH := 170.0
const BLOCK_FILL_WIDTH := 174.0
const BLOCK_FILL_MIN := 12.0

@onready var block_bar: Control = %BlockBar
@onready var block_bar_fill: ColorRect = %BlockBarFill
@onready var block_bar_highlight: ColorRect = %BlockBarHighlight
@onready var block_label: Label = %BlockLabel
@onready var health_bar_fill: ColorRect = %HealthBarFill
@onready var health_bar_highlight: ColorRect = %HealthBarHighlight
@onready var health_label: Label = %HealthLabel


func update_stats(stats: Stats) -> void:
	var max_health := maxi(stats.max_health, 1)
	var health_ratio := clampf(float(stats.health) / float(max_health), 0.0, 1.0)

	health_label.text = "%s/%s" % [stats.health, stats.max_health]
	health_bar_fill.size.x = HEALTH_FILL_WIDTH * health_ratio
	health_bar_highlight.size.x = HEALTH_FILL_WIDTH * health_ratio

	# 护体蓝条：宽度按护体值相对最大生命缩放，至少留出可见宽度。
	var has_block := stats.block > 0
	block_bar.visible = has_block
	if has_block:
		block_label.text = str(stats.block)
		var block_ratio := clampf(float(stats.block) / float(max_health), 0.0, 1.0)
		var fill_width := maxf(BLOCK_FILL_WIDTH * block_ratio, BLOCK_FILL_MIN)
		block_bar_fill.size.x = fill_width
		block_bar_highlight.size.x = fill_width

	visible = stats.health > 0
