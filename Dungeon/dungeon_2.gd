extends Node2D

@onready var dialogueRoomManager = $DialogueRoomManager
@onready var player: CharacterBody2D = $Player
@onready var princess: CharacterBody2D = $Princess
@onready var DungeonRoom2: DungeonRoom = $DungeonRoom2
@onready var DungeonRoom3: DungeonRoom = $DungeonRoom3
@onready var goBackdialogueBarrier: DialogueBarrier = $"DungeonRoom0/GoBackDialogueBarrier"
@onready var shopkeeperDialogueBarrier: DialogueBarrier = $"DungeonRoom1/ShopkeeperDialogueBarrier"
@onready var sideDoor = $"DungeonRoom3/SideDoor"
@onready var princessFollowCheck = $"DungeonRoom3/PrincessFollowCheck"

var last_valid_position: Vector2
var currentRoom: DungeonRoom
var ironSword: Equipment = load("res://Equipment/iron_sword.tres")
var overpricedArmor: Equipment = load("res://Equipment/overpriced_armor.tres")
var DoorSound = load("res://Music and Sounds/door_sound.tscn")

func _ready() -> void:
	Events.playerDown = false
	Events.princessDown = false
	Events.playerDead = false
	Events.is_player_controlled = true
	
	Events.room_entered.connect(_on_room_entered)
	Events.room_locked.connect(_on_room_locked)
	Events.player_died.connect(_on_player_died)
	
	if Events.player_transition == "up":
		player.global_position = goBackdialogueBarrier.global_position + Vector2(0, -16)
		player.movement_component.update_animation_direction(Vector2.UP)

func _physics_process(_delta: float) -> void:
	last_valid_position = player.global_position

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_killall"):
		currentRoom.debug_killall()

func combat_lock_signal():
	currentRoom.combat_lock_room()

func dialogue_barrier(key: String):
	if key == "princess_follow_check":
		if not sideDoor:
			princess.set_follow_state()
			princessFollowCheck.queue_free()
	else:
		dialogueRoomManager.nudge_player(last_valid_position)
		dialogueRoomManager.dialogue(key)

func remove_shopkeeper_dialogue_barrier():
	shopkeeperDialogueBarrier.queue_free()

func _on_room_entered(room):
	currentRoom = room
		
func _on_room_locked(room):
	if room == DungeonRoom2:
		combat_lock_signal()
		Events.dungeon_2_dialogue_value = "room_2_arena"
	elif room == DungeonRoom3 and Events.dungeon_2_dialogue_value == "room_2_arena":
		princess.set_nav_state()
		dialogueRoomManager.dialogue("enter_puzzle_room")
	
func _on_player_died():
	await get_tree().create_timer(1).timeout
	get_tree().reload_current_scene()

func _on_box_puzzle_puzzle_complete() -> void:
	sideDoor.queue_free()
	var doorSound = DoorSound.instantiate()
	get_tree().current_scene.add_child(doorSound)
	dialogueRoomManager.dialogue("puzzle_complete")
