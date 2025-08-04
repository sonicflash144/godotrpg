extends Node2D

@onready var start_position = global_position
@onready var target_position = global_position
@onready var timer = $Timer

@export var wander_range: int = 48

func update_start_position(pos: Vector2):
	start_position = pos

func update_target_position():
	var target_vector = Vector2(randf_range(-wander_range, wander_range), randf_range(-wander_range, wander_range))
	target_position = start_position + target_vector

func get_time_left():
	return timer.time_left
	
func start_wander_timer(duration):
	timer.start(duration)

func _on_timer_timeout() -> void:
	update_target_position()
