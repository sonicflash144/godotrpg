extends Node2D

@onready var dialogueRoomManager = $DialogueRoomManager
@onready var player: CharacterBody2D = $Player
@onready var princess: CharacterBody2D = $Princess
@onready var DungeonRoom2: DungeonRoom = $DungeonRoom2
@onready var DungeonRoom3: DungeonRoom = $DungeonRoom3
@onready var DungeonRoom4: DungeonRoom = $DungeonRoom4
@onready var dialogueBarrier: Area2D = $DialogueBarrier
@onready var shopkeeperDialogueBarrier: Area2D = $ShopkeeperDialogueBarrier
@onready var chest = $Chest
@onready var chest2 = $Chest2
@onready var sideDoor = $SideDoor

var last_valid_position: Vector2
var currentRoom: DungeonRoom
var ironSword = load("res://Equipment/iron_sword.tres")
var overpricedChestplate = load("res://Equipment/overpriced_armor.tres")
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
		player.global_position = dialogueBarrier.global_position + Vector2(0, -16)
		player.movement_component.update_animation_direction(Vector2.UP)

func _physics_process(_delta: float) -> void:
	last_valid_position = player.global_position

func combat_lock_signal():
	currentRoom.combat_lock_room()

func dialogue_barrier(key: String):
	dialogueRoomManager.nudge_player(last_valid_position)
	dialogueRoomManager.dialogue(key)

func _on_room_entered(room):
	currentRoom = room
	if room == DungeonRoom4:
		princess.set_follow_state()
		
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

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_killall"):
		currentRoom.debug_killall()

func _on_shopkeeper_dialogue_zone_zone_triggered() -> void:
	if Events.dungeon_2_dialogue_value == "":
		dialogueRoomManager.dialogue("shopkeeper")
	else:
		dialogueRoomManager.dialogue("shopkeeper_talk_loop")

func remove_shopkeeper_dialogue_barrier():
	shopkeeperDialogueBarrier.queue_free()

func _on_chest_dialogue_zone_zone_triggered() -> void:
	chest.open_chest()
	dialogueRoomManager.dialogue("chest_description")
	player.storage.append(ironSword)

func _on_chest_2_dialogue_zone_zone_triggered() -> void:
	chest2.open_chest()
	dialogueRoomManager.dialogue("chest2_description")
	player.storage.append(overpricedChestplate)

func _on_side_door_dialogue_zone_zone_triggered() -> void:
	dialogueRoomManager.dialogue("side_door_description")

func _on_box_puzzle_puzzle_complete() -> void:
	sideDoor.queue_free()
	var doorSound = DoorSound.instantiate()
	get_tree().current_scene.add_child(doorSound)
	dialogueRoomManager.dialogue("puzzle_complete")
