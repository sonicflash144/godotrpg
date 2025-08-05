extends Node2D

@onready var dialogueRoomManager: DialogueRoomManager = $DialogueRoomManager
@onready var pathfindingManager: PathfindingManager = $PathfindingManager
@onready var player: CharacterBody2D = $Player
@onready var playerHealthComponent: Health_Component = $Player/Health_Component
@onready var princess: CharacterBody2D = $Princess
@onready var princessHealthComponent: Health_Component = $Princess/Health_Component
@onready var princessHurtbox: Hurtbox = $"Princess/Hurtbox"
@onready var playerHitbox: Hitbox = $"Player/HitboxPivot/SwordHitbox"
@onready var dialogueBarrier: DialogueBarrier = $DungeonRoom1/DialogueBarrier

@onready var savePoint = $StartRoom/SavePoint/Marker2D
@onready var CombatRoom2: DungeonRoom = $CombatRoom2
@onready var DoorRoom: DungeonRoom = $DoorRoom

@export var markers: Array[Marker2D]

var last_valid_position: Vector2

func _ready() -> void:
	Events.playerDown = false
	Events.princessDown = true
	Events.playerDead = false
	Events.combat_locked = false
	Events.player_has_sword = true
	Events.num_party_members = 1
	
	Events.room_entered.connect(_on_room_entered)
	Events.room_locked.connect(_on_room_locked)
	Events.player_died.connect(_on_player_died)
	Events.dialogue_movement.connect(_on_dialogue_movement)
	
	set_collision_masks(true)
	princess.set_nav_state()
	
	if not Events.deferred_load_data.is_empty() and Events.deferred_load_data.scene == "dungeon":
		var save_position = Vector2(Events.deferred_load_data["player_x_pos"], Events.deferred_load_data["player_y_pos"])
		player.position = save_position
		
	MusicManager.play_track(MusicManager.Track.DUNGEON)

func _physics_process(_delta: float) -> void:
	last_valid_position = player.global_position

func set_collision_masks(value: bool):
	princessHurtbox.set_collision_mask_value(7, value)
	playerHitbox.set_collision_mask_value(9, value)

func dialogue_barrier(_key: String):
	dialogueRoomManager.nudge_player(last_valid_position)
	if Events.get_flag("met_princess"):
		dialogueRoomManager.dialogue("talked_loop")
	else:
		dialogueRoomManager.dialogue("ignore")

func remove_dialogue_barrier():
	dialogueBarrier.queue_free()

func open_door():
	dialogueRoomManager.dialogue("door_opened")
	
func set_princess_follow_state():
	princess.set_follow_state()
	Events.num_party_members = 2
	
func _on_room_entered(room):
	if room == DoorRoom:
		Events.set_flag("visited_door")

func _on_room_locked(room):
	if room == CombatRoom2 and not Events.get_flag("combat_room_2"):
		dialogueRoomManager.dialogue("ghost_room")
	elif room == DoorRoom and Events.get_flag("princess_door_ready"):
		dialogueRoomManager.dialogue("door")
	
func _on_player_died():
	Events.set_flag("met_princess", false)
	Events.set_flag("hit_princess", false)
	Events.set_flag("combat_room_2", false)
	await get_tree().create_timer(1).timeout
	TransitionHandler.console_fade_out("dungeon")

func _on_dialogue_movement(key: String):
	for marker in markers:
		if marker.name == key:
			princess.move_to_position_astar(marker.global_position)
			return

func _on_princess_hurtbox_area_entered(_area: Area2D) -> void:
	princessHealthComponent.heal(princessHealthComponent.MAX_HEALTH)
	if not Events.get_flag("hit_princess"):
		dialogueRoomManager.dialogue("hit")
	else:
		dialogueRoomManager.dialogue("hit_loop")
		set_collision_masks(false)
		
func _on_princess_dialogue_zone_zone_triggered() -> void:
	if Events.get_flag("visited_door"):
		set_collision_masks(false)
		if Events.get_flag("princess_apology"):
			dialogueRoomManager.dialogue("door_help")
		else:
			dialogueRoomManager.dialogue("fled_visited_door")
	elif Events.get_flag("combat_room_2"):
		if Events.get_flag("princess_apology"):
			dialogueRoomManager.dialogue("fled_loop")
		else:
			dialogueRoomManager.dialogue("fled")
	elif Events.get_flag("met_princess"):
		dialogueRoomManager.dialogue("talked_loop")
	else:
		dialogueRoomManager.dialogue("start")

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
