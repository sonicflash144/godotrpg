extends Node2D

@onready var player = $Player
@onready var DungeonRoom1 = $DungeonRoom1
@onready var DungeonRoom2 = $DungeonRoom2
@onready var DungeonRoom3 = $DungeonRoom3

var last_valid_position: Vector2
var currentRoom: Node2D

func _ready():
	Events.playerDown = false
	Events.princessDown = false
	Events.playerDead = false
	Events.is_player_controlled = true
	Events.player_died.connect(_on_player_died)
	Events.room_entered.connect(_on_room_entered)
	Events.room_locked.connect(_on_room_locked)

func _physics_process(_delta: float) -> void:
	if player:
		last_valid_position = player.global_position

func combat_lock_signal():
	currentRoom.combat_lock_room()
		
func _on_room_entered(room):
	currentRoom = room
		
func _on_room_locked(room):
	if room == DungeonRoom2:
		combat_lock_signal()
	
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_killall"):
		currentRoom.debug_killall()

func _on_player_died() -> void:
	await get_tree().create_timer(1).timeout
	get_tree().reload_current_scene()
