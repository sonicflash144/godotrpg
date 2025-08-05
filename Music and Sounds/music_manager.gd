extends Node

@onready var dungeonPlayer: AudioStreamPlayer = $Dungeon
@onready var combatPlayer: AudioStreamPlayer = $Combat
@onready var hallPlayer: AudioStreamPlayer = $Hall

enum Track {
	DUNGEON,
	COMBAT,
	HALL
}

var current_track_player = null
var dungeon_playback_position: float = 0.0

# This function plays a specified track.
func play_track(track_to_play: Track):
	var new_track_player

	match track_to_play:
		Track.DUNGEON:
			new_track_player = dungeonPlayer
		Track.COMBAT:
			new_track_player = combatPlayer
		Track.HALL:
			new_track_player = hallPlayer

	# If the requested track is already playing, do nothing.
	if new_track_player == current_track_player and new_track_player.is_playing():
		return

	# If a track is currently playing, store its position if it's the dungeon track.
	if current_track_player and current_track_player.is_playing():
		if current_track_player == dungeonPlayer:
			dungeon_playback_position = dungeonPlayer.get_playback_position()
		current_track_player.stop()

	# Play the new track
	current_track_player = new_track_player
	
	if current_track_player == dungeonPlayer:
		current_track_player.play(dungeon_playback_position)
	else:
		current_track_player.play() # Play from the beginning

# This function stops all music.
func stop_music():
	if current_track_player and current_track_player.is_playing():
		if current_track_player == dungeonPlayer:
			dungeon_playback_position = dungeonPlayer.get_playback_position()
		current_track_player.stop()
	current_track_player = null

# This function crossfades between tracks.
func switch_track_with_fade(new_track: Track, fade_duration: float = 1.0):
	var new_player
	match new_track:
		Track.DUNGEON:
			new_player = dungeonPlayer
		Track.COMBAT:
			new_player = combatPlayer
		Track.HALL:
			new_player = hallPlayer

	if new_player == current_track_player and new_player.is_playing():
		return

	# Fade out the current track if one is playing
	if current_track_player and current_track_player.is_playing():
		if current_track_player == dungeonPlayer:
			dungeon_playback_position = dungeonPlayer.get_playback_position()
			
		var fade_out_tween = create_tween()
		fade_out_tween.tween_property(current_track_player, "volume_db", -80.0, fade_duration)
		fade_out_tween.tween_callback(current_track_player.stop)

	# Fade in the new track
	current_track_player = new_player
	current_track_player.volume_db = -80.0
	
	if current_track_player == dungeonPlayer:
		current_track_player.play(dungeon_playback_position)
	else:
		current_track_player.play() # Play from the beginning
		
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(current_track_player, "volume_db", 0.0, fade_duration)
