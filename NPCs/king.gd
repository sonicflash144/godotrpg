extends CharacterBody2D

@onready var health_component: Health_Component = $Health_Component
@onready var movement_component: Movement_Component = $Movement_Component
@onready var navigation_component: Navigation_Component = $Navigation_Component
@onready var wanderController = $WanderController
@onready var swordSlowController = $SwordSlowController
@onready var slashHitbox: Hitbox = $SlashHitbox
@onready var attack_timer = $AttackTimer
@onready var spear_timer = $SpearTimer
@onready var attackSound: AudioStreamPlayer = $AttackSound
@onready var defendSound: AudioStreamPlayer = $DefendSound
@onready var slashSound: AudioStreamPlayer = $SlashSound
@onready var marker = $"../arena_center"

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
var MAX_SPEED := 80.0
var current_attack_animation: String
var is_enraged := false
var has_attacked_in_state := false
var slash_direction := Vector2.ZERO
var slash_target_position: Vector2
var spawned_spears: Array[Area2D] = []
var spawned_tornadoes: Array[Area2D] = []
var SPEAR_SCENE = load("res://NPCs/spear.tscn")
var WARNING_SCENE = load("res://NPCs/warning.tscn")
var TORNADO_SCENE = load("res://NPCs/tornado.tscn")

func _physics_process(_delta: float) -> void:
	match state:
		ATTACK:
			if slash_direction != Vector2.ZERO:
				if global_position.distance_to(slash_target_position) < 4.0:
					movement_component.move(Vector2.ZERO, 0, "Slash")
				else:
					movement_component.move(slash_direction)
			else:
				attack_state()
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
	
	var health_percentage = health_component.get_health_percentage()
	if state != NAV and health_percentage < 0.25 and not is_enraged:
		is_enraged = true
		if spear_timer:
			spear_timer.start()
		else:
			set_nav_state()

func slow_enemy():
	swordSlowController.slow_enemy()

func attack_state():
	if health_component.get_health_percentage() <= 0:
		return
		
	var player_position = get_target_player().global_position
	var direction_to_player = global_position.direction_to(player_position)
	
	if current_attack_animation:
		movement_component.move(Vector2.ZERO, movement_component.MAX_SPEED, current_attack_animation)
	else:
		movement_component.move(Vector2.ZERO)
	movement_component.update_animation_direction(direction_to_player)
	
	if has_attacked_in_state:
		return

	var available_attacks = []
	if is_enraged:
		available_attacks = ["Attack"] 
	else:
		available_attacks = ["Attack", "Defend"]
		
	if global_position.distance_to(player_position) <= 64.0:
		available_attacks.append("Slash")
		
	var chosen_attack = available_attacks.pick_random()
	if chosen_attack == "Slash":
		slash_attack(player_position)
	elif chosen_attack == "Attack":
		current_attack_animation = "Attack"
	elif chosen_attack == "Defend":
		current_attack_animation = "Defend"

	has_attacked_in_state = true

func _on_spear_timer_timeout() -> void:
	shoot_spear()

func _on_attack_timer_timeout() -> void:
	state = ATTACK
	has_attacked_in_state = false
	current_attack_animation = ""
	slash_direction = Vector2.ZERO

func shoot_spear():
	defendSound.play()
	var target = get_target_player()
	var target_pos = target.global_position
	var screen_margin = 16.0
	var spawn_area = get_viewport_rect().grow(-screen_margin)

	var diagonal_directions = [
		Vector2(1, 1).normalized(),
		Vector2(1, -1).normalized(),
		Vector2(-1, -1).normalized(),
		Vector2(-1, 1).normalized()
	]
	
	var spawn_distance_from_player = 96.0
	var valid_spawn_directions = []
	
	for direction in diagonal_directions:
		var potential_spawn_point = target_pos + direction * spawn_distance_from_player
		if spawn_area.has_point(potential_spawn_point):
			valid_spawn_directions.append(direction)
	
	if valid_spawn_directions.is_empty():
		return

	if health_component.get_health_percentage() < 0.5 and not is_enraged and valid_spawn_directions.size() > 1:
		var dir1 = valid_spawn_directions.pick_random()
		var remaining_directions = valid_spawn_directions.duplicate()
		remaining_directions.erase(dir1)
		
		var preferred_directions = []
		for dir in remaining_directions:
			if not dir.is_equal_approx(-dir1):
				preferred_directions.append(dir)
		
		var dir2
		if not preferred_directions.is_empty():
			dir2 = preferred_directions.pick_random()
		else:
			dir2 = remaining_directions.pick_random()
			
		spawn_spear_instance(target, target_pos, dir1, spawn_distance_from_player)
		spawn_spear_instance(target, target_pos, dir2, spawn_distance_from_player)
	else:
		var chosen_direction = valid_spawn_directions.pick_random()
		spawn_spear_instance(target, target_pos, chosen_direction, spawn_distance_from_player)

