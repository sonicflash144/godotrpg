extends Node

class_name Health_Component

signal player_down(down: bool)
signal princess_down(down: bool)
signal enemy_died(enemy: CharacterBody2D)

@export var MAX_HEALTH: int
@export var DeathEffect: PackedScene
@export var healthUI: Health_UI

var health: int
var SwordShockwaveScene = load("res://Enemies/sword_shockwave_controller.tscn")

func _ready() -> void:
	health = MAX_HEALTH
	
func is_max_health():
	return health >= MAX_HEALTH
	
func heal(heal_value := 1):
	if health <= 0:
		get_parent().visible = true
		if get_parent().is_in_group("Player"):
			player_down.emit(false)
			Events.playerDown = false
		elif get_parent().is_in_group("Princess"):
			princess_down.emit(false)
			Events.princessDown = false
	health += heal_value
	health = clamp(health, 0, MAX_HEALTH)
	
	if healthUI:
		healthUI.update_health(health, MAX_HEALTH)
	
func damage(damage_value: int, area_name: String):
	health -= damage_value
	health = clamp(health, 0, MAX_HEALTH)
	
	if healthUI:
		healthUI.update_health(health, MAX_HEALTH)

	if health <= 0:
		death(area_name)

func death(area_name: String):
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
		player_down.emit(true)
		Events.playerDown = true
	elif get_parent().is_in_group("Princess"):
		if Events.playerDown and not Events.playerDead:
			Events.player_died.emit()
			Events.playerDead = true
			return
		princess_down.emit(true)
		Events.princessDown = true
	elif get_parent().is_in_group("Enemy"):
		enemy_died.emit(get_parent())
		if Events.sword_shockwave and area_name == "SwordHitbox":
			var swordShockwave = SwordShockwaveScene.instantiate()
			get_tree().current_scene.call_deferred("add_child", swordShockwave)
			swordShockwave.global_position = get_parent().global_position
