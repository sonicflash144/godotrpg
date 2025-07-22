extends CharacterBody2D

@onready var animatedSprite = $AnimatedSprite
@onready var playerDetectionZone = $PlayerDetectionZone
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var enemyHitbox: Hitbox = $Hitbox
@onready var swordSlowController = $SwordSlowController
@onready var bulletCooldownTimer = $BulletCooldown

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
var bullet = load("res://Enemies/fire_flower_bullet.tscn")
var spawned_bullets: Array[Node2D] = []

func _physics_process(delta: float) -> void:
	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)
	match state:
		INACTIVE:
			velocity = Vector2.ZERO
			
		IDLE:
			velocity = Vector2.ZERO
			seek_player()
			
		CHASE:
			var player = playerDetectionZone.get_target_player()
			if player:
				shoot_bullet(player)
				animatedSprite.play("Attack")
			else:
				state = IDLE
				animatedSprite.play("Idle")

	velocity += knockback
	
	move_and_slide()

func set_idle_state():
	state = IDLE

func seek_player():
	if playerDetectionZone.get_target_player():
		state = CHASE

func slow_enemy():
	swordSlowController.slow_enemy()
	
func handle_death():
	for b in spawned_bullets:
		if is_instance_valid(b):
			b.queue_free()
	queue_free()

func shoot_bullet(player: CharacterBody2D):
	if bulletCooldownTimer.time_left > 0:
		return
		
	bulletCooldownTimer.start(1)
	var direction = global_position.direction_to(player.global_position)
	var bullet_instance = bullet.instantiate()
	bullet_instance.global_position = global_position + Vector2(0, -6)
	bullet_instance.direction = direction
	get_parent().get_parent().add_child(bullet_instance)
	spawned_bullets.append(bullet_instance)
