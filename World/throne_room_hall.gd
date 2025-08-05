extends Node2D

@onready var dialogueRoomManager: DialogueRoomManager = $DialogueRoomManager
@onready var player: CharacterBody2D = $Player
@onready var princess: CharacterBody2D = $Princess
@onready var princessHealthUI: Health_UI = $HealthCanvasLayer/PrincessHealthUI
@onready var respawnMarker = $Respawn

func _ready() -> void:
	Events.playerDown = false
	Events.princessDown = false
	Events.playerDead = false
	Events.combat_locked = false
	Events.player_has_sword = true
	Events.is_player_controlled = true
	
	player.movement_component.update_animation_direction(Vector2.UP)
	if Events.num_party_members == 1:
		if princess:
			princess.queue_free()
		princessHealthUI.visible = false
		Events.princessDown = true
		
		if Events.king_fight_started:
			player.global_position = respawnMarker.global_position
	else:
		if Events.king_fight_started:
			player.global_position = respawnMarker.global_position
			princess.global_position = respawnMarker.global_position
		else:
			await get_tree().create_timer(0.8).timeout
			dialogueRoomManager.dialogue("enter_hall")
			
	MusicManager.play_track(MusicManager.Track.HALL)
	
func _on_transition_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		TransitionHandler.console_fade_out("throne_room")
		Events.player_transition = "up"
	if princess:
		Events.store_equipment(player.equipment, princess.equipment, player.storage)
	else:
		Events.store_equipment(player.equipment, [], player.storage)
