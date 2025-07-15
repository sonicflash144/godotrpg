extends StaticBody2D

func _on_hurtbox_area_entered(area: Area2D):
	queue_free()
