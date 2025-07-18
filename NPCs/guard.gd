extends CharacterBody2D

@onready var navigation_component: Navigation_Component = $Navigation_Component

enum {
	MOVE,
	ATTACK,
	FOLLOW,
	NAV
}
var state = NAV

func move_to_position_astar(target_position: Vector2):
	navigation_component.move_to_position_astar(target_position)
