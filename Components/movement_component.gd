extends Node

class_name Movement_Component

@onready var character: CharacterBody2D = $".."
@onready var animation_tree = $"../AnimationTree"
@onready var animation_state = animation_tree.get("parameters/playback")
@onready var hitbox: Hitbox = get_node_or_null("../Hitbox")

@export var bossAnimation := false

var current_speed: float
var MAX_SPEED := 80.0
var ATTACK_MOVE_SPEED := 24.0
const SPRINTMASTER_SPEED_MULTIPLIER = 1.2

var knockback := Vector2.ZERO
var last_input_vector := Vector2.ZERO
var buffered_input := Vector2.ZERO

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
	
func get_player_input_vector():
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

func move(direction: Vector2, speed := MAX_SPEED, animationOverride := "", follower := false):
	current_speed = speed
	if Events.equipment_abilities["Speed"] and not follower:
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
