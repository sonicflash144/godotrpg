extends Area2D

class_name Hurtbox

signal trigger_knockback(knockback_vector: Vector2)

@onready var health: Health_Component = $"../Health_Component"
@onready var blinkAnimationPlayer = $"../BlinkAnimationPlayer"
@onready var timer = $Timer
@onready var collisionShape = $CollisionShape2D

const SWORD_SLOW_RATE := 0.2
var invincibilityTime: float
var HurtSound: PackedScene

var is_invincible := false
var collider_disabled := false

func _ready() -> void:
	if get_parent().is_in_group("Player") or get_parent().is_in_group("Princess"):
		invincibilityTime = 1.0
		HurtSound = load("res://Music and Sounds/player_hurt_sound.tscn")
	elif get_parent().is_in_group("Enemy"):
		invincibilityTime = 0.2
		HurtSound = load("res://Music and Sounds/player_hit_sound.tscn")

func disable_collider():
	is_invincible = true
	collider_disabled = true
	collisionShape.set_deferred("disabled", true)
		
func enable_collider():
	collider_disabled = false
	_on_timer_timeout()
	start_invincibility()

func overworld_damage_logic(area: Area2D):
	var princessHealth = get_node_or_null("../../Princess/Health_Component")

	var laser_damage = area.damage
	var player_would_die = health.health <= laser_damage
	var princess_would_die = princessHealth.health <= laser_damage

	# If both will die, then damage both to kill them.
	if player_would_die and princess_would_die:
		health.damage(laser_damage, area.name)
		princessHealth.damage(laser_damage, area.name)
	# Otherwise, only deal damage to a character if they will survive.
	else:
		if not player_would_die:
			health.damage(laser_damage, area.name)
		if not princess_would_die:
			princessHealth.damage(laser_damage, area.name)

func start_invincibility():
	is_invincible = true
	collisionShape.set_deferred("disabled", true)
	if blinkAnimationPlayer:
		blinkAnimationPlayer.play("Start")
	timer.start(invincibilityTime)

func _on_timer_timeout():
	if collider_disabled:
		return
		
	is_invincible = false
	collisionShape.set_deferred("disabled", false)

func _on_area_entered(area: Area2D) -> void:
	if is_invincible:
		return
	
	if area.name == "LaserHitbox":
		overworld_damage_logic(area)
	else:
		if health:
			health.damage(area.damage, area.name)
		
		if Events.equipment_abilities["Ice"] and area.name == "SwordHitbox" and get_parent().is_in_group("Enemy") and randf() < SWORD_SLOW_RATE:
			get_parent().slow_enemy()
	
	# Common effects for any hit that is registered.
	start_invincibility()
	var hurtSound = HurtSound.instantiate()
	get_tree().current_scene.add_child(hurtSound)
	if area.name == "ShockwaveHitbox":
		var direction = (global_position - area.global_position).normalized()
		trigger_knockback.emit(direction)
	elif area.name == "LaserHitbox":
		var movement_component = get_node_or_null("../Movement_Component")
		var direction = movement_component.animation_tree.get("parameters/Run/blend_position")
		trigger_knockback.emit(-direction)
	else:
		trigger_knockback.emit(area.knockback_vector)
