extends Area2D

class_name DialogueBarrier

@export var key: String

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		get_parent().get_parent().dialogue_barrier(key)
