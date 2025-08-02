extends Node2D

class_name Laser_Movement

@onready var laser: Laser = $Laser

@export var marker: Marker2D
@export var speed := 30.0

var start_position: Vector2
var target_position: Vector2

func _ready() -> void:
	start_position = global_position
	target_position = marker.global_position

func _physics_process(delta: float) -> void:
	global_position = global_position.move_toward(target_position, speed * delta)
	
	if global_position.distance_to(target_position) < 1:
		if target_position.distance_to(marker.global_position) < 1:
			target_position = start_position
		else:
			target_position = marker.global_position
			
func reset_position():
	global_position = start_position
