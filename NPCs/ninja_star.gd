extends Area2D

@onready var hitbox: Hitbox = $NinjaStarHitbox

@export var stats: Stats

var direction := Vector2.ZERO
var speed := 20.0
var MAX_SPEED := 400.0
var acceleration := 500.0

func _ready() -> void:
	hitbox.knockback_vector = direction
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if speed < MAX_SPEED:
		speed += acceleration * delta
		speed = min(speed, MAX_SPEED)
	
	global_position += direction * speed * delta

func _on_body_entered(_body: Node2D) -> void:
	queue_free()
