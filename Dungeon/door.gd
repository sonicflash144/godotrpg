extends StaticBody2D

@onready var dungeon = $".."
@onready var buttonSound: AudioStreamPlayer = $Button
@onready var doorSound: AudioStreamPlayer = $Door
@onready var dialogueZone: Area2D = $DialogueZone
@onready var animatedSprite = $AnimatedSprite2D
@onready var collisionShape = $CollisionShape2D

@export var doorButtons: Array[Area2D]

# Use a dictionary to store the count of bodies on each button
var bodies_on_button := {}
var door_opened := false

func _ready():
	for button in doorButtons:
		# Connect signals and initialize the body count for each button to 0
		button.body_entered.connect(on_door_button_body_entered.bind(button))
		button.body_exited.connect(on_door_button_body_exited.bind(button))
		bodies_on_button[button] = 0

func on_door_button_body_entered(_body: Node2D, button: Area2D) -> void:
	if door_opened:
		return
	
	# Only play sound/animation if this is the FIRST body to press the button
	if bodies_on_button[button] == 0:
		buttonSound.play()
		var anim_sprite = button.get_node_or_null("AnimatedSprite2D")
		if anim_sprite:
			anim_sprite.play("On")

	# Increment the count of bodies on the button
	bodies_on_button[button] += 1
	check_all_buttons()

func on_door_button_body_exited(_body: Node2D, button: Area2D) -> void:
	# Ignore if the door is open or if the count is somehow already zero
	if door_opened or bodies_on_button.get(button, 0) == 0:
		return

	# Decrement the count of bodies on the button
	bodies_on_button[button] -= 1

	# Only play sound/animation if this was the LAST body to leave the button
	if bodies_on_button[button] == 0:
		buttonSound.play()
		var anim_sprite = button.get_node_or_null("AnimatedSprite2D")
		if anim_sprite:
			anim_sprite.play("Off")

func check_all_buttons():
	if door_opened:
		return
		
	for count in bodies_on_button.values():
		# If any button has 0 bodies on it, the condition is not met
		if count == 0:
			return
			
	# If we get here, it means all buttons have at least 1 body on them
	open_door()

func open_door():
	doorSound.play()
	door_opened = true
	dungeon.open_door()
	
	animatedSprite.play("Open")
	collisionShape.set_deferred("disabled", true)
	if is_instance_valid(dialogueZone):
		dialogueZone.queue_free()

func _on_door_transition_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print("SCENE TRANSITION")
