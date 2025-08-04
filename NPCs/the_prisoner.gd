extends CharacterBody2D

@onready var health_component: Health_Component = $Health_Component
@onready var movement_component: Movement_Component = $Movement_Component
@onready var follow_component: Follow_Component = $Follow_Component
@onready var navigation_component: Navigation_Component = $Navigation_Component
@onready var wanderController = $WanderController
@onready var attack_timer: Timer = $AttackTimer
@onready var marker = get_node_or_null("../DoorRoom/THE_prisoner_enter_door_room")

@onready var player: CharacterBody2D = $"../Player"
@onready var princess: CharacterBody2D = $"../Princess"

@export var stats: Stats

enum {
	MOVE,
	ATTACK,
	FOLLOW,
	NAV,
	IDLE,
	WANDER
}
var state = NAV
var currentAttack := "bomb"
var has_attacked_in_state := false
var spawned_bombs: Array[Area2D] = []
var spawned_ninja_stars: Array[Area2D] = []
var bomb_scene = load("res://NPCs/bomb.tscn")
var ninja_star_scene = load("res://NPCs/ninja_star.tscn")

func _ready() -> void:
	follow_component.set_target(princess)

func _physics_process(_delta: float) -> void:
	match state:
		ATTACK:
			attack_state()
		FOLLOW:
			follow_component.follow()
		NAV:
			navigation_component.update_physics_process()		
		IDLE:
			movement_component.move(Vector2.ZERO)
			if wanderController.get_time_left() == 0:
				update_wander_timer()
		WANDER:
			if wanderController.get_time_left() == 0 or global_position.distance_to(wanderController.target_position) < 4:
				update_wander_timer()
			
			var direction = global_position.direction_to(wanderController.target_position)
			movement_component.move(direction)

func attack_state():
	movement_component.move(Vector2.ZERO, movement_component.MAX_SPEED, "Attack")
	
	if not has_attacked_in_state:
		if randi() % 2 == 0:
			currentAttack = "bomb"
		else:
			currentAttack = "ninja star"
		has_attacked_in_state = true

func _on_attack_timer_timeout() -> void:
	state = ATTACK
	has_attacked_in_state = false

func attack_animation_finished():
	update_wander_timer()
	if currentAttack == "bomb":
		throw_bomb()
	elif currentAttack == "ninja star":
		throw_ninja_star()

func throw_bomb():
	var target = get_target_player()
	var direct_direction = global_position.direction_to(target.global_position)
	if health_component.get_health_percentage() < 0.5:
		var angle_offset_rad = deg_to_rad(30.0)

		var directions = [
			direct_direction.rotated(-angle_offset_rad),
			direct_direction,
			direct_direction.rotated(angle_offset_rad)
		]

		for i in range(directions.size()):
			var throw_target_position
			if i == 1:
				# The second bomb is aimed directly at the player
				throw_target_position = target.global_position
			else:
				# Calculate a target position along the spread direction
				throw_target_position = global_position + directions[i] * 64 # Adjust distance as needed
			
			spawn_and_launch_bomb(direct_direction, throw_target_position)
			await get_tree().create_timer(0.5).timeout # Stagger the throws
	else:
		spawn_and_launch_bomb(direct_direction, target.global_position)

func spawn_and_launch_bomb(direct_direction: Vector2, target_position: Vector2):
	if state == NAV:
		return
		
	var bomb_instance = bomb_scene.instantiate()
	bomb_instance.global_position = global_position
	bomb_instance.direction = direct_direction
	get_tree().current_scene.add_child(bomb_instance)
	bomb_instance.launch(target_position)
	
	spawned_bombs.append(bomb_instance)
	spawned_bombs = spawned_bombs.filter(func(b): return is_instance_valid(b))

func throw_ninja_star(): 
	var target = get_target_player()
	if health_component.get_health_percentage() < 0.5:
		var base_direction = global_position.direction_to(target.global_position)
		var angle_offset_rad = deg_to_rad(30.0)

		var directions = [
			base_direction.rotated(-angle_offset_rad),
			base_direction,
			base_direction.rotated(angle_offset_rad)
		]
		directions.shuffle()

		for throw_direction in directions:
			spawn_and_throw_star(throw_direction)
			await get_tree().create_timer(0.5).timeout
	else:
		var direction_to_target = global_position.direction_to(target.global_position)
		spawn_and_throw_star(direction_to_target)

func spawn_and_throw_star(direction: Vector2):
	if state == NAV:
		return
		
	var ninja_star_instance = ninja_star_scene.instantiate()
	ninja_star_instance.global_position = global_position
	ninja_star_instance.direction = direction
	get_tree().current_scene.add_child(ninja_star_instance)
	
	spawned_ninja_stars.append(ninja_star_instance)
	spawned_ninja_stars = spawned_ninja_stars.filter(func(n): return is_instance_valid(n))

func update_wander_timer():
	var state_list = [IDLE, WANDER]
	state_list.shuffle()
	state = state_list.pop_front()
	wanderController.start_wander_timer(randf_range(1.0, 2.0))

func handle_death(_area_name: String) -> void:
	attack_timer.stop()
	set_nav_state()
	for bomb in spawned_bombs:
		if is_instance_valid(bomb):
			bomb.queue_free()
	for ninja_star in spawned_ninja_stars:
		if is_instance_valid(ninja_star):
			ninja_star.queue_free()
			
	get_parent().after_the_prisoner_fight()

func set_follow_state():
	state = FOLLOW
	navigation_component.update_physics_process()

func set_nav_state():
	state = NAV
	navigation_component.update_physics_process()

func set_attack_state():
	state = IDLE
	navigation_component.update_physics_process()
	wanderController.update_start_position(marker.global_position)
	attack_timer.start()
	
func get_target_player():
	return player if Events.is_player_controlled else princess
	
func move_to_position_astar(target_position: Vector2, end_dir := Vector2.ZERO, key := ""):
	if Events.is_player_controlled:
		set_nav_state()
		navigation_component.move_to_position_astar(target_position, end_dir, key)
