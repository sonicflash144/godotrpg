extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var softCollision: Area2D = $SoftCollision
@onready var enemyHitbox: Hitbox = $Hitbox
@onready var wanderController = $WanderController
@onready var swordSlowController = $SwordSlowController
@onready var actionTimer: Timer = $ActionTimer

@export var stats: Stats

enum {
	INACTIVE,
	IDLE,
	WANDER,
	CHASE,
	COOLDOWN
}
var state = INACTIVE
var MAX_SPEED := 60.0
var WANDER_SPEED := 60.0
var knockback := Vector2.ZERO
var spawned_acid_pools: Array[Node2D] = []
var is_playing_attack_reverse := false
var acid_pool_scene = load("res://Enemies/acid_pool.tscn")

func _physics_process(delta: float) -> void:
	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)
	
	match state:
		INACTIVE:
			velocity = Vector2.ZERO
			
		IDLE:
			velocity = Vector2.ZERO
			if wanderController.get_time_left() == 0:
				update_wander_timer()
				
		WANDER:
			if wanderController.get_time_left() == 0 or global_position.distance_to(wanderController.target_position) < 4:
				update_wander_timer()

			var direction = global_position.direction_to(wanderController.target_position)
			enemyHitbox.knockback_vector = direction
			velocity = direction * MAX_SPEED
			sprite.flip_h = velocity.x > 0
			
		CHASE:
			velocity = Vector2.ZERO

	velocity += knockback
	
	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 250
	
	move_and_slide()

func set_idle_state():
	state = IDLE
	await get_tree().create_timer(randf_range(0, 3)).timeout
	actionTimer.start()

func update_wander_timer():
	var state_list = [IDLE, WANDER]
	state_list.shuffle()
	state = state_list.pop_front()
	wanderController.start_wander_timer(randf_range(1.0, 2.0))

func _on_action_timer_timeout() -> void:
	# First, remove any references to pools that have already been destroyed.
	spawned_acid_pools = spawned_acid_pools.filter(func(p): return is_instance_valid(p))
	
	if state == IDLE or state == WANDER:
		state = CHASE
		sprite.play("Start")
	else:
		actionTimer.start()

func handle_death(_area_name: String) -> void:
	for pool in spawned_acid_pools:
		if is_instance_valid(pool):
			pool.queue_free()
	queue_free()

func slow_enemy() -> void:
	swordSlowController.slow_enemy()

func _on_animated_sprite_animation_finished() -> void:
	# This signal fires when any animation finishes, so we only act if in the ATTACKING state.
	if state != CHASE:
		return

	# If the forward animation has just finished...
	if not is_playing_attack_reverse:
		# Create the acid pool.
		var pool_instance = acid_pool_scene.instantiate()
		pool_instance.global_position = global_position
		get_tree().current_scene.add_child(pool_instance)
		spawned_acid_pools.append(pool_instance)
		
		# Set the flag and play the animation in reverse.
		is_playing_attack_reverse = true
		sprite.play_backwards("Start")
	
	# If the backward animation has just finished...
	else:
		# Reset the flag and return to a normal state.
		is_playing_attack_reverse = false
		update_wander_timer() # Resume wandering or idling.
		actionTimer.start()   # Restart the timer for the next attack decision.

func _on_hurtbox_trigger_knockback(knockback_vector: Vector2) -> void:
	knockback = knockback_vector * 100
