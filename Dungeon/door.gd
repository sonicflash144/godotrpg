extends StaticBody2D

@onready var dungeon = $".."
@onready var dialogueZone: DialogueZone = $DialogueZone
@onready var animationPlayer = $AnimationPlayer
@onready var collisionShape = $CollisionShape2D

@export var doorButtons: Array[Area2D]

var bodies_on_button := {}
var door_opened := false

func _ready() -> void:
	for button in doorButtons:
		button.body_entered.connect(on_door_button_body_entered.bind(button))
		button.body_exited.connect(on_door_button_body_exited.bind(button))
		bodies_on_button[button] = 0

func check_all_buttons():
	if door_opened:
		return
		
	for count in bodies_on_button.values():
		if count == 0:
			return
			
	# If we get here, it means all buttons have at least 1 body on them
	open_door()

func open_door():
	door_opened = true
	dungeon.open_door()
	
	animationPlayer.play("Open")
	collisionShape.set_deferred("disabled", true)
	dialogueZone.queue_free()

func on_door_button_body_entered(_body: Node2D, button: Area2D):
	if door_opened:
		return
	
	# Only play sound/animation if this is the FIRST body to press the button
	if bodies_on_button[button] == 0:
		button.interact("On")

	bodies_on_button[button] += 1
	check_all_buttons()

func on_door_button_body_exited(_body: Node2D, button: Area2D):
	if door_opened or bodies_on_button.get(button, 0) == 0:
		return

	bodies_on_button[button] -= 1

	# Only play sound/animation if this was the LAST body to leave the button
	if bodies_on_button[button] == 0:
		button.interact("Off")

func _on_door_transition_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		TransitionHandler.fade_out(get_tree().current_scene, "res://dungeon_2.tscn", 0.8)
		Events.player_transition = "up"
