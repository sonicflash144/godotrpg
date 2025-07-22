extends Area2D

class_name DialogueZone

signal zone_triggered()

@export var default_key := ""

var dialogueRoomManager: DialogueRoomManager
var dialoguePlaying := false
var inDialogueZone := false

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

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		inDialogueZone = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		inDialogueZone = false
	
func _on_dialogue_ended(_resource: DialogueResource):
	dialoguePlaying = false
	
func _unhandled_key_input(event: InputEvent) -> void:
	if Events.controlsEnabled and inDialogueZone and not dialoguePlaying and event.is_action_pressed("ui_accept"):
		dialoguePlaying = true
		if default_key:
			dialogueRoomManager.dialogue(default_key)
		zone_triggered.emit()
