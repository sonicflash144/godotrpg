extends AnimatedSprite2D

@onready var playerHealthComponent: Health_Component = $"../Player/Health_Component"
@onready var princessHealthComponent: Health_Component = $"../Princess/Health_Component"

var heartScene = load("res://Enemies/heart.tscn")
const HEART_DROP_RATE := 0.25
const BETTER_HEART_DROP_RATE := 0.35

func _ready() -> void:
	play("Animate")

func heart_drop():
	if playerHealthComponent.is_max_health() and princessHealthComponent.is_max_health():
		return
		
	var drop_rate = HEART_DROP_RATE
	if Events.equipment_abilities["Luck"]:
		drop_rate = BETTER_HEART_DROP_RATE

	if randf() < drop_rate:
		var heart = heartScene.instantiate()
		heart.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", heart)

func _on_animation_finished() -> void:
	heart_drop()
	queue_free()
