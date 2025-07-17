extends Node2D

@onready var dialogueRoomManager = $DialogueRoomManager
@onready var player: CharacterBody2D = $Player
@onready var transitionArea = $TransitionArea
@onready var guard = $Guard
@onready var marker: Marker2D = $Marker2D
@onready var door = $Door
@onready var animationPlayer = $AnimationPlayer
@onready var alarmSound: AudioStreamPlayer = $Alarm

var DoorSound = load("res://Music and Sounds/door_sound.tscn")
var guardOriginalPosition: Vector2

func _ready() -> void:
	Events.player_has_sword = false
	Events.dialogue_movement.connect(_on_dialogue_movement)
	
	if Events.prisonDoorOpened:
		door.queue_free()
	
	if Events.player_transition == "up":
		player.global_position = transitionArea.global_position
		var animationTree = player.get_node_or_null("AnimationTree")
		animationTree.set("parameters/Idle/blend_position", Vector2.UP)
		
	guardOriginalPosition = guard.global_position

func _on_dialogue_movement(key: String) -> void:
	if key == "guard_enter":
		guard.move_to_position_astar(marker.global_position)
	elif key == "guard_leave":
		guard.move_to_position_astar(guardOriginalPosition)

func _on_wall_dialogue_zone_zone_triggered() -> void:
	dialogueRoomManager.dialogue("wall_description")

func _on_blood_dialogue_zone_zone_triggered() -> void:
	dialogueRoomManager.dialogue("blood_description")
	
func _on_vent_dialogue_zone_zone_triggered() -> void:
	dialogueRoomManager.dialogue("vent_description")

func _on_door_dialogue_zone_zone_triggered() -> void:
	dialogueRoomManager.dialogue("cell_door_description")

func open_prison_door():
	door.queue_free()
	var doorSound = DoorSound.instantiate()
	get_tree().current_scene.add_child(doorSound)
	Events.prisonDoorOpened = true
	
func alarm_animation():
	alarmSound.play()
	animationPlayer.play("alarm")

func _on_transition_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		TransitionHandler.fade_out(get_tree().current_scene, "res://prison1.tscn", 0.8)
		Events.player_transition = "down"
