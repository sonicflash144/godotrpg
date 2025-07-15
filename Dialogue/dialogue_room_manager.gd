extends Node

@onready var player = $"../Player"

@export var dialogueResource: DialogueResource

func _ready():
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func dialogue(value: String, balloon_override: String = ""):
	var balloon_path
	if balloon_override == "top":
		balloon_path = "res://Dialogue/balloon_top.tscn"
	elif balloon_override == "bottom":
		balloon_path = "res://Dialogue/balloon.tscn"
	else:
		balloon_path = get_balloon_path()
	Events.controlsEnabled = false
	DialogueManager.show_dialogue_balloon(dialogueResource, value, balloon_path)

func get_balloon_path():
	if player.global_position.y > get_viewport().get_camera_2d().get_screen_center_position().y:
		return "res://Dialogue/balloon_top.tscn"
	else:
		return "res://Dialogue/balloon.tscn"

func _on_dialogue_ended(_resource: DialogueResource):
	await get_tree().create_timer(0.1).timeout
	Events.controlsEnabled = true

func nudge_player(valid_position: Vector2):
	var direction = (valid_position - player.global_position).normalized()
	var push = direction * 4
	player.global_position += push
