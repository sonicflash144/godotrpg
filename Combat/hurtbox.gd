extends Area2D

signal trigger_knockback(knockback_vector: Vector2)

@onready var timer = $Timer
@onready var collisionShape = $CollisionShape2D

@export var health: Health_Component
@export var invincibilityTime: float
@export var blinkAnimationPlayer: AnimationPlayer
@export var HurtSound: PackedScene

var is_invincible: bool = false

func start_invincibility():
	is_invincible = true
	collisionShape.set_deferred("disabled", true)
	if blinkAnimationPlayer:
		blinkAnimationPlayer.play("Start")
	timer.start(invincibilityTime)

func _on_timer_timeout():
	is_invincible = false
	collisionShape.disabled = false

func _on_area_entered(area: Area2D) -> void:
	if is_invincible:
		return
		
	if health:
		health.damage(area.damage)
	start_invincibility()
	var hurtSound = HurtSound.instantiate()
	get_tree().current_scene.add_child(hurtSound)
	trigger_knockback.emit(area.knockback_vector)
