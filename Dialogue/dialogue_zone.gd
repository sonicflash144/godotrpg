extends Area2D

class_name DialogueZone

signal zone_triggered()

var dialoguePlaying := false
var inDialogueZone := false

func _ready() -> void:
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		inDialogueZone = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		inDialogueZone = false
	
func _on_dialogue_ended(_resource: DialogueResource):
	dialoguePlaying = false
	
func _unhandled_key_input(event: InputEvent) -> void:
	if inDialogueZone and not dialoguePlaying and event.is_action_pressed("ui_accept"):
		dialoguePlaying = true
		zone_triggered.emit()
