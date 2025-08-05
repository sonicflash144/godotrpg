extends Node2D

@onready var dialogueRoomManager: DialogueRoomManager = $DialogueRoomManager
@onready var combatManager = $CombatManager
@onready var player: CharacterBody2D = $Player
@onready var princess: CharacterBody2D = $Princess
@onready var princessHealthUI: Health_UI = $HealthCanvasLayer/PrincessHealthUI
@onready var king: CharacterBody2D = $King

@export var markers: Array[Marker2D]

func _ready() -> void:	
	Events.player_died.connect(_on_player_died)
	player.movement_component.update_animation_direction(Vector2.UP)
	if Events.num_party_members == 1:
		if princess:
			princess.queue_free()
		princessHealthUI.visible = false
		Events.princessDown = true
		
	if Events.king_fight_started:
		if not Events.combat_locked:
			start_king_fight()
	else:
		await get_tree().create_timer(0.8).timeout
		dialogueRoomManager.dialogue("enter_arena")
	
func start_king_fight():
	if king.health_component.get_health_percentage() <= 0:
		return
		
	Events.king_fight_started = true
	Events.combat_locked = true
	Events.emit_signal("room_combat_locked")
	king.set_attack_state()
	MusicManager.play_track(MusicManager.Track.COMBAT)

func after_king_fight():
	dialogueRoomManager.dialogue("after_defeat")
	MusicManager.stop_music()

func game_complete():
	TransitionHandler.console_fade_out("game_complete", 2.0)

func _on_player_died():
	await get_tree().create_timer(1).timeout
	TransitionHandler.console_fade_out("throne_room_hall")
	if princess:
		Events.store_equipment(player.equipment, princess.equipment, player.storage)
	else:
		Events.store_equipment(player.equipment, [], player.storage)
