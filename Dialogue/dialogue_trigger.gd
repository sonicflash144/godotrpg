extends Area2D

@export var key: String

var dialogueRoomManager: DialogueRoomManager
var dialoguePlaying := false

func _ready() -> void:	
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	dialogueRoomManager = find_dialogue_room_manager()

func find_dialogue_room_manager() -> DialogueRoomManager:
	var current_node = get_parent()
	while current_node:
		var potential_manager = current_node.get_node_or_null("DialogueRoomManager")
		if potential_manager and potential_manager is DialogueRoomManager:
			return potential_manager
		current_node = current_node.get_parent()
	return null

func _on_dialogue_ended(_resource: DialogueResource):
	dialoguePlaying = false

func _on_body_entered(body: Node2D) -> void:
	if Events.get_flag(key):
		queue_free()
	elif body.is_in_group("Player") and not dialoguePlaying:
		dialogueRoomManager.dialogue(key)
		Events.set_flag(key)
		queue_free()
