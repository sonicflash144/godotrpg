extends Area2D

@onready var hitbox: Hitbox = $ArrowHitbox

@export var stats: Stats

var direction := Vector2.ZERO
var speed := 400.0

func _ready() -> void:
	hitbox.knockback_vector = direction

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if not Events.equipment_abilities["Piercing"] and area.name == "Hurtbox":
		queue_free()

func _on_body_entered(_body: Node2D) -> void:
	queue_free()
