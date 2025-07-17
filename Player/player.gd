extends CharacterBody2D

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var playerBlinkAnimation = $BlinkAnimationPlayer
@onready var animationTree = $AnimationTree
@onready var animationState = animationTree.get("parameters/playback")

@onready var swordHitbox: Hitbox = $HitboxPivot/SwordHitbox
@onready var playerHealthComponent: Health_Component = $Health_Component
@onready var swapCooldownTimer = $SwapCooldownTimer

@onready var princess: CharacterBody2D = get_node_or_null("../Princess")
@onready var princessHealthComponent: Health_Component = get_node_or_null("../Princess/Health_Component")
@onready var princessBlinkAnimation = get_node_or_null("../Princess/BlinkAnimationPlayer")
@onready var princessHurtbox: Hurtbox = get_node_or_null("../Princess/Hurtbox")
@onready var playerHealthUI: Health_UI = get_node_or_null("../CanvasLayer/PlayerHealthUI")
@onready var princessHealthUI: Health_UI = get_node_or_null("../CanvasLayer/PrincessHealthUI")

enum {
	MOVE,
	ATTACK,
	FOLLOW,
	NAV
}
var state = MOVE
var MAX_SPEED = 80
var last_input_vector := Vector2.ZERO
var buffered_input := Vector2.ZERO
var knockback := Vector2.ZERO
var combat_locked := false
var can_swap_control := true
const SWAP_COOLDOWN_DURATION := 4.0

# --- Path History (for being followed) ---
var path_history: Array[Vector2] = []
const MAX_PATH_HISTORY = 100

# --- Follow State Variables ---
var follow_delay_points = 24
const FOLLOW_DISTANCE = 32

func _ready() -> void:
	Events.room_combat_locked.connect(_on_room_combat_locked)
	Events.room_un_combat_locked.connect(_on_room_un_combat_locked)

func _physics_process(delta: float):
	# Don't let the state be overridden while attacking
	if state != ATTACK:
		state = MOVE if Events.is_player_controlled else FOLLOW

	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)

	match state:
		MOVE:
			move_state()
		ATTACK:
			attack_state()
		FOLLOW:
			follow_state()
			
	velocity += knockback
	move_and_slide()
	
	if velocity.length() > 0:
		path_history.push_back(global_position)
		if path_history.size() > MAX_PATH_HISTORY:
			path_history.pop_front()

func get_player_input_vector() -> Vector2:
	if not Events.controlsEnabled:
		last_input_vector = Vector2.ZERO
		buffered_input = Vector2.ZERO
		return Vector2.ZERO

	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	var final_vector = input_vector

	# Diagonal to cardinal direction buffering
	if last_input_vector.x != 0 and last_input_vector.y != 0 and \
		((input_vector.x != 0 and input_vector.y == 0) or \
		(input_vector.x == 0 and input_vector.y != 0)):
		buffered_input = input_vector
		final_vector = last_input_vector
	elif buffered_input != Vector2.ZERO:
		if input_vector == Vector2.ZERO:
			final_vector = Vector2.ZERO
		else:
			final_vector = buffered_input
		buffered_input = Vector2.ZERO

	last_input_vector = input_vector
	return final_vector

func move_state():
	var move_direction = get_player_input_vector().normalized()
	update_velocity_and_animation(move_direction)

	if Events.controlsEnabled and Events.player_has_sword and Input.is_action_just_pressed("attack"):
		state = ATTACK

func attack_state():
	velocity = Vector2.ZERO
	animationState.travel("Attack")

