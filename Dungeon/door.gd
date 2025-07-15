extends StaticBody2D

@onready var dungeon = $".."
@onready var buttonSound: AudioStreamPlayer = $Button
@onready var dialogueZone: Area2D = $DialogueZone
@onready var animatedSprite = $AnimatedSprite2D
@onready var collisionShape = $CollisionShape2D

@export var doorButtons: Array[Area2D]

var DoorSound = load("res://Music and Sounds/door_sound.tscn")

var pressed_buttons := {}
var door_opened := false

func _ready():
	for button in doorButtons:
		button.body_entered.connect(on_door_button_body_entered.bind(button))
		button.body_exited.connect(on_door_button_body_exited.bind(button))
		pressed_buttons[button] = false

func on_door_button_body_entered(_body: Node2D, button: Node) -> void:
	if door_opened:
		return
	
	buttonSound.play()
	var anim_sprite = button.get_node_or_null("AnimatedSprite2D")
	anim_sprite.play("On")

	pressed_buttons[button] = true
	check_all_buttons()

func on_door_button_body_exited(_body: Node2D, button: Node) -> void:
	if door_opened:
		return

	buttonSound.play()
	var anim_sprite = button.get_node_or_null("AnimatedSprite2D")
	anim_sprite.play("Off")

	pressed_buttons[button] = false

func check_all_buttons():
	for state in pressed_buttons.values():
		if not state:
			return  # At least one button not pressed
	open_door()

func open_door():
	var doorSound = DoorSound.instantiate()
	get_tree().current_scene.add_child(doorSound)
	door_opened = true
	dungeon.open_door()
	
	animatedSprite.play("Open")
	collisionShape.set_deferred("disabled", true)
	dialogueZone.queue_free()

func _on_door_transition_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print("SCENE TRANSITION")
