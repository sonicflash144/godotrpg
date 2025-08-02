extends Node2D

@onready var dialogueRoomManager: DialogueRoomManager = $DialogueRoomManager
@onready var pathfindingManager: PathfindingManager = $PathfindingManager
@onready var player: CharacterBody2D = $Player
@onready var princess: CharacterBody2D = $Princess
@onready var THE_Prisoner: CharacterBody2D = $ThePrisoner
@onready var playerHealthComponent: Health_Component = $Player/Health_Component
@onready var princessHealthComponent: Health_Component = $Princess/Health_Component

@onready var goBackdialogueBarrier: DialogueBarrier = $StartRoom/GoBackDialogueBarrier
@onready var CampfireRoom: DungeonRoom = $CampfireRoom
@onready var savePoint1 = $CampfireRoom/SavePoint1/Marker2D
@onready var pin1 = $LaserRoom1/JugglingPin1
@onready var pin2 = $LaserRoom2/JugglingPin2
@onready var pin3 = $ThePrisonerRoom/JugglingPin3
@onready var ThePrisonerRoom: DungeonRoom = $ThePrisonerRoom
@onready var ThePrisonerFollowCheck: DialogueBarrier = $ThePrisonerRoom/ThePrisonerFollowCheck
@onready var PuzzleRoom1: DungeonRoom = $PuzzleRoom1
@onready var princessFollowCheck1: DialogueBarrier = $PuzzleRoom1/PrincessFollowCheck1
@onready var savePoint2 = $ChestRoom/SavePoint2/Marker2D
@onready var DoorRoom: DungeonRoom = $DoorRoom

@export var markers: Array[Marker2D]

var last_valid_position: Vector2
var num_pins_collected := 0

func _ready() -> void:
	Events.playerDown = false
	Events.princessDown = false
	Events.playerDead = false
	Events.combat_locked = false
	Events.player_has_sword = true
	Events.num_party_members = 2
	Events.is_player_controlled = true
	
	Events.room_locked.connect(_on_room_locked)
	Events.player_died.connect(_on_player_died)
	Events.dialogue_movement.connect(_on_dialogue_movement)
	
	if not Events.deferred_load_data.is_empty() and Events.deferred_load_data.scene == "dungeon_3":
		var save_position = Vector2(Events.deferred_load_data["player_x_pos"], Events.deferred_load_data["player_y_pos"])
		player.position = save_position
		princess.position = save_position
		if Events.get_flag("met_THE_prisoner"):
			Events.num_party_members = 3
			THE_Prisoner.position = save_position
			THE_Prisoner.set_follow_state()
	elif Events.player_transition == "up":
		player.global_position = goBackdialogueBarrier.global_position + Vector2(0, -16)
		player.movement_component.update_animation_direction(Vector2.UP)
	
	await get_tree().process_frame
	
	if Events.get_flag("pin_1"):
		pin1.queue_free()
		num_pins_collected += 1
	if Events.get_flag("pin_2"):
		pin2.queue_free()
		num_pins_collected += 1
	if Events.get_flag("pin_3"):
		pin3.queue_free()
		num_pins_collected += 1
	
func _physics_process(_delta: float) -> void:
	last_valid_position = player.global_position
	
func dialogue_barrier(key: String):
	if key == "THE_prisoner_follow_check":
		Events.num_party_members = 3
		THE_Prisoner.set_follow_state()
		ThePrisonerFollowCheck.queue_free()
	elif key == "princess_follow_check_1":
		if PuzzleRoom1.roomCompleted:
			princess.set_follow_state()
			princessFollowCheck1.queue_free()
	else:
		dialogueRoomManager.nudge_player(last_valid_position)
		dialogueRoomManager.dialogue(key)

func save_point_helper(savePosition: Vector2):
	playerHealthComponent.heal(playerHealthComponent.MAX_HEALTH)
	princessHealthComponent.heal(princessHealthComponent.MAX_HEALTH)
	
	var playerEquipment: Array[String]
	var princessEquipment: Array[String]
	var storage: Array[String]
	
	for item in player.equipment:
		playerEquipment.append(item.name)
	for item in princess.equipment:
		princessEquipment.append(item.name)
	for item in player.storage:
		storage.append(item.name)
		
	Events.save_game(savePosition, playerEquipment, princessEquipment, storage)

func campfire_finished():
	player.set_move_state()
	princess.set_follow_state()

func _on_room_locked(room):
	if room == CampfireRoom and not Events.get_flag("campfire_completed"):
		player.set_nav_state()
		princess.set_nav_state()
		dialogueRoomManager.dialogue("campfire")
	elif room == ThePrisonerRoom and not Events.get_flag("met_THE_prisoner"):
		dialogueRoomManager.dialogue("THE_prisoner")
	elif room == DoorRoom and not Events.get_flag("before_THE_prisoner_fight"):
		princess.set_nav_state()
		THE_Prisoner.set_nav_state()
		dialogueRoomManager.dialogue("before_THE_prisoner_fight", "bottom")
	
func _on_player_died():
	await get_tree().create_timer(1).timeout
	Events.load_game()

func _on_dialogue_movement(key: String):
	for marker in markers:
		if marker.name == key:
			if key == "player_campfire":
				player.move_to_position_astar(marker.global_position, Vector2.RIGHT)
			elif key == "princess_campfire":
				princess.move_to_position_astar(marker.global_position, Vector2.LEFT)
			elif key == "princess_campfire_finished":
				princess.move_to_position_astar(marker.global_position, Vector2.UP)
			elif key == "THE_prisoner_enter_door_room":
				THE_Prisoner.move_to_position_astar(marker.global_position, Vector2.LEFT)
			else:
				princess.move_to_position_astar(marker.global_position)
			return

func take_pin_1():
	Events.set_flag("pin_1")
	pin1.queue_free()

func take_pin_2():
	Events.set_flag("pin_2")
	pin2.queue_free()
	
func take_pin_3():
	Events.set_flag("pin_3")
	pin3.queue_free()

func _on_save_point_1_dialogue_zone_zone_triggered() -> void:
	save_point_helper(savePoint1.global_position)

func _on_save_point_2_dialogue_zone_zone_triggered() -> void:
	save_point_helper(savePoint2.global_position)
