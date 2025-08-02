extends CharacterBody2D

@onready var movement_component: Movement_Component = $Movement_Component
@onready var follow_component: Follow_Component = $Follow_Component
@onready var navigation_component: Navigation_Component = $Navigation_Component

@onready var princess: CharacterBody2D = $"../Princess"

@export var stats: Stats

enum {
	MOVE,
	ATTACK,
	FOLLOW,
	NAV
}
var state = NAV

func _ready() -> void:
	follow_component.set_target(princess)

func _physics_process(_delta: float) -> void:
	if state != ATTACK and state != NAV:
		if not Events.is_player_controlled:
			state = MOVE
		else:
			state = FOLLOW

	match state:
		MOVE:
			move_state()
		ATTACK:
			pass
		FOLLOW:
			follow_component.follow()
		NAV:
			navigation_component.update_physics_process()

func move_state():
	var move_direction = movement_component.get_player_input_vector().normalized()
	movement_component.move(move_direction)

func set_nav_state():
	state = NAV
	
func set_follow_state():
	state = FOLLOW
	navigation_component.update_physics_process()

func move_to_position_astar(target_position: Vector2, end_dir := Vector2.ZERO):
	if Events.is_player_controlled:
		state = NAV
		navigation_component.move_to_position_astar(target_position, end_dir)
