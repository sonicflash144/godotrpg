extends Control

class_name Health_UI

@onready var fill = $Fill
@onready var background = $BarBackground

var max_fill_width = 0
var texture_normal = preload("res://UI/health bar.png")
var texture_low = preload("res://UI/health bar low.png")
var texture_grey = preload("res://UI/health bar disabled.png")
var texture_disabled

func _ready():
	max_fill_width = fill.size.x
	texture_disabled = texture_grey
	
func update_health(health, MAX_HEALTH):
	var ratio = float(health) / MAX_HEALTH
	fill.size.x = ratio * max_fill_width
	
	if ratio <= 0:
		background.texture = texture_low
		texture_disabled = texture_low
	else:
		background.texture = texture_normal

func enable_texture():
	background.texture = texture_normal
	
func disable_texture():
	background.texture = texture_disabled
