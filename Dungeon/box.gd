extends StaticBody2D

@onready var boxPuzzle = $"../BoxPuzzle"
@onready var collisionShape = $CollisionShape2D
@onready var destroySound: AudioStreamPlayer = $DestroySound

var no_reset := false

func _ready() -> void:
	if boxPuzzle.no_reset:
		no_reset = true

func reset_box():
	if visible:
		return
	visible = true
	collisionShape.set_deferred("disabled", false)

func _on_area_2d_area_entered(_area: Area2D) -> void:
	if no_reset or get_parent().roomCompleted:
		return
	
	destroySound.play()
	visible = false
	collisionShape.set_deferred("disabled", true)
