extends Area2D

var players_in_zone: Array = []

func can_see_player() -> bool:
	return not players_in_zone.is_empty()

# Return the closest or first seen player
func get_target_player() -> Node2D:
	var closest = null
	var min_dist = INF
	for p in players_in_zone:
		var dist = global_position.distance_to(p.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = p
	return closest

func _on_body_entered(body: Node2D):
	if not players_in_zone.has(body):
		players_in_zone.append(body)

func _on_body_exited(body: Node2D):
	players_in_zone.erase(body)
