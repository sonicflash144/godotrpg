extends Node2D

@onready var dialogueRoomManager = $DialogueRoomManager
@onready var player = $Player
@onready var DungeonRoom1 = $DungeonRoom1
@onready var DungeonRoom2 = $DungeonRoom2
@onready var DungeonRoom3 = $DungeonRoom3

var last_valid_position: Vector2
var currentRoom: Node2D

func _ready():
	Events.playerDead = false
	Events.player_has_sword = true
	Events.room_entered.connect(_on_room_entered)
	Events.room_locked.connect(_on_room_locked)
	#Events.room_exited.connect(on_room_exited)
	
	await load_first_room()
	combat_lock_signal()

func load_first_room() -> void:
	while currentRoom == null:
		await get_tree().process_frame
	await get_tree().create_timer(1).timeout

func _physics_process(_delta: float) -> void:
	if player:
		last_valid_position = player.global_position

func combat_lock_signal():
	currentRoom.combat_lock_room()

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
	if room == DungeonRoom2 and value == "enter_ghost_room":
		dialogueRoomManager.dialogue("ghost_room")
	if room == DungeonRoom3 and value == "door":
		dialogueRoomManager.dialogue("door")

func dialogue_barrier(_key: String):
	var value = Events.princess_dialogue_value
	if not value:
		dialogueRoomManager.nudge_player(last_valid_position)
		dialogueRoomManager.dialogue("ignore")
	elif value == "talked_loop":
		dialogueRoomManager.nudge_player(last_valid_position)
		dialogueRoomManager.dialogue("talked_loop")

func _on_dialogue_zone_zone_triggered() -> void:
	dialogueRoomManager.dialogue("door_description")
	
func open_door() -> void:
	dialogueRoomManager.dialogue("door_opened")

func _on_health_component_player_died() -> void:
	Events.princess_dialogue_value = ""
	await get_tree().create_timer(1).timeout
	get_tree().reload_current_scene()
