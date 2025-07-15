extends Node

@warning_ignore("unused_signal")
signal room_entered(room)
@warning_ignore("unused_signal")
signal room_locked(room)
@warning_ignore("unused_signal")
signal room_exited(room)
@warning_ignore("unused_signal")
signal dialogue_movement(key: String)

var playerDead: bool = false
var controlsEnabled: bool = true
var player_has_sword: bool = true
var player_transition: String = ""

var prisonDoorOpened: bool = false

var prison_dialogue_value: String = ""
var princess_dialogue_value: String = ""
