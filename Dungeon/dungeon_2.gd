extends Node2D

@onready var dialogueRoomManager: DialogueRoomManager = $DialogueRoomManager
@onready var pathfindingManager: PathfindingManager = $PathfindingManager
@onready var player: CharacterBody2D = $Player
@onready var princess: CharacterBody2D = $Princess
@onready var playerHealthComponent: Health_Component = $Player/Health_Component
@onready var princessHealthComponent: Health_Component = $Princess/Health_Component
@onready var CampfireRoom: DungeonRoom = $CampfireRoom
@onready var PuzzleRoom: DungeonRoom = $PuzzleRoom
@onready var ThePrisonerRoom: DungeonRoom = $ThePrisonerRoom
@onready var goBackdialogueBarrier: DialogueBarrier = $"StartRoom/GoBackDialogueBarrier"
@onready var shopkeeperDialogueBarrier: DialogueBarrier = $"ShopkeeperRoom/ShopkeeperDialogueBarrier"
@onready var sideDoor = $"PuzzleRoom/SideDoor"
@onready var princessFollowCheck = $"PuzzleRoom/PrincessFollowCheck"
@onready var afterLasersDialogueBarrierCollisionShape = $ThePrisonerRoom/DialogueBarrier/CollisionShape2D
@onready var savePoint = $CampfireRoom/SavePoint/Marker2D

@export var markers: Array[Marker2D]

var last_valid_position: Vector2
var ironSword: Equipment = load("res://Equipment/Iron Sword.tres")
var overpricedArmor: Equipment = load("res://Equipment/Overpriced Armor.tres")
var DoorSound = load("res://Music and Sounds/door_sound.tscn")

func _ready() -> void:
	if not Events.deferred_load_data.is_empty() and Events.deferred_load_data.scene == "dungeon_2":
		var save_position = Vector2(Events.deferred_load_data["player_x_pos"], Events.deferred_load_data["player_y_pos"])
		player.position = save_position
		princess.position = save_position
	elif Events.player_transition == "up":
		player.global_position = goBackdialogueBarrier.global_position + Vector2(0, -16)
		player.movement_component.update_animation_direction(Vector2.UP)
	
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
	
	await get_tree().process_frame
	if Events.get_flag("met_shopkeeper"):
		remove_shopkeeper_dialogue_barrier()
	if Events.get_flag("puzzle_completed"):
		sideDoor.queue_free()
	if Events.get_flag("met_THE_prisoner"):
		afterLasersDialogueBarrierCollisionShape.set_deferred("disabled", false)
	
func _physics_process(_delta: float) -> void:
	last_valid_position = player.global_position
	
func dialogue_barrier(key: String):
	if key == "princess_follow_check":
		if not sideDoor:
			princess.set_follow_state()
			princessFollowCheck.queue_free()
	else:
		dialogueRoomManager.nudge_player(last_valid_position)
		dialogueRoomManager.dialogue(key)

func campfire_finished():
	player.set_move_state()
	princess.set_follow_state()

func remove_shopkeeper_dialogue_barrier():
	shopkeeperDialogueBarrier.queue_free()

func _on_room_locked(room):
	if room == CampfireRoom and not Events.get_flag("campfire_completed"):
		player.set_nav_state()
		princess.set_nav_state()
		dialogueRoomManager.dialogue("campfire")
	elif room == PuzzleRoom and not Events.get_flag("puzzle_completed"):
		if Events.debug_autocomplete:
			var puzzle = room.get_node_or_null("BoxPuzzle")
			puzzle.is_puzzle_complete = true
			_on_box_puzzle_puzzle_complete()
			return
			
		princess.set_nav_state()
		if not Events.get_flag("puzzle_started"):
			dialogueRoomManager.dialogue("enter_puzzle_room")
		else:
			_on_dialogue_movement("enter_puzzle_room")
	elif room == ThePrisonerRoom and not Events.get_flag("met_THE_prisoner"):
		dialogueRoomManager.dialogue("THE_prisoner_intro")
		afterLasersDialogueBarrierCollisionShape.set_deferred("disabled", false)
	
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
			else:
				princess.move_to_position_astar(marker.global_position)
			return

func _on_box_puzzle_puzzle_complete() -> void:
	sideDoor.queue_free()
	var doorSound = DoorSound.instantiate()
	get_tree().current_scene.add_child(doorSound)
	dialogueRoomManager.dialogue("puzzle_complete")

func _on_save_point_dialogue_zone_zone_triggered() -> void:
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
		
	Events.save_game(savePoint.global_position, playerEquipment, princessEquipment, storage)
