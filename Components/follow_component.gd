extends Node

class_name Follow_Component

@onready var character: CharacterBody2D = $".."
@onready var movement_component: Movement_Component = $"../Movement_Component"

var target: CharacterBody2D
const FOLLOW_DISTANCE := 32.0

const MAX_PATH_HISTORY := 100
var path_history: Array[Vector2] = []

func _physics_process(_delta: float) -> void:
	if character.velocity.length() > 0:
		path_history.push_back(character.global_position)
		if path_history.size() > MAX_PATH_HISTORY:
			path_history.pop_front()

func set_target(body: CharacterBody2D):
	target = body

func follow():
	var target_path: Array[Vector2] = target.get_node("Follow_Component").path_history
	
	if target_path.is_empty():
		movement_component.move(Vector2.ZERO)
		return
		
	var target_base_velocity = target.velocity - target.get_node("Movement_Component").knockback
	var target_speed = target_base_velocity.length()
	var target_is_moving = target_speed > 1.0
	var follow_speed = target_speed
	
	var points_delay = 0
	if target_speed > 0:
		points_delay = calculate_follow_delay_points(target_speed)
	else:
		var target_max_speed = target.get_node("Movement_Component").MAX_SPEED
		points_delay = calculate_follow_delay_points(target_max_speed)
		follow_speed = target_max_speed
	
	var target_index = max(0, target_path.size() - points_delay)
	var target_position = target_path[target_index]

	var direction_to_target = target_position - character.global_position
	var distance_to_target = character.global_position.distance_to(target.global_position)

	if direction_to_target.length() > 1.0 and (target_is_moving or distance_to_target > FOLLOW_DISTANCE):
		movement_component.move(direction_to_target.normalized(), follow_speed)
	else:
		movement_component.move(Vector2.ZERO)

func calculate_follow_delay_points(speed: float, physics_fps := 60.0) -> int:
	return int((FOLLOW_DISTANCE / speed) * physics_fps)

func clear_path_history():
	path_history.clear()
