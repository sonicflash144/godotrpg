extends Node

@onready var menuPlayer = $Menu
@onready var prisonPlayer = $Prison
@onready var tensePlayer = $Tense
@onready var dungeonPlayer = $Dungeon
@onready var princessPlayer = $Princess
@onready var campfirePlayer = $Campfire
@onready var prisonerPlayer = $Prisoner
@onready var prisonerFightPlayer = $PrisonerFight
@onready var hallPlayer = $Hall
@onready var kingPlayer = $King

enum Track {
	MENU,
	PRISON,
	TENSE,
	DUNGEON,
	PRINCESS,
	CAMPFIRE,
	PRISONER,
	PRISONER_FIGHT,
	HALL,
	KING
}

var track_players := {}
var current_track_player: AudioStreamPlayer = null
var dungeon_playback_position := 0.0
var default_volumes := {}

func _ready() -> void:
	track_players = {
		Track.MENU: menuPlayer,
		Track.PRISON: prisonPlayer,
		Track.TENSE: tensePlayer,
		Track.DUNGEON: dungeonPlayer,
		Track.PRINCESS: princessPlayer,
		Track.CAMPFIRE: campfirePlayer,
		Track.PRISONER: prisonerPlayer,
		Track.PRISONER_FIGHT: prisonerFightPlayer,
		Track.HALL: hallPlayer,
		Track.KING: kingPlayer
	}
	
	for player in track_players.values():
		if player:
			default_volumes[player] = player.volume_db

func get_player(track: Track) -> AudioStreamPlayer:
	return track_players.get(track, null)

func set_track(track: Track, fade_sec: float = 0.0) -> void:
	var new_player := get_player(track)
	if not new_player:
		push_error("Track player not found for track: ", track)
		return

	if new_player == current_track_player and new_player.is_playing():
		return

	if current_track_player and current_track_player.is_playing():
		if current_track_player == dungeonPlayer:
			dungeon_playback_position = dungeonPlayer.get_playback_position()

		if fade_sec > 0.0:
			var fade_out := create_tween()
			fade_out.tween_property(current_track_player, "volume_db", -80.0, fade_sec)
			fade_out.tween_callback(current_track_player.stop)
		else:
			current_track_player.stop()

	current_track_player = new_player
	var playback_pos := 0.0
	if current_track_player == dungeonPlayer:
		playback_pos = dungeon_playback_position
		
	var target_volume_db = default_volumes.get(current_track_player, 0.0)

	if fade_sec > 0.0:
		current_track_player.volume_db = -80.0
		current_track_player.play(playback_pos)
		
		var fade_in := create_tween()
		fade_in.tween_property(current_track_player, "volume_db", target_volume_db, fade_sec)
	else:
		current_track_player.volume_db = target_volume_db
		current_track_player.play(playback_pos)

func play_track(track_to_play: Track) -> void:
	set_track(track_to_play, 0.0)

func crossfade_track(new_track: Track, fade_duration := 1.0) -> void:
	set_track(new_track, fade_duration)

func stop_music() -> void:
	if current_track_player and current_track_player.is_playing():
		if current_track_player == dungeonPlayer:
			dungeon_playback_position = dungeonPlayer.get_playback_position()
		current_track_player.stop()
	current_track_player = null
