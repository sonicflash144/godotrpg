extends Node

@onready var timer = $Timer
@onready var movement_component: Movement_Component = get_node_or_null("../Movement_Component")

const SLOW_FACTOR = 0.65
var enemy: CharacterBody2D
var original_max_speed: float
var original_wander_speed: float
var slow_max_speed: float
var slow_wander_speed: float
var IceEffect = load("res://Effects/ice_effect.tscn")

func _ready() -> void:
	enemy = get_parent()
	if movement_component:
		original_max_speed = movement_component.MAX_SPEED
		slow_max_speed = original_max_speed * SLOW_FACTOR
	else:
		original_max_speed = enemy.MAX_SPEED
		original_wander_speed = enemy.WANDER_SPEED
		slow_max_speed = original_max_speed * SLOW_FACTOR
		slow_wander_speed = original_wander_speed * SLOW_FACTOR

func slow_enemy():
	if timer.is_stopped():
		if movement_component:
			movement_component.MAX_SPEED = slow_max_speed
		else:
			enemy.MAX_SPEED = slow_max_speed
			enemy.WANDER_SPEED = slow_wander_speed
		timer.start(3)
		
		var iceEffect = IceEffect.instantiate()
		enemy.add_child(iceEffect)
		
func _on_timer_timeout() -> void:
	if movement_component:
		movement_component.MAX_SPEED = original_max_speed
	else:
		enemy.MAX_SPEED = original_max_speed
		enemy.WANDER_SPEED = original_wander_speed
	enemy.get_node_or_null("IceEffect").queue_free()
