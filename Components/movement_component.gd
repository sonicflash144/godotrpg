extends Node

class_name Movement_Component

@onready var character: CharacterBody2D = $".."
@onready var animation_tree = $"../AnimationTree"
@onready var animation_state = animation_tree.get("parameters/playback")
@onready var hitbox: Hitbox = get_node_or_null("../Hitbox")

@export var bossAnimation := false
@export var THE_PrisonerOverride := false

var current_speed: float
var MAX_SPEED := 80.0
var ATTACK_MOVE_SPEED := 24.0
const SPRINTMASTER_SPEED_MULTIPLIER = 1.25

var knockback := Vector2.ZERO
var last_input_vector := Vector2.ZERO

var diagonal_buffer_timer := 0.0
const DIAGONAL_BUFFER_DURATION := 0.05
var last_diagonal_input: Vector2 = Vector2.ZERO

func _ready() -> void:
	current_speed = MAX_SPEED
	if Events.equipment_abilities["Speed"]:
		current_speed *= SPRINTMASTER_SPEED_MULTIPLIER

func _physics_process(delta: float) -> void:
	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)
	if Events.inCutscene:
		character.velocity = Vector2.ZERO
	character.velocity += knockback
	character.move_and_slide()

	if diagonal_buffer_timer > 0:
		diagonal_buffer_timer -= delta

func get_player_input_vector() -> Vector2:
	if not Events.controlsEnabled:
		last_input_vector = Vector2.ZERO
		diagonal_buffer_timer = 0.0
		return Vector2.ZERO

	var input_vector = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	# Check for a transition from diagonal to cardinal input
	if last_input_vector.x != 0 and last_input_vector.y != 0 and \
	   ((input_vector.x != 0 and input_vector.y == 0) or \
		(input_vector.x == 0 and input_vector.y != 0)):
		last_diagonal_input = last_input_vector
		diagonal_buffer_timer = DIAGONAL_BUFFER_DURATION

	var final_vector: Vector2
	if diagonal_buffer_timer > 0:
		# If a new diagonal is pressed during the buffer, use it immediately
		if input_vector.x != 0 and input_vector.y != 0:
			diagonal_buffer_timer = 0.0
			final_vector = input_vector
		# If no keys are pressed, stop moving and cancel the buffer
		elif input_vector == Vector2.ZERO:
			diagonal_buffer_timer = 0.0
			final_vector = Vector2.ZERO
		# Otherwise, maintain the last diagonal direction for the buffer duration
		else:
			final_vector = last_diagonal_input
	else:
		final_vector = input_vector

	last_input_vector = input_vector

	return final_vector.normalized()

func move(direction: Vector2, speed := MAX_SPEED, animationOverride := "", follower := false):
	current_speed = speed
	if Events.equipment_abilities["Speed"] and not follower and not THE_PrisonerOverride:
		current_speed *= SPRINTMASTER_SPEED_MULTIPLIER
	update_animation_direction(direction)
	character.velocity = direction * current_speed
	if animationOverride:
		animation_state.travel(animationOverride)
	elif direction != Vector2.ZERO:
		animation_state.travel("Run")
	else:
		animation_state.travel("Idle")

func update_animation_direction(direction: Vector2):
	if direction != Vector2.ZERO:
		animation_tree.set("parameters/Idle/blend_position", direction)
		animation_tree.set("parameters/Run/blend_position", direction)
		animation_tree.set("parameters/Attack/blend_position", direction)
		
		if bossAnimation:
			animation_tree.set("parameters/Defend/blend_position", direction)
			animation_tree.set("parameters/Slash/blend_position", direction)
		
		if hitbox:
			hitbox.knockback_vector = direction

func _on_hurtbox_trigger_knockback(knockback_vector: Vector2) -> void:
	knockback = knockback_vector * 100
