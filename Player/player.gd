extends CharacterBody2D

@onready var animationPlayer = $AnimationPlayer
@onready var animationTree = $AnimationTree
@onready var animationState = animationTree.get("parameters/playback")
@onready var swordHitbox = $HitboxPivot/SwordHitbox
@onready var hurtbox = $Hurtbox

enum {
	MOVE,
	ATTACK
}
var MAX_SPEED = 80
var state = MOVE
var knockback = Vector2.ZERO

func _physics_process(delta: float):
	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)
	
	match state:
		MOVE:
			move_state()
		ATTACK:
			attack_state()
	velocity += knockback
	
	move_and_slide()
	
func move_state():
	if Events.controlsEnabled:
		var input_vector = Vector2.ZERO
		input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		input_vector = input_vector.normalized()
		
		if input_vector != Vector2.ZERO:
			swordHitbox.knockback_vector = input_vector
			animationTree.set("parameters/Idle/blend_position", input_vector)
			animationTree.set("parameters/Run/blend_position", input_vector)
			animationTree.set("parameters/Attack/blend_position", input_vector)
			animationState.travel("Run")
			velocity = input_vector * MAX_SPEED
		else:
			animationState.travel("Idle")
			velocity = Vector2.ZERO
		
		if Events.player_has_sword and Input.is_action_just_pressed("attack"):
			state = ATTACK
	else:
		velocity = Vector2.ZERO
		animationState.travel("Idle")

func attack_state():
	velocity = Vector2.ZERO
	animationState.travel("Attack")
	
func attack_animation_finished():
	state = MOVE

func _on_hurtbox_trigger_knockback(knockback_vector: Vector2) -> void:
	knockback = knockback_vector * 100
