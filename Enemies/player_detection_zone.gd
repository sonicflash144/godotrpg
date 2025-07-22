extends Area2D

var players_in_zone: Array[CharacterBody2D] = []

func get_target_player():
	var target_group = "Player" if Events.is_player_controlled else "Princess"

	for body in players_in_zone:
		if body.is_in_group(target_group):
			return body
	
	return null

func _on_body_entered(body: Node2D) -> void:
	if not players_in_zone.has(body):
		players_in_zone.append(body)

func _on_body_exited(body: Node2D) -> void:
	players_in_zone.erase(body)