func follow_state():
	var follow_target_path: Array[Vector2] = princess.path_history
	var target_is_moving = princess.velocity.length() > 1.0
	
	if follow_target_path.is_empty():
		update_velocity_and_animation(Vector2.ZERO)
		return

	var target_index = max(0, follow_target_path.size() - follow_delay_points)
	var target_position = follow_target_path[target_index]
	
	var direction_to_target = target_position - global_position
	var distance_to_target = global_position.distance_to(princess.global_position)

	if direction_to_target.length() > 1.0 and (target_is_moving or distance_to_target > FOLLOW_DISTANCE):
		var follow_speed = MAX_SPEED
		if princess.state == ATTACK:
			follow_speed = princess.ATTACK_MOVE_SPEED
		update_velocity_and_animation(direction_to_target.normalized(), follow_speed)
	else:
		update_velocity_and_animation(Vector2.ZERO)

func update_animation_direction(direction: Vector2):
	if direction != Vector2.ZERO:
		swordHitbox.knockback_vector = direction
		animationTree.set("parameters/Idle/blend_position", direction)
		animationTree.set("parameters/Run/blend_position", direction)
		animationTree.set("parameters/Attack/blend_position", direction)

func update_velocity_and_animation(direction: Vector2, speed: float = MAX_SPEED):
	update_animation_direction(direction)

	if direction != Vector2.ZERO:
		animationState.travel("Run")
		velocity = direction * speed
	else:
		animationState.travel("Idle")
		velocity = Vector2.ZERO

func _on_hurtbox_trigger_knockback(knockback_vector: Vector2) -> void:
	knockback = knockback_vector * 100

func swap_controlled_player():
	Events.is_player_controlled = not Events.is_player_controlled
	path_history.clear()
	princess.path_history.clear()
	update_controlled_player()

func update_controlled_player(justEntered := false):
	if Events.is_player_controlled:
		hurtbox.enable_collider()
		princessHurtbox.disable_collider()
		playerHealthUI.enable_texture()
		if justEntered:
			princessHealthUI.disable_texture()
		else:
			princessHealthUI.disable_texture(SWAP_COOLDOWN_DURATION)
		playerBlinkAnimation.play("Enabled")
		princessBlinkAnimation.play("Disabled")
		z_index = 0
		princess.z_index = -1
	else:
		hurtbox.disable_collider()
		princessHurtbox.enable_collider()
		playerHealthUI.disable_texture(SWAP_COOLDOWN_DURATION)
		princessHealthUI.enable_texture()
		playerBlinkAnimation.play("Disabled")
		princessBlinkAnimation.play("Enabled")
		z_index = -1
		princess.z_index = 0

func attack_animation_finished():
	state = FOLLOW if not Events.is_player_controlled else MOVE

func _on_room_combat_locked():
	combat_locked = true
	if not Events.playerDown and not Events.princessDown:
		update_controlled_player(true)
	
func _on_room_un_combat_locked():
	combat_locked = false
	if Events.num_party_members < 2:
		return
		
	if not Events.is_player_controlled:
		Events.is_player_controlled = true
		path_history.clear()
		princess.path_history.clear()
	if Events.playerDown:
		playerHealthComponent.heal(1)
		Events.playerDown = false
	elif Events.princessDown:
		princessHealthComponent.heal(1)
		Events.princessDown = false
	hurtbox.enable_collider()
	princessHurtbox.enable_collider()
	playerHealthUI.enable_texture()
	princessHealthUI.enable_texture()
	playerBlinkAnimation.play("RESET")
	princessBlinkAnimation.play("RESET")
	z_index = 0
	princess.z_index = 0

func _on_health_component_player_down() -> void:
	if Events.is_player_controlled:
		swap_controlled_player()

func _on_health_component_princess_down() -> void:
	if not Events.is_player_controlled:
		swap_controlled_player()
	
func _unhandled_key_input(event: InputEvent) -> void:
	if combat_locked and event.is_action_pressed("swap_player") and can_swap_control \
	and not Events.playerDown and not Events.princessDown:
		swap_controlled_player()
		can_swap_control = false
		swapCooldownTimer.start(SWAP_COOLDOWN_DURATION)

func _on_swap_cooldown_timer_timeout() -> void:
	can_swap_control = true
