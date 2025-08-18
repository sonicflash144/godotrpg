extends Node2D

@onready var dialogueRoomManager: DialogueRoomManager = $DialogueRoomManager
@onready var pathfindingManager: PathfindingManager = $PathfindingManager
@onready var player: CharacterBody2D = $Player
@onready var princess: CharacterBody2D = $Princess
@onready var playerHealthComponent: Health_Component = $Player/Health_Component
@onready var princessHealthComponent: Health_Component = $Princess/Health_Component

@onready var CampfireRoom: DungeonRoom = $CampfireRoom
@onready var savePoint1 = $CampfireRoom/SavePoint1/Marker2D
@onready var goBackdialogueBarrier: DialogueBarrier = $StartRoom/GoBackDialogueBarrier
@onready var shopkeeperDialogueBarrier: DialogueBarrier = $ShopkeeperRoom/ShopkeeperDialogueBarrier
@onready var PuzzleRoom1: DungeonRoom = $PuzzleRoom1
@onready var princessFollowCheck1 = $PuzzleRoom1/PrincessFollowCheck1
@onready var savePoint2 = $SadGuyRoom/SavePoint2/Marker2D
@onready var ThePrisonerRoom: DungeonRoom = $ThePrisonerRoom
@onready var blacksmith = $BlacksmithRoom/Blacksmith
@onready var PuzzleRoom2: DungeonRoom = $PuzzleRoom2
@onready var princessFollowCheck2 = $PuzzleRoom2/PrincessFollowCheck2
@onready var DoorRoom: DungeonRoom = $DoorRoom
@onready var doorRoomDialogueBarrierCollisionShape = $DoorRoom/DoorRoomDialogueBarrier/CollisionShape2D

@export var markers: Array[Marker2D]

var ironSword: Equipment = load("res://Equipment/Iron Sword.tres")
var overpricedArmor: Equipment = load("res://Equipment/Overpriced Armor.tres")
var puzzle_2_started := false

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
	
	if not Events.deferred_load_data.is_empty() and Events.deferred_load_data.scene == "dungeon_2":
		var save_position = Vector2(Events.deferred_load_data["player_x_pos"], Events.deferred_load_data["player_y_pos"])
		player.position = save_position
		princess.position = save_position
	elif Events.player_transition == "up":
		player.global_position = goBackdialogueBarrier.global_position + Vector2(0, -16)
		princess.global_position = goBackdialogueBarrier.global_position + Vector2(0, 16)
		player.movement_component.update_animation_direction(Vector2.UP)
	
	await get_tree().process_frame
	
	if Events.get_flag("met_shopkeeper"):
		remove_shopkeeper_dialogue_barrier()
		
	MusicManager.play_track(MusicManager.Track.DUNGEON)
	
func dialogue_barrier(key: String):
	if key == "princess_follow_check_1":
		if PuzzleRoom1.roomCompleted:
			princess.set_follow_state()
			princessFollowCheck1.queue_free()
	elif key == "princess_follow_check_2":
		if PuzzleRoom2.roomCompleted:
			princess.set_follow_state()
			princessFollowCheck2.queue_free()
	else:
		dialogueRoomManager.nudge_player()
		dialogueRoomManager.dialogue(key)

func save_point_helper(savePosition: Vector2, save_point_name: String):
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
		
	Events.save_game(savePosition, playerEquipment, princessEquipment, storage, save_point_name)

func campfire_finished():
	player.set_move_state()
	princess.set_follow_state()

func remove_shopkeeper_dialogue_barrier():
	shopkeeperDialogueBarrier.queue_free()

func blacksmith_fix_armor():
	var animatedSprite = blacksmith.get_node_or_null("AnimatedSprite2D")
	var hammerSound = blacksmith.get_node_or_null("Hammer")
	animatedSprite.play("Start")
	hammerSound.play()
	overpricedArmor.defense = 4
	player.update_stats()
	princess.update_stats()

func open_door():
	dialogueRoomManager.dialogue("door_opened")

func set_princess_follow_state():
	princess.set_follow_state()

func set_door_room_barrier():
	doorRoomDialogueBarrierCollisionShape.set_deferred("disabled", false)

func _on_room_locked(room):
	if room == CampfireRoom and not Events.get_flag("campfire_completed"):
		dialogueRoomManager.dialogue("campfire")
	elif room == ThePrisonerRoom:
		if not Events.get_flag("met_THE_prisoner"):
			dialogueRoomManager.dialogue("THE_prisoner")
		elif Events.get_flag("met_blacksmith") and not Events.get_flag("THE_prisoner_after_blacksmith"):
			dialogueRoomManager.dialogue("THE_prisoner_after_blacksmith")
	elif room == DoorRoom:
		dialogueRoomManager.dialogue("door")
	
func _on_player_died():
	await get_tree().create_timer(1).timeout
	Events.load_game()

func _on_dialogue_movement(key: String, character := "princess", direction := Vector2.ZERO):
	for marker in markers:
		if marker.name == key:
			if character == "player":
				player.move_to_position_astar(marker.global_position, direction)
			elif character == "princess":
				princess.move_to_position_astar(marker.global_position, direction)
			return

func _on_side_door_dialogue_zone_zone_triggered() -> void:
	if puzzle_2_started:
		dialogueRoomManager.dialogue("side_door")
	else:
		dialogueRoomManager.dialogue("side_door_wrong_side")
	
func _on_save_point_1_dialogue_zone_zone_triggered() -> void:
	save_point_helper(savePoint1.global_position, savePoint1.get_parent().key)

func _on_save_point_2_dialogue_zone_zone_triggered() -> void:
	save_point_helper(savePoint2.global_position, savePoint2.get_parent().key)
