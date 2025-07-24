extends Node2D

@onready var dialogueRoomManager = $DialogueRoomManager
@onready var player: CharacterBody2D = $Player
@onready var transitionArea = $TransitionArea
@onready var sandwich: DialogueZone = $SandwichDialogueZone
@onready var sword: DialogueZone = $SwordDialogueZone
@onready var guard = $Guard
@onready var guard2 = $Guard2
@onready var genericGuard = $GenericGuard
@onready var genericGuard2 = $GenericGuard2
@onready var genericGuard3 = $GenericGuard3
@onready var marker: Marker2D = $guard2_enter
@onready var genericDoor = $GenericDoor

var EquipSound = load("res://Music and Sounds/equip_sound.tscn")
var DoorSound = load("res://Music and Sounds/door_sound.tscn")

func _ready() -> void:
	Events.num_party_members = 1
	Events.player_has_sword = false
	Events.dialogue_movement.connect(_on_dialogue_movement)
	
	if Events.player_transition == "down":
		player.global_position = transitionArea.global_position
	
func eat_sandwich():
	sandwich.queue_free()
	Events.prison_dialogue_value = "sandwich"
	
func take_sword():
	sword.queue_free()
	var equipSound = EquipSound.instantiate()
	get_tree().current_scene.add_child(equipSound)
	
func open_generic_door():
	genericDoor.queue_free()
	var doorSound = DoorSound.instantiate()
	get_tree().current_scene.add_child(doorSound)

func player_face_guard():
	var playerAnimationTree = player.get_node_or_null("AnimationTree")
	var direction = player.global_position.direction_to(guard.global_position)
	playerAnimationTree.set("parameters/Idle/blend_position", direction)
	
func guard_face_guard2():
	var guardAnimationTree = guard.get_node_or_null("AnimationTree")
	var direction = guard.global_position.direction_to(guard2.global_position)
	guardAnimationTree.set("parameters/Idle/blend_position", direction)
	
func guard_face_player():
	var guardAnimationTree = guard.get_node_or_null("AnimationTree")
	var direction = guard.global_position.direction_to(player.global_position)
	guardAnimationTree.set("parameters/Idle/blend_position", direction)

func _on_dialogue_movement(key: String):
	if key == "guard_return":
		guard.move_to_position_astar(player.global_position + Vector2(-32, 0))
	elif key == "guard2_enter":
		guard2.move_to_position_astar(marker.global_position)
		genericGuard.move_to_position_astar(marker.global_position + Vector2(-16, 16))
		genericGuard2.move_to_position_astar(marker.global_position + Vector2(-32, 0))
		genericGuard3.move_to_position_astar(marker.global_position + Vector2(-16, -16))
		
func _on_transition_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		TransitionHandler.fade_out(get_tree().current_scene, "res://prison0.tscn", 0.8)
		Events.player_transition = "up"

func transition_to_dungeon():
	TransitionHandler.fade_out(get_tree().current_scene, "res://dungeon.tscn", 0.8)
