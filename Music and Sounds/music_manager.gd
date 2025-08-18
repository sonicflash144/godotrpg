extends Node

@onready var menuPlayer = $Menu
@onready var prisonPlayer = $Prison
@onready var tensePlayer = $Tense
@onready var dungeonPlayer = $Dungeon
@onready var combatPlayer = $Combat
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
	COMBAT,
	PRINCESS,
	CAMPFIRE,
	PRISONER,
	PRISONER_FIGHT,
	HALL,
	KING
}

var track_players := {}
var current_track_player: AudioStreamPlayer = null
var dungeon_music_started := false
var default_volumes := {}

func _ready() -> void:
	track_players = {
		Track.MENU: menuPlayer,
		Track.PRISON: prisonPlayer,
		Track.TENSE: tensePlayer,
		Track.DUNGEON: dungeonPlayer,
		Track.COMBAT: combatPlayer,
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
	
	# If the new track is the same as the current one and it's actively playing, do nothing.
	if new_player == current_track_player and new_player.is_playing() and not new_player.get_stream_paused():
		return
	
	# Fade out and pause/stop the current track
	if current_track_player and current_track_player.is_playing():
		if current_track_player == dungeonPlayer:
			# For the dungeon track, we pause it instead of stopping it.
			if fade_sec > 0.0:
				var fade_out := create_tween()
				fade_out.tween_property(current_track_player, "volume_db", -80.0, fade_sec)
				fade_out.tween_callback(current_track_player.set_stream_paused.bind(true))
			else:
				current_track_player.set_stream_paused(true)
		else:
			# For all other tracks, we stop them completely.
			if fade_sec > 0.0:
				var fade_out := create_tween()
				fade_out.tween_property(current_track_player, "volume_db", -80.0, fade_sec)
				fade_out.tween_callback(current_track_player.stop)
			else:
				current_track_player.stop()

	current_track_player = new_player
	var target_volume_db = default_volumes.get(current_track_player, 0.0)

	# Start or resume the new track
	var should_resume = current_track_player == dungeonPlayer and dungeon_music_started

	if fade_sec > 0.0:
		current_track_player.volume_db = -80.0
		
		if should_resume:
			current_track_player.set_stream_paused(false)
		else:
			current_track_player.play()
		
		var fade_in := create_tween()
		fade_in.tween_property(current_track_player, "volume_db", target_volume_db, fade_sec)
		
	else:
		current_track_player.volume_db = target_volume_db
		if should_resume:
			current_track_player.set_stream_paused(false)
		else:
			current_track_player.play()
			
	if current_track_player == dungeonPlayer:
		dungeon_music_started = true

func play_track(track_to_play: Track) -> void:
	set_track(track_to_play, 0.0)

func crossfade_track(new_track: Track, fade_duration := 1.0) -> void:
	set_track(new_track, fade_duration)

func stop_music() -> void:
	if current_track_player == dungeonPlayer:
		current_track_player.set_stream_paused(true)
	else:
		current_track_player.stop()
		
	current_track_player = null
