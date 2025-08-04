extends CharacterBody2D

@onready var animationPlayer = $AnimationPlayer
@onready var playerDetectionZone = $PlayerDetectionZone
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var softCollision = $SoftCollision
@onready var enemyHitbox: Hitbox = $Hitbox
@onready var cooldownTimer = $CooldownTimer
@onready var wanderController = $WanderController
@onready var swordSlowController = $SwordSlowController

@export var stats: Stats

enum {
	INACTIVE,
	IDLE,
	WANDER,
	CHASE,
	COOLDOWN
}
var MAX_SPEED := 120.0
var WANDER_SPEED := 60.0
var knockback := Vector2.ZERO
var state = INACTIVE

var charge_direction := Vector2.ZERO
var is_charging := false

func _physics_process(delta: float) -> void:
	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)

	match state:
		INACTIVE:
			velocity = Vector2.ZERO

		IDLE:
			animationPlayer.play("Idle")
			velocity = Vector2.ZERO
			seek_player()
			if wanderController.get_time_left() == 0:
				update_wander_timer()

		WANDER:
			seek_player()
			if wanderController.get_time_left() == 0 or global_position.distance_to(wanderController.target_position) < 4:
				update_wander_timer()
			var direction = global_position.direction_to(wanderController.target_position)
			enemyHitbox.knockback_vector = direction
			velocity = direction * WANDER_SPEED

		CHASE:
			animationPlayer.play("Attack")
			if not is_charging:
				var player = playerDetectionZone.get_target_player()
				if player:
					var predicted_position = player.global_position + player.velocity * 0.8
					var blended_position = player.global_position.lerp(predicted_position, randf())
					charge_direction = global_position.direction_to(blended_position)
					enemyHitbox.knockback_vector = charge_direction
					is_charging = true
				else:
					state = IDLE
					return

			velocity = charge_direction * MAX_SPEED

		COOLDOWN:
			animationPlayer.play("Idle")
			velocity = Vector2.ZERO

	velocity += knockback

	# Prevents enemies from stacking directly on top of each other
	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 250

	move_and_slide()

	if is_charging:
		var hit_blocking_wall = false
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var normal = collision.get_normal()
			if normal.dot(charge_direction) < -0.7:  # Threshold for detecting blocking (head-on) collisions; adjust as needed
				hit_blocking_wall = true
				break

		if hit_blocking_wall:
			is_charging = false
			state = COOLDOWN
			cooldownTimer.start()
			velocity = Vector2.ZERO

func set_idle_state():
	state = IDLE

func seek_player():
	if playerDetectionZone.get_target_player():
		state = CHASE

func update_wander_timer():
	var state_list = [IDLE, WANDER]
	state_list.shuffle()
	state = state_list.pop_front()
	wanderController.start_wander_timer(randf_range(1.0, 3.0))

func slow_enemy():
	swordSlowController.slow_enemy()

func handle_death(_area_name: String):
	queue_free()

func _on_cooldown_timer_timeout() -> void:
	state = IDLE
	update_wander_timer()

func _on_hurtbox_trigger_knockback(knockback_vector: Vector2) -> void:
	if is_charging:
		knockback = knockback_vector * 150
	else:
		knockback = knockback_vector * 100
