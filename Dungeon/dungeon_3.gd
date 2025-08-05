extends Node2D

@onready var princessHealthUI: Health_UI = $HealthCanvasLayer/PrincessHealthUI
@onready var dialogueRoomManager: DialogueRoomManager = $DialogueRoomManager
@onready var pathfindingManager: PathfindingManager = $PathfindingManager
@onready var player: CharacterBody2D = $Player
@onready var princess: CharacterBody2D = $Princess
@onready var THE_Prisoner: CharacterBody2D = $ThePrisoner
@onready var playerHealthComponent: Health_Component = $Player/Health_Component
@onready var playerHitbox: Hitbox = $Player/HitboxPivot/SwordHitbox
@onready var princessHealthComponent: Health_Component = $Princess/Health_Component
@onready var princessHurtbox: Hurtbox = $Princess/Hurtbox

@onready var goBackdialogueBarrier: DialogueBarrier = $StartRoom/GoBackDialogueBarrier
@onready var CampfireRoom: DungeonRoom = $CampfireRoom
@onready var savePoint1 = $CampfireRoom/SavePoint1/Marker2D
@onready var pin1 = $LaserRoom1/JugglingPin1
@onready var pin2 = $LaserRoom2/JugglingPin2
@onready var pin3 = $ThePrisonerRoom/JugglingPin3
@onready var ThePrisonerRoom: DungeonRoom = $ThePrisonerRoom
@onready var PuzzleRoom1: DungeonRoom = $PuzzleRoom1
@onready var princessFollowCheck1: DialogueBarrier = $PuzzleRoom1/PrincessFollowCheck1
@onready var savePoint2 = $ChestRoom/SavePoint2/Marker2D
@onready var DoorRoom: DungeonRoom = $DoorRoom
@onready var door = $DoorRoom/Door
@onready var doorDialogueZone = $DoorRoom/Door/DoorDialogueZone/CollisionShape2D
@onready var doorRoomDialogueBarrierCollisionShape = $DoorRoom/DialogueBarrier/CollisionShape2D
@onready var THE_PrisonerMarker = $DoorRoom/THE_prisoner_enter_door_room

@export var markers: Array[Marker2D]

var DeathEffect = preload("res://Effects/death_effect.tscn")
var CombatLockSound = load("res://Music and Sounds/combat_lock_sound.tscn")

var last_valid_position: Vector2
var num_pins_collected := 0

func _ready() -> void:
	Events.playerDown = false
	Events.princessDown = false
	Events.playerDead = false
	Events.combat_locked = false
	Events.player_has_sword = true
	if Events.THE_prisoner_fight_started and Events.num_party_members == 1:
		if princess:
			princess.queue_free()
		princessHealthUI.visible = false
		Events.princessDown = true
	else:
		Events.num_party_members = 2
	Events.is_player_controlled = true
	
	Events.room_locked.connect(_on_room_locked)
	Events.player_died.connect(_on_player_died)
	Events.dialogue_movement.connect(_on_dialogue_movement)
	
	doorDialogueZone.set_deferred("disabled", true)
	
	if not Events.deferred_load_data.is_empty() and Events.deferred_load_data.scene == "dungeon_3":
		var save_position = Vector2(Events.deferred_load_data["player_x_pos"], Events.deferred_load_data["player_y_pos"])
		player.position = save_position
		if princess:
			princess.position = save_position
			
		if Events.THE_prisoner_fight_started:
			THE_Prisoner.global_position = THE_PrisonerMarker.global_position
			THE_Prisoner.set_nav_state()
		elif Events.get_flag("met_THE_prisoner"):
			Events.num_party_members = 3
			THE_Prisoner.position = save_position
			THE_Prisoner.set_follow_state()
	elif Events.player_transition == "up":
		player.global_position = goBackdialogueBarrier.global_position + Vector2(0, -16)
		princess.global_position = goBackdialogueBarrier.global_position + Vector2(0, 16)
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
	
	if princess:
		princess.navigation_component.target_reached.connect(_on_dialogue_movement_finished)
	THE_Prisoner.navigation_component.target_reached.connect(_on_dialogue_movement_finished)
	
	MusicManager.play_track(MusicManager.Track.DUNGEON)
	
