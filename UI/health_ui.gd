extends Control

class_name Health_UI

@onready var fill = $Fill
@onready var background = $BarBackground

var texture_normal = preload("res://UI/health bar.png")
var texture_low = preload("res://UI/health bar low.png")
var max_fill_width = 0

func _ready():	
	max_fill_width = fill.size.x

func update_health(health, MAX_HEALTH):
	var ratio = float(health) / MAX_HEALTH
	fill.size.x = ratio * max_fill_width
	
	if ratio <= 0.25:
		background.texture = texture_low
	else:
		background.texture = texture_normal
