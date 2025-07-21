extends Node2D

@onready var dialogueRoomManager = $DialogueRoomManager
@onready var player: CharacterBody2D = $Player
@onready var princess: CharacterBody2D = $Princess
@onready var DungeonRoom0: DungeonRoom = $DungeonRoom0
@onready var DungeonRoom2: DungeonRoom = $DungeonRoom2
@onready var DungeonRoom3: DungeonRoom = $DungeonRoom3

var last_valid_position: Vector2
var currentRoom: DungeonRoom

func _ready() -> void:
	Events.playerDown = false
	Events.princessDown = true
	Events.playerDead = false
	
	Events.player_has_sword = true
	Events.num_party_members = 1
	
	Events.room_entered.connect(_on_room_entered)
	Events.room_locked.connect(_on_room_locked)
	Events.player_died.connect(_on_player_died)
	
	princess.set_nav_state()

func _physics_process(_delta: float) -> void:
	last_valid_position = player.global_position

func combat_lock_signal():
	currentRoom.combat_lock_room()

func dialogue_barrier(_key: String):
	var value = Events.princess_dialogue_value
	if not value:
		dialogueRoomManager.nudge_player(last_valid_position)
		dialogueRoomManager.dialogue("ignore")
	elif value == "talked_loop":
		dialogueRoomManager.nudge_player(last_valid_position)
		dialogueRoomManager.dialogue("talked_loop")

func open_door():
	dialogueRoomManager.dialogue("door_opened")
	
func set_princess_follow_state():
	princess.set_follow_state()
	
func _on_room_entered(room):
	currentRoom = room
	if room == DungeonRoom3:
		var value = Events.princess_dialogue_value
		if value == "door":
			return
		elif value == "fled_loop":
			Events.princess_dialogue_value = "door_help"
		elif value == "exit_ghost_room":
			Events.princess_dialogue_value = "fled_visited_door"

func _on_room_locked(room):
	var value = Events.princess_dialogue_value
	if room == DungeonRoom0:
		combat_lock_signal()
	if room == DungeonRoom2 and value == "enter_ghost_room":
		dialogueRoomManager.dialogue("ghost_room")
	if room == DungeonRoom3 and value == "door":
		dialogueRoomManager.dialogue("door")
	
func _on_player_died():
	Events.princess_dialogue_value = ""
	await get_tree().create_timer(1).timeout
	get_tree().reload_current_scene()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_killall"):
		currentRoom.debug_killall()
		
func _on_dialogue_zone_zone_triggered() -> void:
	dialogueRoomManager.dialogue("door_description")