func _physics_process(_delta: float) -> void:
	last_valid_position = player.global_position
	
func dialogue_barrier(key: String):
	if key == "princess_follow_check_1":
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

func take_pin_1():
	Events.set_flag("pin_1")
	pin1.queue_free()

func take_pin_2():
	Events.set_flag("pin_2")
	pin2.queue_free()
	
func take_pin_3():
	Events.set_flag("pin_3")
	pin3.queue_free()

func THE_prisoner_join_party():
	Events.num_party_members = 3
	THE_Prisoner.set_follow_state()

func start_the_prisoner_fight():
	if THE_Prisoner.health_component.get_health_percentage() <= 0:
		return
		
	if princess:
		princess.set_follow_state()
	Events.THE_prisoner_fight_started = true
	Events.combat_locked = true
	Events.emit_signal("room_combat_locked")
	var combatLockSound = CombatLockSound.instantiate()
	get_tree().current_scene.add_child(combatLockSound)
	Events.currentRoom.activate_spikes()
	THE_Prisoner.set_attack_state()
	MusicManager.play_track(MusicManager.Track.COMBAT)

func after_the_prisoner_fight():
	Events.set_flag("after_THE_prisoner_fight")
	doorDialogueZone.set_deferred("disabled", false)
	doorRoomDialogueBarrierCollisionShape.set_deferred("disabled", false)
	dialogueRoomManager.dialogue("after_defeat", "bottom", true)
	MusicManager.stop_music()

func kill_princess():
	princessHurtbox.set_collision_mask_value(7, true)
	playerHitbox.set_collision_mask_value(9, true)
	
	_on_dialogue_movement("player_kill_princess", "player", Vector2.LEFT)
	
	await get_tree().create_timer(1).timeout
	Events.inCutscene = true
	
	player.stats.attack += princess.stats.health
	playerHitbox.update_damage()
	player.attack_state()

func princess_death_effect():
	princess.queue_free()
	princessHealthUI.visible = false
	var deathEffect = DeathEffect.instantiate()
	get_tree().current_scene.add_child(deathEffect)
	deathEffect.global_position = princess.global_position
	Events.update_equipment_abilities(player.equipment)

func open_door():
	door.open_door()

func _on_room_locked(room):
	if room == CampfireRoom and not Events.get_flag("campfire_completed"):
		dialogueRoomManager.dialogue("campfire")
	elif room == ThePrisonerRoom and not Events.get_flag("met_THE_prisoner"):
		dialogueRoomManager.dialogue("THE_prisoner")
	elif room == DoorRoom and Events.THE_prisoner_fight_started and not Events.combat_locked:
		start_the_prisoner_fight()
	elif room == DoorRoom and not Events.get_flag("before_THE_prisoner_fight"):
		Events.num_party_members = 2
		dialogueRoomManager.dialogue("before_THE_prisoner_fight", "bottom")
	
func _on_player_died():
	await get_tree().create_timer(1).timeout
	if Events.THE_prisoner_fight_started and Events.deferred_load_data["scene"] == "dungeon_3":
		TransitionHandler.console_fade_out("dungeon_3")
	else:
		Events.load_game()

func _on_dialogue_movement(key: String, character := "princess", direction := Vector2.ZERO, ended_signal := false):
	for marker in markers:
		if marker.name == key:
			var endedSignalKey = key if ended_signal else ""
			if character == "player":
				player.move_to_position_astar(marker.global_position, direction, endedSignalKey)
			elif character == "princess":
				princess.move_to_position_astar(marker.global_position, direction, endedSignalKey)
			elif character == "THE_prisoner":
				THE_Prisoner.move_to_position_astar(marker.global_position, direction, endedSignalKey)
			return

func _on_dialogue_movement_finished(key: String):
	if key == "THE_prisoner_exit_door_room":
		if princess:
			dialogueRoomManager.dialogue(key, "bottom", true)
		else:
			dialogueRoomManager.dialogue(key, "bottom")
	elif key == "princess_open_door":
		dialogueRoomManager.dialogue(key, "bottom")

func _on_save_point_1_dialogue_zone_zone_triggered() -> void:
	save_point_helper(savePoint1.global_position)

func _on_save_point_2_dialogue_zone_zone_triggered() -> void:
	save_point_helper(savePoint2.global_position)
