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

var num_party_members: int = 2
var is_player_controlled: bool = true

var playerDown: bool = false
var princessDown: bool = false
var playerDead: bool = false

var controlsEnabled: bool = true
var player_has_sword: bool = true
var player_transition: String = ""

var prisonDoorOpened: bool = false

var prison_dialogue_value: String = ""
var princess_dialogue_value: String = ""
