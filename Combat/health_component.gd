extends Node

class_name Health_Component

signal enemy_died(enemy: CharacterBody2D)

var MAX_HEALTH: int
var health: int
var healthUI: Health_UI
var DeathEffect: PackedScene
var invincible := false

const REVENGE_DAMANGE_MULTIPLIER := 2

func _ready() -> void:
	MAX_HEALTH = get_parent().stats.health
	health = MAX_HEALTH
	if get_parent().is_in_group("Player"):
		healthUI = get_node_or_null("../../HealthCanvasLayer/PlayerHealthUI")
	elif get_parent().is_in_group("Princess"):
		healthUI = get_node_or_null("../../HealthCanvasLayer/PrincessHealthUI")
	elif get_parent().is_in_group("Enemy"):
		DeathEffect = load("res://Effects/enemy_death_effect.tscn")

func get_health_percentage():
	return float(health) / MAX_HEALTH

func is_max_health():
	return health >= MAX_HEALTH
	
func heal(heal_value := 1):
	var revived := false
	
	if health <= 0:
		get_parent().visible = true
		if get_parent().is_in_group("Player"):
			revived = true
			Events.player_down.emit(false)
			Events.playerDown = false
		elif get_parent().is_in_group("Princess"):
			revived = true
			Events.princess_down.emit(false)
			Events.princessDown = false
	health += heal_value
	health = clamp(health, 0, MAX_HEALTH)
	
	if healthUI:
		healthUI.update_health(health, MAX_HEALTH, revived)
	
func damage(base_damage: int, area_name: String):
	if area_name == "debug_killall":
		death(area_name)
		return
	elif invincible:
		return
	
	var adjusted_damage = base_damage
	if get_parent().is_in_group("Enemy") and Events.equipment_abilities["Revenge"] and (Events.playerDown or Events.princessDown):
		adjusted_damage *= REVENGE_DAMANGE_MULTIPLIER
	if area_name != "LaserHitbox":
		adjusted_damage = clamp(adjusted_damage - get_parent().stats.defense, 0, INF)
	health -= adjusted_damage
	health = clamp(health, 0, MAX_HEALTH)
	
	if healthUI:
		healthUI.update_health(health, MAX_HEALTH)

	if health <= 0:
		death(area_name)

func death(area_name: String):
	if get_parent().is_in_group("Princess") and area_name == "SwordHitbox":
		Events.princessDown = true
		return
		
	if get_parent().name == "ThePrisoner" or get_parent().name == "King":
		get_parent().handle_death(area_name)
	elif DeathEffect:
		get_parent().handle_death(area_name)
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
		Events.player_down.emit(true)
		Events.playerDown = true
	elif get_parent().is_in_group("Princess"):
		if Events.playerDown and not Events.playerDead:
			Events.player_died.emit()
			Events.playerDead = true
			return
		Events.princess_down.emit(true)
		Events.princessDown = true
	elif get_parent().is_in_group("Enemy"):
		enemy_died.emit(get_parent())
		#if Events.equipment_abilities["Shockwave"] and area_name == "SwordHitbox" and randf() < SWORD_SHOCKWAVE_RATE:
			#var swordShockwave = SwordShockwaveScene.instantiate()
			#get_tree().current_scene.call_deferred("add_child", swordShockwave)
			#swordShockwave.global_position = get_parent().global_position
