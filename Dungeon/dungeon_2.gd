extends Node2D

@onready var dialogueRoomManager: DialogueRoomManager = $DialogueRoomManager
@onready var pathfindingManager: PathfindingManager = $PathfindingManager
@onready var player: CharacterBody2D = $Player
@onready var princess: CharacterBody2D = $Princess
@onready var princessCollider = $"Princess/CollisionShape2D"
@onready var princessHurtbox: Hurtbox = $"Princess/Hurtbox"
@onready var princessBlinkAnimation = $"Princess/BlinkAnimationPlayer"
@onready var DungeonRoom0: DungeonRoom = $DungeonRoom0
@onready var DungeonRoom2: DungeonRoom = $DungeonRoom2
@onready var DungeonRoom3: DungeonRoom = $DungeonRoom3
@onready var DungeonRoom4: DungeonRoom = $DungeonRoom4
@onready var DungeonRoom5: DungeonRoom = $DungeonRoom5
@onready var DungeonRoom6: DungeonRoom = $DungeonRoom6
@onready var DungeonRoom7: DungeonRoom = $DungeonRoom7
@onready var goBackdialogueBarrier: DialogueBarrier = $"DungeonRoom0/GoBackDialogueBarrier"
@onready var shopkeeperDialogueBarrier: DialogueBarrier = $"DungeonRoom1/ShopkeeperDialogueBarrier"
@onready var sideDoor = $"DungeonRoom3/SideDoor"
@onready var princessFollowCheck = $"DungeonRoom3/PrincessFollowCheck"
@onready var afterLasersDialogueBarrierCollisionShape = $DungeonRoom6/DialogueBarrier/CollisionShape2D

@export var markers: Array[Marker2D]

var last_valid_position: Vector2
var currentRoom: DungeonRoom
var puzzle_complete := false
var overworld_hazard_active := false
var ironSword: Equipment = load("res://Equipment/iron_sword.tres")
var overpricedArmor: Equipment = load("res://Equipment/overpriced_armor.tres")
var DoorSound = load("res://Music and Sounds/door_sound.tscn")

func _ready() -> void:
	Events.playerDown = false
	Events.princessDown = false
	Events.playerDead = false
	Events.is_player_controlled = true
	
	Events.room_entered.connect(_on_room_entered)
	Events.room_exited.connect(_on_room_exited)
	Events.room_locked.connect(_on_room_locked)
	Events.player_died.connect(_on_player_died)
	Events.dialogue_movement.connect(_on_dialogue_movement)
	
	if Events.player_transition == "up":
		player.global_position = goBackdialogueBarrier.global_position + Vector2(0, -16)
		player.movement_component.update_animation_direction(Vector2.UP)
		
	if Events.get_flag("met_shopkeeper"):
		remove_shopkeeper_dialogue_barrier()

func _physics_process(_delta: float) -> void:
	last_valid_position = player.global_position

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_killall"):
		currentRoom.debug_killall()

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

func puzzle_completed():
	puzzle_complete = true

func start_overworld_hazard():
	overworld_hazard_active = true
	princessCollider.set_deferred("disabled", true)
	princessHurtbox.disable_collider()
	princessBlinkAnimation.play("Disabled")
	princess.z_index = -1

func end_overworld_hazard():
	overworld_hazard_active = false
	if Events.combat_locked:
		return
	princessCollider.set_deferred("disabled", false)
	princessHurtbox.enable_collider()
	princessBlinkAnimation.play("RESET")
	princess.z_index = 0

func _on_room_entered(room):
	currentRoom = room
	if room == DungeonRoom4 or room == DungeonRoom5:
		start_overworld_hazard()
		room.activate_lasers()
	elif overworld_hazard_active:
		end_overworld_hazard()
		
func _on_room_exited(room):
	currentRoom = room
	if room == DungeonRoom4 or room == DungeonRoom5:
		room.deactivate_lasers()
		
func _on_room_locked(room):
	if room == DungeonRoom2:
		room.combat_lock_room()
	elif room == DungeonRoom3 and not puzzle_complete:
		princess.set_nav_state()
		if not Events.get_flag("puzzle_started"):
			dialogueRoomManager.dialogue("enter_puzzle_room")
		else:
			_on_dialogue_movement("enter_puzzle_room")
	elif room == DungeonRoom6 and not Events.get_flag("met_THE_prisoner"):
		dialogueRoomManager.dialogue("THE_prisoner_intro")
		afterLasersDialogueBarrierCollisionShape.set_deferred("disabled", false)
	elif room == DungeonRoom7:
		room.combat_lock_room()
	
func _on_player_died():
	await get_tree().create_timer(1).timeout
	get_tree().reload_current_scene()

func _on_dialogue_movement(key: String):
	for marker in markers:
		if marker.name == key:
			princess.move_to_position_astar(marker.global_position)
			return

func _on_box_puzzle_puzzle_complete() -> void:
	sideDoor.queue_free()
	var doorSound = DoorSound.instantiate()
	get_tree().current_scene.add_child(doorSound)
	dialogueRoomManager.dialogue("puzzle_complete")
