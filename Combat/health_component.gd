extends Node

class_name Health_Component

signal player_died()
signal enemy_died()

@export var MAX_HEALTH: int
@export var DeathEffect: PackedScene
@export var healthUI: Health_UI

var health: int

func _ready():
	health = MAX_HEALTH
	
func damage(damage_value: int):
	health -= damage_value
	health = clamp(health, 0, MAX_HEALTH)
	
	if healthUI:
		healthUI.update_health(health, MAX_HEALTH)

	if health <= 0:
		get_parent().queue_free()
		
		if DeathEffect:
			var deathEffect = DeathEffect.instantiate()
			get_tree().current_scene.add_child(deathEffect)
			deathEffect.global_position = get_parent().global_position
			
		if get_parent().is_in_group("Player") and not Events.playerDead:
			Events.playerDead = true
			player_died.emit()
		elif get_parent().is_in_group("Enemy"):
			enemy_died.emit()
