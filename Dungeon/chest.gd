extends StaticBody2D

@onready var animationPlayer = $AnimationPlayer
@onready var dialogueZone = $ChestDialogueZone

func open_chest():
	animationPlayer.play("Open")
	dialogueZone.queue_free()
