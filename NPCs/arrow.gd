extends Node2D

@onready var hitbox = $Hitbox

var direction: Vector2 = Vector2.ZERO
var speed: float = 400.0
var horizontal_offset: float = -3.0

var piercing: bool = false

func _ready():
	hitbox.knockback_vector = direction
	if direction.y == 0 and direction.x != 0:
		position.y += horizontal_offset

func _physics_process(delta: float):
	global_position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if not piercing and area.name == "Hurtbox":
		queue_free()

func _on_body_entered(_body: Node2D) -> void:
	queue_free()
