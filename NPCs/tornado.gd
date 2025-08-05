extends Area2D

@onready var hitbox: Hitbox = $TornadoHitbox

@export var stats: Stats

var current_speed := 20.0
var max_speed := 150.0
var acceleration := 300.0
var arc_strength := 180.0             # Controls how wide the arc is. Higher values mean a sharper curve.
var steering_force := 2.5             # How quickly the tornado adjusts its path to the player.
var lifetime := 2.5
var target: CharacterBody2D
var velocity := Vector2.ZERO
var age := 0.0

func initialize(player_target: CharacterBody2D):
	target = player_target
	velocity = global_position.direction_to(target.global_position) * current_speed

func _physics_process(delta: float):
	age += delta
	if age > lifetime:
		queue_free()
		return

	current_speed += acceleration * delta
	current_speed = min(current_speed, max_speed)

	var direction_to_target = global_position.direction_to(target.global_position)
	hitbox.knockback_vector = direction_to_target
	var desired_velocity = direction_to_target * current_speed
	
	var steering = (desired_velocity - velocity) * steering_force * delta
	var arc_force = direction_to_target.orthogonal() * arc_strength
	velocity += steering
	velocity += arc_force * delta
	
	velocity = velocity.limit_length(current_speed)
	global_position += velocity * delta

func _on_area_entered(area: Area2D):
	if area.name == "Hurtbox":
		queue_free()

func _on_body_entered(_body: Node2D) -> void:
	queue_free()
