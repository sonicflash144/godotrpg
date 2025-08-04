extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox = $BombHitbox
@onready var hitboxCollisionShape = $BombHitbox/CollisionShape2D

@export var stats: Stats
@export var throw_duration: float = 0.6  # How long the throw takes in seconds.
@export var throw_height: float = 64.0   # How high the arc goes in pixels.

const SHOCKWAVE_SCENE = preload("res://NPCs/shockwave_controller.tscn")

var direction := Vector2.ZERO
var start_position: Vector2
var target_position: Vector2
var time_elapsed: float = 0.0

func _ready() -> void:
	set_physics_process(false)
	hitbox.knockback_vector = direction

func launch(target: Vector2) -> void:
	start_position = global_position
	target_position = target
	time_elapsed = 0.0
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	time_elapsed += delta
	
	# Calculate the throw's progress as a value from 0.0 to 1.0.
	var progress = min(time_elapsed / throw_duration, 1.0)
	
	# 1. HORIZONTAL MOVEMENT (Ground Position)
	# Linearly interpolate the bomb's actual position along the ground.
	global_position = start_position.lerp(target_position, progress)
	
	# 2. VERTICAL MOVEMENT (Visual Arc)
	# This formula creates a parabola. As `progress` goes from 0 to 1,
	# `arc_height` will go from 0 up to `throw_height` and back down to 0.
	var arc_height = -4 * throw_height * progress * (progress - 1)
	
	# Apply the calculated height as a vertical offset to the sprite.
	# We use a negative value because in Godot's 2D coordinates, Y is down.
	animated_sprite.position.y = -arc_height
	
	# 3. LANDING
	# When the progress is complete, land the bomb.
	if progress >= 1.0:
		# Snap to the final position and reset the sprite's visuals.
		global_position = target_position
		animated_sprite.position = Vector2.ZERO
		animated_sprite.scale = Vector2.ONE
		
		# Stop the physics process and play the explosion animation.
		set_physics_process(false)
		animated_sprite.play("Start")
		
		hitboxCollisionShape.set_deferred("disabled", false)

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "Start":
		if SHOCKWAVE_SCENE:
			var shockwave_instance = SHOCKWAVE_SCENE.instantiate()
			get_parent().add_child(shockwave_instance)
			shockwave_instance.global_position = global_position
		queue_free()
