extends CharacterBody2D

@onready var animatedSprite: AnimatedSprite2D = $AnimatedSprite
@onready var playerDetectionZone: Area2D = $PlayerDetectionZone
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var softCollision: Area2D = $SoftCollision
@onready var enemyHitbox: Hitbox = $Hitbox
@onready var wanderController: Node = $WanderController
@onready var swordSlowController: Node = $SwordSlowController
@onready var bulletCooldownTimer: Timer = $BulletCooldownTimer

@export var stats: Stats

enum {
	INACTIVE,
	IDLE,
	WANDER,
	CHASE,
	COOLDOWN
}
var state = INACTIVE
var MAX_SPEED := 50.0
var WANDER_SPEED := 50.0
var knockback := Vector2.ZERO
var spawned_bullets: Array[Node2D] = []
var bullet_scene = load("res://Enemies/jellyfish_bullet.tscn")

func _physics_process(delta: float) -> void:
	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)
	
	match state:
		INACTIVE:
			velocity = Vector2.ZERO
			
		IDLE:
			velocity = Vector2.ZERO
			if wanderController.get_time_left() == 0:
				update_wander_state()
			seek_player()
				
		WANDER:
			if wanderController.get_time_left() == 0 or global_position.distance_to(wanderController.target_position) < 4:
				update_wander_state()

			var direction = global_position.direction_to(wanderController.target_position)
			velocity = direction * WANDER_SPEED
			seek_player()
			
		CHASE:
			velocity = Vector2.ZERO
			var player = playerDetectionZone.get_target_player()
			if player:
				shoot_bullet(player)
			else:
				update_wander_state()

	velocity += knockback
	
	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 250
	
	move_and_slide()

func set_idle_state():
	state = IDLE
	animatedSprite.play("default")
	update_wander_state()

func update_wander_state():
	var state_list = [IDLE, WANDER]
	state_list.shuffle()
	state = state_list.pop_front()
	wanderController.start_wander_timer(randf_range(1.0, 2.0))
	animatedSprite.play("default")

func seek_player():
	if playerDetectionZone.get_target_player():
		state = CHASE

func shoot_bullet(player: CharacterBody2D):
	if bulletCooldownTimer.time_left > 0:
		return
		
	bulletCooldownTimer.start(1.5) # Cooldown between shots
	animatedSprite.play("Start") # Play shooting animation
	
	var bullet_instance = bullet_scene.instantiate()
	bullet_instance.global_position = global_position
	bullet_instance.set_target_position(player.global_position)
	
	get_tree().current_scene.add_child(bullet_instance)
	spawned_bullets.append(bullet_instance)
	
	spawned_bullets = spawned_bullets.filter(func(b): return is_instance_valid(b))

func handle_death(_area_name: String) -> void:
	for bullet in spawned_bullets:
		if is_instance_valid(bullet):
			bullet.queue_free()
	queue_free()

func slow_enemy() -> void:
	swordSlowController.slow_enemy()

func _on_animated_sprite_animation_finished() -> void:
	# After the "Start" (shooting) animation finishes, go back to idle.
	if animatedSprite.animation == "Start":
		animatedSprite.play("default")
		# Go back to wandering/idling until player is detected again or timer runs out
		if not playerDetectionZone.get_target_player():
			update_wander_state()

func _on_hurtbox_trigger_knockback(knockback_vector: Vector2) -> void:
	knockback = knockback_vector * 100