func spawn_spear_instance(target: CharacterBody2D, target_pos: Vector2, direction: Vector2, spawn_distance_from_player: float):
	var spawn_position = target_pos + direction * spawn_distance_from_player

	var spear_instance = SPEAR_SCENE.instantiate()
	get_tree().current_scene.add_child(spear_instance)
	spear_instance.global_position = spawn_position
	
	var offset = spawn_position - target_pos
	spear_instance.initialize(target, offset)
	
	spawned_spears.append(spear_instance)
	spawned_spears = spawned_spears.filter(func(s): return is_instance_valid(s))

func spawn_warning_then_tornado(target: CharacterBody2D, spawn_position: Vector2) -> void:
	var warning_instance = WARNING_SCENE.instantiate()
	get_tree().current_scene.add_child(warning_instance)
	warning_instance.global_position = spawn_position
	
	if warning_instance.has_signal("animation_finished"):
		await warning_instance.animation_finished
	
	spawn_tornado_instance(target, spawn_position)

func shoot_tornado() -> void:
	attackSound.play()

	var target = get_target_player()
	var base_direction = movement_component.animation_tree.get("parameters/Attack/blend_position")
	
	var snapped_direction = Vector2.ZERO
	if abs(base_direction.x) > abs(base_direction.y):
		snapped_direction.x = sign(base_direction.x)
	else:
		snapped_direction.y = sign(base_direction.y)
	if snapped_direction == Vector2.ZERO:
		snapped_direction = Vector2.RIGHT

	if health_component.get_health_percentage() < 0.5 and not is_enraged:
		var directions = [
			snapped_direction,
			snapped_direction.orthogonal(),
			-snapped_direction.orthogonal()
		]
		directions.shuffle()

		for direction in directions:
			var spawn_position = global_position + direction * 16.0
			spawn_warning_then_tornado(target, spawn_position)
			await get_tree().create_timer(0.8).timeout
		if attack_timer:
			attack_timer.start()
		else:
			set_nav_state()
	else:
		var spawn_position = global_position + snapped_direction * 16.0
		spawn_warning_then_tornado(target, spawn_position)

func spawn_tornado_instance(target: CharacterBody2D, spawn_position: Vector2):
	var tornado_instance = TORNADO_SCENE.instantiate()
	get_tree().current_scene.add_child(tornado_instance)
	
	tornado_instance.global_position = spawn_position
	tornado_instance.initialize(target)
	
	spawned_tornadoes.append(tornado_instance)
	spawned_tornadoes = spawned_tornadoes.filter(func(t): return is_instance_valid(t))

func slash_attack(player_position: Vector2):
	slash_target_position = player_position
	slash_direction = global_position.direction_to(slash_target_position)
	slashHitbox.knockback_vector = slash_direction

func play_slash_sound():
	slashSound.play()

func attack_animation_finished(anim_name: String):
	update_wander_timer()
	
	if anim_name == "Attack":
		shoot_tornado()
	elif anim_name == "Defend":
		shoot_spear()
	elif anim_name == "Slash":
		slash_direction = Vector2.ZERO
		
func update_wander_timer():
	var state_list = [IDLE, WANDER]
	state_list.shuffle()
	state = state_list.pop_front()
	wanderController.start_wander_timer(randf_range(1.0, 2.0))

func handle_death(_area_name: String) -> void:
	if not attack_timer:
		return
	attack_timer.queue_free()
	spear_timer.queue_free()
	set_nav_state()
	
	for spear in spawned_spears:
		if is_instance_valid(spear):
			spear.queue_free()
	for tornado in spawned_tornadoes:
		if is_instance_valid(tornado):
			tornado.queue_free()
		
	Events.combat_locked = false
	Events.emit_signal("room_un_combat_locked")
	get_parent().after_king_fight()

func set_nav_state():
	state = NAV
	navigation_component.update_physics_process()

func set_attack_state():
	state = IDLE
	navigation_component.update_physics_process()
	wanderController.update_start_position(marker.global_position)
	if attack_timer:
		attack_timer.start()
	else:
		set_nav_state()

func get_target_player():
	return player if Events.is_player_controlled else princess

func move_to_position_astar(target_position: Vector2, end_dir := Vector2.ZERO, key := ""):
	if Events.is_player_controlled:
		set_nav_state()
		navigation_component.move_to_position_astar(target_position, end_dir, key)
