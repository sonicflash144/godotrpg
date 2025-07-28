extends CharacterBody2D

@onready var movement_component: Movement_Component = $Movement_Component
@onready var follow_component: Follow_Component = $Follow_Component
@onready var navigation_component: Navigation_Component = $Navigation_Component

@onready var player: CharacterBody2D = $"../Player"

@export var stats: Stats
@export var equipment: Array[Equipment]

enum {
	MOVE,
	ATTACK,
	FOLLOW,
	NAV
}
var state = FOLLOW
var attackCharged := false
var arrow = load("res://NPCs/arrow.tscn")

func _ready() -> void:
	follow_component.set_target(player)
	if Events.deferred_load_data.is_empty():
		update_stats()

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
			attack_state()
		FOLLOW:
			follow_component.follow()
		NAV:
			navigation_component.update_physics_process()

func update_stats():
	stats.attack = 0
	stats.defense = 0
	for item in equipment:
		stats.attack += item.attack
		stats.defense += item.defense
	Events.update_equipment_abilities(player.equipment, equipment)

func move_state():
	var move_direction = movement_component.get_player_input_vector().normalized()
	movement_component.move(move_direction)
	if Events.controlsEnabled and Input.is_action_just_pressed("attack"):
		state = ATTACK

func attack_state():
	var move_direction = movement_component.get_player_input_vector().normalized()
	movement_component.move(move_direction, movement_component.ATTACK_MOVE_SPEED, "Attack")
	if Input.is_action_just_released("attack"):
		state = MOVE
		if attackCharged and not Events.princessDown:
			shoot_arrow()

func set_nav_state():
	state = NAV
	
func set_follow_state():
	state = FOLLOW
	navigation_component.update_physics_process()

func charge_animation_finished():
	attackCharged = true

func shoot_arrow():
	attackCharged = false
	var base_direction = movement_component.animation_tree.get("parameters/Attack/blend_position")
	const HORIZONTAL_OFFSET := -3
	var angles = [0.0] if not Events.equipment_abilities["Multishot"] else [-10.0, 0.0, 10.0]
	
	var position_offset = Vector2.ZERO
	if base_direction.y == 0 and base_direction.x != 0:
		position_offset.y += HORIZONTAL_OFFSET
	
	for angle in angles:
		var arrow_instance = arrow.instantiate()
		var arrow_direction = base_direction.rotated(deg_to_rad(angle))
		arrow_instance.global_position = global_position + position_offset
		arrow_instance.rotation = arrow_direction.angle()
		arrow_instance.direction = arrow_direction
		get_parent().add_child(arrow_instance)

func move_to_position_astar(target_position: Vector2):
	if Events.is_player_controlled:
		state = NAV
		navigation_component.move_to_position_astar(target_position)
