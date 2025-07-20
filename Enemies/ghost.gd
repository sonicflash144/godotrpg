extends CharacterBody2D

@onready var sprite = $AnimatedSprite
@onready var playerDetectionZone = $PlayerDetectionZone
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var softCollision = $SoftCollision
@onready var enemyHitbox: Hitbox = $Hitbox
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
var MAX_SPEED := 50.0
var WANDER_SPEED := 50.0
var knockback := Vector2.ZERO
var state = INACTIVE

func _physics_process(delta: float) -> void:
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
			velocity = direction * WANDER_SPEED
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
	
	# Prevents enemies from stacking directly on top of each other
	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 250
	
	move_and_slide()

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

func _on_hurtbox_trigger_knockback(knockback_vector: Vector2) -> void:
	knockback = knockback_vector * 125
