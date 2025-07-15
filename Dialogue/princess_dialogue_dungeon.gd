extends Node

@onready var dialogueRoomManager = $"../../DialogueRoomManager"
@export var markers: Array[Marker2D]

func _ready() -> void:
	Events.dialogue_movement.connect(_on_dialogue_movement)
	
func _on_dialogue_movement(key: String) -> void:
	for marker in markers:
		if marker.name == key:
			get_parent().move_to_position_astar(marker.global_position)
			return
	
func _on_hurtbox_area_entered(_area: Area2D) -> void:
	if not Events.princess_dialogue_value or Events.princess_dialogue_value == "talked_loop":
		dialogueRoomManager.dialogue("hit")
	else:
		dialogueRoomManager.dialogue("hit_loop")

func _on_dialogue_zone_zone_triggered() -> void:
	var value = Events.princess_dialogue_value
	match value:
		"":
			dialogueRoomManager.dialogue("start")
		"talked_loop":
			dialogueRoomManager.dialogue("talked_loop")
		"exit_ghost_room":
			dialogueRoomManager.dialogue("fled")
			Events.princess_dialogue_value = "fled_loop"
		"fled_loop":
			dialogueRoomManager.dialogue("fled_loop")
		"fled_visited_door":
			dialogueRoomManager.dialogue("fled_visited_door")
		"door_help":
			dialogueRoomManager.dialogue("door_help")
