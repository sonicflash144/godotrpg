extends Node2D

func _on_transition_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		TransitionHandler.console_fade_out("throne_room")
		Events.player_transition = "up"
