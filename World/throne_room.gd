extends Node2D

@onready var dialogueRoomManager: DialogueRoomManager = $DialogueRoomManager
@onready var combatManager = $CombatManager
@onready var player: CharacterBody2D = $Player
@onready var king: CharacterBody2D = $King

@export var markers: Array[Marker2D]

func _ready() -> void:	
	start_king_fight()
	#await get_tree().create_timer(1).timeout
	#dialogueRoomManager.dialogue("enter_arena")

func start_king_fight():
	Events.combat_locked = true
	Events.emit_signal("room_combat_locked")
	king.set_attack_state()

func game_complete():
	pass
