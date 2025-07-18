extends Area2D

@onready var hitbox: Hitbox = $Hitbox

var direction := Vector2.ZERO
var speed := 400.0
var horizontal_offset := -3

var piercing := false

func _ready() -> void:
	hitbox.knockback_vector = direction
	if direction.y == 0 and direction.x != 0:
		position.y += horizontal_offset

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if not piercing and area.name == "Hurtbox":
		queue_free()

func _on_body_entered(_body: Node2D) -> void:
	queue_free()
