extends Control

func _ready() -> void:
	MusicManager.play_track(MusicManager.Track.MENU)
