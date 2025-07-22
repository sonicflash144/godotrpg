extends Area2D

class_name Hitbox

var damage := 1
var knockback_vector := Vector2.ZERO

func _ready() -> void:
	await get_parent().ready
	update_damage()

func update_damage():
	damage = get_parent().stats.attack
