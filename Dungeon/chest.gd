extends StaticBody2D

class_name Chest

@onready var animationPlayer = $AnimationPlayer
@onready var openSound = $OpenSound
@onready var dialogueZone = $ChestDialogueZone
@onready var player: CharacterBody2D = $"../../Player"

@export var item: Equipment

var key: String

func _ready() -> void:
	var file_name = item.resource_path.get_file().get_basename()
	key = "chest_" + file_name.to_lower().replace(" ", "_")
	dialogueZone.default_key = key
	
	await get_tree().process_frame
	if Events.get_flag(key):
		animationPlayer.play("Open")
		dialogueZone.queue_free()
		return

func open_chest():
	openSound.play()
	animationPlayer.play("Open")
	player.storage.append(item)
	Events.set_flag(key)
	dialogueZone.queue_free()

func _on_chest_dialogue_zone_zone_triggered() -> void:
	open_chest()
