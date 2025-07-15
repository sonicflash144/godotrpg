extends CharacterBody2D

@onready var sprite = $AnimatedSprite
@onready var playerDetectionZone = $PlayerDetectionZone
@onready var hurtbox = $Hurtbox
@onready var softCollision = $SoftCollision
@onready var enemyHitbox = $Hitbox
@onready var wanderController = $WanderController

const EnemyDeathEffect = preload("res://Effects/enemy_death_effect.tscn")
enum {
	INACTIVE,
	IDLE,
	WANDER,
	CHASE
}
var MAX_SPEED = 50
var knockback = Vector2.ZERO
var state = INACTIVE

func _physics_process(delta: float):
	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)
	match state:
		INACTIVE:
			velocity = Vector2.ZERO
		IDLE:
			velocity = Vector2.ZERO
			seek_player()
			if wanderController.get_time_left() == 0:
				update_wander_timer()
		WANDER:
			seek_player()
			if wanderController.get_time_left() == 0 or global_position.distance_to(wanderController.target_position) < 4:
				update_wander_timer()
			var direction = global_position.direction_to(wanderController.target_position)
			velocity = direction * MAX_SPEED
			sprite.flip_h = velocity.x > 0
		CHASE:
			var player = playerDetectionZone.get_target_player()
			if player and global_position.distance_to(player.global_position) > 4:
				var direction = global_position.direction_to(player.global_position)
				enemyHitbox.knockback_vector = direction
				velocity = direction * MAX_SPEED
				sprite.flip_h = velocity.x > 0
			else:
				state = IDLE

	velocity += knockback
	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 250
	
	move_and_slide()

func update_wander_timer():
	state = pick_random_state([IDLE, WANDER])
	wanderController.start_wander_timer(randf_range(1, 3))

func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func _on_hurtbox_trigger_knockback(knockback_vector: Vector2) -> void:
	knockback = knockback_vector * 125
