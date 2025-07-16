extends Control

class_name Health_UI

@onready var fill = $Fill
@onready var background = $BarBackground
@onready var cooldownBar = $TextureProgressBar
@onready var timer = $Timer

var max_fill_width = 0
var texture_normal = preload("res://UI/health bar.png")
var texture_low = preload("res://UI/health bar low.png")
var texture_grey = preload("res://UI/health bar disabled.png")
var texture_disabled
var maxCooldown: float
var onCooldown: bool = false

func _ready():
	max_fill_width = fill.size.x
	texture_disabled = texture_grey
	cooldownBar.value = 0
	
func _physics_process(_delta: float) -> void:
	if onCooldown:
		cooldownBar.value = (timer.time_left / maxCooldown) * 100
	
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
	timer.stop()
	
func disable_texture(cooldown := -1.0):
	background.texture = texture_disabled
	if cooldown > 0 and texture_disabled != texture_low:
		timer.start(cooldown)
		maxCooldown = cooldown
		onCooldown = true

func _on_timer_timeout() -> void:
	onCooldown = false
