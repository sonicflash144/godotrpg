extends CharacterBody2D

@onready var animationPlayer = $AnimationPlayer
@onready var playerDetectionZone = $PlayerDetectionZone
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var softCollision = $SoftCollision
@onready var enemyHitbox: Hitbox = $Hitbox
@onready var chargeTimer = $ChargeTimer
@onready var idleCooldownTimer = $IdleCooldownTimer

enum {
	INACTIVE,
	IDLE,
	CHASE
}

var MAX_SPEED = 120
var knockback = Vector2.ZERO
var state = INACTIVE

var charge_direction := Vector2.ZERO
var is_charging := false
var is_in_cooldown := false

func _physics_process(delta: float):
	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)

	match state:
		INACTIVE:
			velocity = Vector2.ZERO
		IDLE:
			animationPlayer.play("Idle")
			velocity = Vector2.ZERO
			seek_player()
		CHASE:
			animationPlayer.play("Attack")

			if is_in_cooldown:
				state = IDLE
				return

			if not is_charging:
				var player = playerDetectionZone.get_target_player()
				if player:
					var predicted_position = player.global_position + player.velocity * 0.8
					var t = randf()  # Random float between 0.0 and 1.0
					var blended_position = player.global_position.lerp(predicted_position, t)
					charge_direction = global_position.direction_to(blended_position)
					enemyHitbox.knockback_vector = charge_direction
					is_charging = true
					chargeTimer.start()
				else:
					state = IDLE
					return

			velocity = charge_direction * MAX_SPEED

	velocity += knockback

	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 250

	move_and_slide()

func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE

func _on_charge_timer_timeout():
	is_charging = false
	is_in_cooldown = true
	state = IDLE
	idleCooldownTimer.wait_time = randf_range(0, 2)
	idleCooldownTimer.start()
	
func _on_idle_cooldown_timer_timeout() -> void:
	is_in_cooldown = false

func _on_hurtbox_trigger_knockback(knockback_vector: Vector2) -> void:
	if is_charging:
		knockback = knockback_vector * 150
	else:
		knockback = knockback_vector * 100
