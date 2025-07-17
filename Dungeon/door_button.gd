extends Area2D

@onready var animatedSprite = $AnimatedSprite2D
@onready var buttonSound: AudioStreamPlayer = $Button

func interact(value: String):
	buttonSound.play()
	animatedSprite.play(value)
