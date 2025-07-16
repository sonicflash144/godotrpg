extends CharacterBody2D

@onready var animationPlayer = $AnimationPlayer
@onready var animationTree = $AnimationTree
@onready var animationState = animationTree.get("parameters/playback")
@onready var playerHealthComponent: Health_Component = $Health_Component
@onready var playerBlinkAnimation = $BlinkAnimationPlayer
@onready var swordHitbox = $HitboxPivot/SwordHitbox
@onready var hurtbox: Area2D = $Hurtbox

@onready var princess: CharacterBody2D = get_node_or_null("../Princess")
@onready var princessHealthComponent: Health_Component = get_node_or_null("../Princess/Health_Component")
@onready var princessBlinkAnimation = get_node_or_null("../Princess/BlinkAnimationPlayer")
@onready var princessHurtbox: Area2D = get_node_or_null("../Princess/Hurtbox")
@onready var playerHealthUI: Health_UI = get_node_or_null("../CanvasLayer/PlayerHealthUI")
@onready var princessHealthUI: Health_UI = get_node_or_null("../CanvasLayer/PrincessHealthUI")

enum {
	MOVE,
	ATTACK,
	FOLLOW
}
var MAX_SPEED = 80
var state = MOVE
var knockback = Vector2.ZERO
var combat_locked: bool = false

# --- Path History (for being followed) ---
var path_history: Array[Vector2] = []
const MAX_PATH_HISTORY = 100

# --- Follow State Variables ---
var follow_delay_points = 24
const FOLLOW_DISTANCE = 32.0

func _ready() -> void:
	Events.room_combat_locked.connect(_on_room_combat_locked)
	Events.room_un_combat_locked.connect(_on_room_un_combat_locked)

func _physics_process(delta: float):
	# Update state based on who is controlled, but don't interrupt an attack
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

func move_state():
	if Events.controlsEnabled:
		var input_vector = Vector2.ZERO
		input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

		update_velocity_and_animation(input_vector.normalized())

		if Events.player_has_sword and Input.is_action_just_pressed("attack"):
			state = ATTACK
	else:
		update_velocity_and_animation(Vector2.ZERO)

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

	# Only move if the distance to the target point is > 1.0 (prevents stuttering)
	# AND either the target is moving OR we are too far away from the idle target.
	if direction_to_target.length() > 1.0 and (target_is_moving or distance_to_target > FOLLOW_DISTANCE):
		update_velocity_and_animation(direction_to_target.normalized())
	else:
		update_velocity_and_animation(Vector2.ZERO)

func update_velocity_and_animation(direction: Vector2):
	if direction != Vector2.ZERO:
		swordHitbox.knockback_vector = direction
		animationTree.set("parameters/Idle/blend_position", direction)
		animationTree.set("parameters/Run/blend_position", direction)
		animationTree.set("parameters/Attack/blend_position", direction)
		animationState.travel("Run")
		velocity = direction * MAX_SPEED
	else:
		animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, MAX_SPEED)

func swap_controlled_player():
	Events.is_player_controlled = not Events.is_player_controlled
	path_history.clear()
	princess.path_history.clear()
	update_controlled_player()

func update_controlled_player():
	if Events.is_player_controlled:
		hurtbox.enable_collider()
		princessHurtbox.disable_collider()
		playerHealthUI.enable_texture()
		princessHealthUI.disable_texture()
		playerBlinkAnimation.play("RESET")
		princessBlinkAnimation.play("Disabled")
		z_index = 0
		princess.z_index = -1
	else:
		hurtbox.disable_collider()
		princessHurtbox.enable_collider()
		playerHealthUI.disable_texture()
		princessHealthUI.enable_texture()
		playerBlinkAnimation.play("Disabled")
		princessBlinkAnimation.play("RESET")
		z_index = -1
		princess.z_index = 0

func attack_state():
	velocity = Vector2.ZERO
	animationState.travel("Attack")

func attack_animation_finished():
	state = FOLLOW if not Events.is_player_controlled else MOVE

func _on_room_combat_locked():
	combat_locked = true
	update_controlled_player()
	
func _on_room_un_combat_locked():
	combat_locked = false
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

func _on_hurtbox_trigger_knockback(knockback_vector: Vector2) -> void:
	knockback = knockback_vector * 100
	
func _unhandled_key_input(event: InputEvent) -> void:
	if combat_locked and event.is_action_pressed("swap_player") and not Events.playerDown and not Events.princessDown:
		swap_controlled_player()
