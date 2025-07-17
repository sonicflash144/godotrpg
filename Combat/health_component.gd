extends Node

class_name Health_Component

signal player_down()
signal princess_down()
signal enemy_died(enemy: CharacterBody2D)

@export var MAX_HEALTH: int
@export var DeathEffect: PackedScene
@export var healthUI: Health_UI

var health: int

func _ready():
	health = MAX_HEALTH
	
func heal(heal_value: int):
	if health <= 0:
		get_parent().visible = true
	
	health += heal_value
	health = clamp(health, 0, MAX_HEALTH)
	
	if healthUI:
		healthUI.update_health(health, MAX_HEALTH)
	
func damage(damage_value: int):
	health -= damage_value
	health = clamp(health, 0, MAX_HEALTH)
	
	if healthUI:
		healthUI.update_health(health, MAX_HEALTH)

	if health <= 0:
		death()

func death():
	if DeathEffect:
		get_parent().queue_free()
		var deathEffect = DeathEffect.instantiate()
		get_tree().current_scene.add_child(deathEffect)
		deathEffect.global_position = get_parent().global_position
	else:
		get_parent().visible = false
		
	if get_parent().is_in_group("Player"):
		if Events.princessDown and not Events.playerDead:
			Events.player_died.emit()
			Events.playerDead = true
			return
		player_down.emit()
		Events.playerDown = true
	elif get_parent().is_in_group("Princess"):
		if Events.playerDown and not Events.playerDead:
			Events.player_died.emit()
			Events.playerDead = true
			return
		princess_down.emit()
		Events.princessDown = true
	elif get_parent().is_in_group("Enemy"):
		enemy_died.emit(get_parent())
