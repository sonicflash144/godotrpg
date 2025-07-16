extends CharacterBody2D

@onready var hurtbox = $Hurtbox
@onready var blinkAnimationPlayer = $BlinkAnimationPlayer
@onready var animationTree = $AnimationTree
@onready var animationState = animationTree.get("parameters/playback")
@onready var navigationAgent = $NavigationAgent2D
@onready var tilemap = $"../TileMapLayer"
@onready var player: CharacterBody2D = $"../Player"

enum {
	MOVE,
	FOLLOW,
	NAV
}
var state

# --- Path History (for being followed) ---
var path_history: Array[Vector2] = []
const MAX_PATH_HISTORY = 100

# --- Follow State Variables ---
var follow_delay_points = 24
const FOLLOW_DISTANCE = 32.0

# --- Navigation/Movement State Variables ---
var MAX_SPEED = 80
var knockback = Vector2.ZERO
var astar_path: Array[Vector2i]

func _physics_process(delta: float):
	if state == NAV:
		pass
	elif not Events.is_player_controlled:
		state = MOVE
	else: 
		state = FOLLOW

	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)
	
	match state:
		NAV:
			nav_state()
		FOLLOW:
			follow_state()
		MOVE:
			player_move_state()

	velocity += knockback
	move_and_slide()

	if velocity.length() > 0:
		path_history.push_back(global_position)
		if path_history.size() > MAX_PATH_HISTORY:
			path_history.pop_front()

func player_move_state():
	if Events.controlsEnabled:
		var input_vector = Vector2.ZERO
		input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		
		update_velocity_and_animation(input_vector.normalized())
	else:
		update_velocity_and_animation(Vector2.ZERO)

func follow_state():
	var player_path: Array[Vector2] = player.path_history
	var player_is_moving = player.velocity.length() > 1.0
	
	if player_path.is_empty():
		update_velocity_and_animation(Vector2.ZERO)
		return

	var target_index = max(0, player_path.size() - follow_delay_points)
	var target_position = player_path[target_index]
	
	var direction_to_target = target_position - global_position
	var distance_to_player = global_position.distance_to(player.global_position)

	# Only move if the distance to the target point is > 1.0 (prevents stuttering)
	# AND either the player is moving OR we are too far away from the idle player.
	if direction_to_target.length() > 1.0 and (player_is_moving or distance_to_player > FOLLOW_DISTANCE):
		update_velocity_and_animation(direction_to_target.normalized())
	else:
		update_velocity_and_animation(Vector2.ZERO)

func nav_state():
	var move_direction = Vector2.ZERO
	if not astar_path.is_empty():
		var target_position = tilemap.map_to_local(astar_path.front())
		var direction = target_position - global_position
		if direction.length() < 2:
			astar_path.pop_front()
		move_direction = direction
	elif not navigationAgent.is_navigation_finished():
		move_direction = navigationAgent.get_next_path_position() - global_position
	
	update_velocity_and_animation(move_direction.normalized())

func update_velocity_and_animation(direction: Vector2):
	if direction != Vector2.ZERO:
		animationTree.set("parameters/Idle/blend_position", direction)
		animationTree.set("parameters/Run/blend_position", direction)
		animationState.travel("Run")
		velocity = direction * MAX_SPEED
	else:
		animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, MAX_SPEED)

func _on_hurtbox_trigger_knockback(knockback_vector: Vector2) -> void:
	knockback = knockback_vector * 100

func move_to_position_nav(target_position: Vector2):
	if Events.is_player_controlled:
		state = NAV
		astar_path.clear()
		navigationAgent.target_position = target_position

func move_to_position_astar(target_position: Vector2):
	if Events.is_player_controlled:
		state = NAV
		navigationAgent.target_position = global_position
		if tilemap.is_point_walkable(target_position):
			astar_path = tilemap.astar.get_id_path(
				tilemap.local_to_map(global_position),
				tilemap.local_to_map(target_position)
			).slice(1)
