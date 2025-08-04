extends Node2D

@onready var dialogueRoomManager: DialogueRoomManager = $DialogueRoomManager

func _ready() -> void:
	await get_tree().create_timer(1).timeout
	dialogueRoomManager.dialogue("enter_hall")

func _on_transition_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		TransitionHandler.console_fade_out("throne_room")
		Events.player_transition = "up"
