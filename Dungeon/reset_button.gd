extends Area2D

@onready var animatedSprite = $AnimatedSprite2D
@onready var resetSound: AudioStreamPlayer = $Reset
@onready var boxPuzzle: Box_Puzzle = $".."

func _on_body_entered(_body: Node2D) -> void:
	resetSound.play()
	animatedSprite.play("On")
	boxPuzzle.reset_puzzle()
	
func _on_body_exited(_body: Node2D) -> void:
	animatedSprite.play("Off")
