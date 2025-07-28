extends Control

class_name Health_UI

@onready var fill = $Fill
@onready var background = $BarBackground
@onready var cooldownBar = $TextureProgressBar
@onready var timer = $Timer

var texture_normal = preload("res://UI/Sprites/health bar.png")
var texture_low = preload("res://UI/Sprites/health bar low.png")
var texture_grey = preload("res://UI/Sprites/health bar disabled.png")

var max_fill_width = 0
var maxCooldown: float
var onCooldown := false

func _ready() -> void:
	max_fill_width = fill.size.x
	cooldownBar.value = 0
	
func _physics_process(_delta: float) -> void:
	if onCooldown:
		cooldownBar.value = (timer.time_left / maxCooldown) * 100
	
func update_health(health, MAX_HEALTH, revived := false):
	var ratio = float(health) / MAX_HEALTH
	fill.size.x = ratio * max_fill_width
	
	if ratio <= 0:
		background.texture = texture_low
	elif revived:
		background.texture = texture_grey
	else:
		background.texture = texture_normal

func enable_texture():
	background.texture = texture_normal
	timer.stop()
	
func disable_texture(cooldown := -1.0,):
	if background.texture == texture_low:
		return
	
	background.texture = texture_grey
	if cooldown > 0:
		timer.start(cooldown)
		maxCooldown = cooldown
		onCooldown = true

func _on_timer_timeout() -> void:
	onCooldown = false
