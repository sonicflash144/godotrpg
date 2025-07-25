extends Node

var GAME_STATE: GameState = preload("res://game_state.tres")

func set_flag(flag_name: String, value):
	if GAME_STATE:
		GAME_STATE.flags[flag_name] = value

func get_flag(flag_name: String):
	if GAME_STATE:
		return GAME_STATE.flags.get(flag_name)

# Combat
var num_party_members := 2
var is_player_controlled := true

@warning_ignore("unused_signal")
signal player_down(down: bool)
@warning_ignore("unused_signal")
signal princess_down(down: bool)
@warning_ignore("unused_signal")
signal player_died()

var playerDown := false
var princessDown := false
var playerDead := false

# Dungeon Rooms
@warning_ignore("unused_signal")
signal room_entered(room)
@warning_ignore("unused_signal")
signal room_exited(room)
@warning_ignore("unused_signal")
signal room_locked(room)
@warning_ignore("unused_signal")
signal room_combat_locked(room)
@warning_ignore("unused_signal")
signal room_un_combat_locked(room)

# Dialogue
@warning_ignore("unused_signal")
signal dialogue_movement(key: String)

var princess_dialogue_value := ""

var menuOpen := false
var controlsEnabled := true

func enable_controls():
	await get_tree().create_timer(0.1).timeout
	controlsEnabled = true

# Equipment
var equipment_abilities: Dictionary[String, bool] = {
	"Piercing": false,
	"Multishot": false,
	"Ice": false,
	"Shockwave": false,
	"Revenge": false,
	"Luck": false,
	"Speed": false
}

func update_equipment_abilities(player_equipment: Array, princess_equipment := []):
	for ability in equipment_abilities:
		equipment_abilities[ability] = false
	
	var all_equipment = player_equipment + princess_equipment
	for item in all_equipment:
		if item.ability:
			equipment_abilities[item.ability] = true

# World State
var player_has_sword := true
var player_transition := ""
