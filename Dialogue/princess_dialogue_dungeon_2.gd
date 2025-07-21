extends Node

@onready var dialogueRoomManager = $"../../DialogueRoomManager"

@export var markers: Array[Marker2D]

func _ready() -> void:
	Events.dialogue_movement.connect(_on_dialogue_movement)
	
func _on_dialogue_movement(key: String):
	for marker in markers:
		if marker.name == key:
			get_parent().move_to_position_astar(marker.global_position)
			return

func _on_dialogue_zone_zone_triggered() -> void:
	if Events.dungeon_2_dialogue_value == "enter_puzzle_room_loop":
		dialogueRoomManager.dialogue("enter_puzzle_room_loop")
