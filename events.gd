extends Node

@warning_ignore("unused_signal")
signal player_died()

@warning_ignore("unused_signal")
signal room_entered(room)
@warning_ignore("unused_signal")
signal room_locked(room)
@warning_ignore("unused_signal")
signal room_combat_locked(room)
@warning_ignore("unused_signal")
signal room_un_combat_locked(room)

@warning_ignore("unused_signal")
signal dialogue_movement(key: String)

func enable_controls():
	await get_tree().create_timer(0.1).timeout
	controlsEnabled = true

# Dialogue
var menuOpen := false
var controlsEnabled := true
var player_has_sword := true
var player_transition := ""

var prison_dialogue_value := ""
var princess_dialogue_value := ""
var dungeon_2_dialogue_value := ""

# Combat
var num_party_members := 2
var is_player_controlled := true

var playerDown := false
var princessDown := false
var playerDead := false

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

# World
var prisonDoorOpened := false
