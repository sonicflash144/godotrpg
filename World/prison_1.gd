extends Node2D

@onready var dialogueRoomManager = $DialogueRoomManager
@onready var player: CharacterBody2D = $Player
@onready var transitionArea = $TransitionArea
@onready var sandwich: DialogueZone = $SandwichDialogueZone
@onready var sword: DialogueZone = $SwordDialogueZone
@onready var guard = $Guard
@onready var guard2 = $Guard2
@onready var genericGuard = $GenericGuard
@onready var genericGuard2 = $GenericGuard2
@onready var genericGuard3 = $GenericGuard3
@onready var marker: Marker2D = $guard2_enter
@onready var genericDoor = $GenericDoor
@onready var equipSound: AudioStreamPlayer = $EquipSound
@onready var doorSound: AudioStreamPlayer = $DoorSound

func _ready() -> void:
	Events.num_party_members = 1
	Events.player_has_sword = false
	Events.set_flag("prison_door_opened")
	Events.dialogue_movement.connect(_on_dialogue_movement)
	
	if Events.player_transition == "down":
		player.global_position = transitionArea.global_position
		
	await get_tree().process_frame
	if Events.get_flag("ate_sandwich"):
		sandwich.queue_free()
		
	MusicManager.play_track(MusicManager.Track.HALL)

func eat_sandwich():
	sandwich.queue_free()

func take_sword():
	sword.queue_free()
	equipSound.play()
	
func open_generic_door():
	genericDoor.queue_free()
	doorSound.play()

func player_face_guard():
	var playerAnimationTree = player.get_node_or_null("AnimationTree")
	var direction = player.global_position.direction_to(guard.global_position)
	playerAnimationTree.set("parameters/Idle/blend_position", direction)
	
func guard_face_guard2():
	var guardAnimationTree = guard.get_node_or_null("AnimationTree")
	var direction = guard.global_position.direction_to(guard2.global_position)
	guardAnimationTree.set("parameters/Idle/blend_position", direction)
	
func guard_face_player():
	var guardAnimationTree = guard.get_node_or_null("AnimationTree")
	var direction = guard.global_position.direction_to(player.global_position)
	guardAnimationTree.set("parameters/Idle/blend_position", direction)

func _on_dialogue_movement(key: String):
	if key == "guard_return":
		guard.move_to_position_astar(player.global_position + Vector2(-32, 0))
	elif key == "guard2_enter":
		guard2.move_to_position_astar(marker.global_position)
		genericGuard.move_to_position_astar(marker.global_position + Vector2(-16, 16))
		genericGuard2.move_to_position_astar(marker.global_position + Vector2(-32, 0))
		genericGuard3.move_to_position_astar(marker.global_position + Vector2(-16, -16))
		
func _on_transition_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		TransitionHandler.console_fade_out("prison0")
		Events.player_transition = "up"

func transition_to_dungeon():
	TransitionHandler.console_fade_out("dungeon")
