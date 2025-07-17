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

var prison_dialogue_value := ""
var princess_dialogue_value := ""

var num_party_members := 2
var is_player_controlled := true

var playerDown := false
var princessDown := false
var playerDead := false

var controlsEnabled := true
var player_has_sword := true
var player_transition := ""

var prisonDoorOpened := false
