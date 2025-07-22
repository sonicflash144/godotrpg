extends StaticBody2D

class_name Chest

@onready var animationPlayer = $AnimationPlayer
@onready var dialogueZone = $ChestDialogueZone
@onready var player: CharacterBody2D = $"../../Player"

@export var item: Equipment

func _ready() -> void:
	var file_name = item.resource_path.get_file().get_basename()
	dialogueZone.default_key = "chest_" + file_name

func open_chest():
	animationPlayer.play("Open")
	player.storage.append(item)
	dialogueZone.queue_free()

func _on_chest_dialogue_zone_zone_triggered() -> void:
	open_chest()
