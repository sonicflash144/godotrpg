extends Node

class_name DialogueRoomManager

@onready var player: CharacterBody2D = $"../Player"

@export var dialogueResource: DialogueResource

const balloon_top = "res://Dialogue/balloon_top.tscn"
const balloon_bottom = "res://Dialogue/balloon.tscn"

var enableControlsOverride := false

func _ready() -> void:
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
func get_balloon_path():
	if player.global_position.y > get_viewport().get_camera_2d().get_screen_center_position().y:
		return balloon_top
	else:
		return balloon_bottom

func dialogue(value: String, balloon_override: String = "", controls_override := false):
	enableControlsOverride = controls_override
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
	if enableControlsOverride:
		enableControlsOverride = false
	else:
		Events.enable_controls()

func nudge_player():
	var direction = player.movement_component.animation_tree.get("parameters/Run/blend_position").normalized()
	var push = -direction * 4
	player.global_position += push
