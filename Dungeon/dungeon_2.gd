extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var DungeonRoom1: DungeonRoom = $DungeonRoom1
@onready var DungeonRoom2: DungeonRoom = $DungeonRoom2
@onready var DungeonRoom3: DungeonRoom = $DungeonRoom3

var last_valid_position: Vector2
var currentRoom: DungeonRoom

func _ready() -> void:
	Events.playerDown = false
	Events.princessDown = false
	Events.playerDead = false
	Events.is_player_controlled = true
	
	Events.room_entered.connect(_on_room_entered)
	Events.room_locked.connect(_on_room_locked)
	Events.player_died.connect(_on_player_died)

func _physics_process(_delta: float) -> void:
	last_valid_position = player.global_position

func combat_lock_signal():
	currentRoom.combat_lock_room()
		
func _on_room_entered(room):
	currentRoom = room
		
func _on_room_locked(room):
	if room == DungeonRoom2:
		combat_lock_signal()
	
func _on_player_died():
	await get_tree().create_timer(1).timeout
	get_tree().reload_current_scene()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_killall"):
		currentRoom.debug_killall()
