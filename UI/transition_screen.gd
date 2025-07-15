extends CanvasLayer

signal transitioned

@onready var animationPlayer = $AnimationPlayer

func transition():
	animationPlayer.play("fade_to_black")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fade_to_black":
		transitioned.emit()
		animationPlayer.play("fade_to_normal")
