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

# Dialogue
var controlsEnabled := true
var player_has_sword := true
var player_transition := ""

var prison_dialogue_value := ""
var princess_dialogue_value := ""

# Combat
var num_party_members := 2
var is_player_controlled := true

var playerDown := false
var princessDown := false
var playerDead := false

# Equipment
var piercing := false
var multishot := false
var sword_slow := false
var sword_shockwave := true

# World
var prisonDoorOpened := false
