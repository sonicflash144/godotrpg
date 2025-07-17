extends Node

@onready var player: CharacterBody2D = $"../Player"

@export var dialogueResource: DialogueResource

var balloon_top = "res://Dialogue/balloon_top.tscn"
var balloon_bottom = "res://Dialogue/balloon.tscn"

func _ready():
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func get_balloon_path():
	if player.global_position.y > get_viewport().get_camera_2d().get_screen_center_position().y:
		return balloon_top
	else:
		return balloon_bottom

func dialogue(value: String, balloon_override: String = ""):
	var balloon_path
	if balloon_override == "top":
		balloon_path = balloon_top
	elif balloon_override == "bottom":
		balloon_path = balloon_bottom
	else:
		balloon_path = get_balloon_path()
	Events.controlsEnabled = false
	DialogueManager.show_dialogue_balloon(dialogueResource, value, balloon_path)

func _on_dialogue_ended(_resource: DialogueResource):
	await get_tree().create_timer(0.1).timeout
	Events.controlsEnabled = true

func nudge_player(valid_position: Vector2):
	var direction = (valid_position - player.global_position).normalized()
	var push = direction * 4
	player.global_position += push
