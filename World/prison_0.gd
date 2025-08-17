extends Node2D

@onready var dialogueRoomManager = $DialogueRoomManager
@onready var player: CharacterBody2D = $Player
@onready var transitionArea = $TransitionArea
@onready var guard = $Guard
@onready var marker: Marker2D = $Marker2D
@onready var door = $CellDoor
@onready var doorSound: AudioStreamPlayer = $DoorSound
@onready var animationPlayer = $AnimationPlayer
@onready var alarmSound: AudioStreamPlayer = $Alarm

var guardOriginalPosition: Vector2

func _ready() -> void:
	Events.num_party_members = 1
	Events.player_has_sword = false
	Events.dialogue_movement.connect(_on_dialogue_movement)
	
	if Events.player_transition == "up":
		player.global_position = transitionArea.global_position
		player.movement_component.update_animation_direction(Vector2.UP)
		
	guardOriginalPosition = guard.global_position
	
	await get_tree().process_frame
	if Events.get_flag("prison_door_opened"):
		door.queue_free()
	
	MusicManager.play_track(MusicManager.Track.PRISON)

func open_prison_door():
	door.queue_free()
	doorSound.play()
	Events.set_flag("prison_door_opened")
	
func alarm_animation():
	alarmSound.play()
	animationPlayer.play("alarm")

func _on_dialogue_movement(key: String):
	if key == "guard_enter":
		guard.move_to_position_astar(marker.global_position)
	elif key == "guard_leave":
		guard.move_to_position_astar(guardOriginalPosition)

func _on_transition_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		TransitionHandler.console_fade_out("prison1")
		Events.player_transition = "down"
