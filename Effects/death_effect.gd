extends AnimatedSprite2D

func _ready() -> void:
	play("Animate")

func _on_animation_finished() -> void:
	queue_free()
