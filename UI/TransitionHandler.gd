extends Node

var SCREEN: Dictionary = {
	"width": ProjectSettings.get_setting("display/window/size/viewport_width"),
	"height": ProjectSettings.get_setting("display/window/size/viewport_height"),
	"center": Vector2()
}

func _ready() -> void:
	SCREEN.center = Vector2(SCREEN.width / 2, SCREEN.height / 2)
	LimboConsole.register_command(console_reload, "reload", "Reload current save")
	LimboConsole.register_command(console_fade_out, "scene", "Load a new scene")
	LimboConsole.add_argument_autocomplete_source("scene", 0,
		func(): return ["prison0", "prison1", "dungeon", "dungeon_2", "dungeon_3", "throne_room_hall", "throne_room"]
	)

func console_reload():
	Events.load_game()
	LimboConsole.close_console()

func console_fade_in(scene_name: String, duration := 0.8):
	var scene_path = "res://%s.tscn" % scene_name
	if not ResourceLoader.exists(scene_path, "PackedScene"):
		push_error("Scene not found: %s" % scene_path)
		return
	Events.currentScene = scene_name
	fade_in(scene_path, duration)

func console_fade_out(scene_name: String, duration := 0.8):
	var scene_path = "res://%s.tscn" % scene_name
	if not ResourceLoader.exists(scene_path, "PackedScene"):
		push_error("Scene not found: %s" % scene_path)
		return
	Events.currentScene = scene_name
	fade_out(scene_path, duration)
	LimboConsole.close_console()

func fade_out(to, duration := 0.8):
	Events.controlsEnabled = false
	var rootControl = CanvasLayer.new()
	var colorRect = ColorRect.new()
	var tween = get_tree().create_tween()
	rootControl.set_process_mode(PROCESS_MODE_ALWAYS)
	colorRect.color = Color(0, 0, 0, 0)
	
	get_tree().get_root().add_child.call_deferred(rootControl)
	rootControl.add_child(colorRect)
	colorRect.set_size(Vector2(SCREEN.width, SCREEN.height))
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(colorRect, "color", Color.BLACK, duration / 2)
	await tween.finished
	get_tree().current_scene.queue_free()
	
	var new_scene = load(to).instantiate()
	get_tree().get_root().add_child(new_scene)
	
	var tween2 = get_tree().create_tween()
	tween2.set_ease(Tween.EASE_IN_OUT)
	tween2.set_trans(Tween.TRANS_LINEAR)
	tween2.tween_property(colorRect, "color", Color(0, 0, 0, 0), duration / 2)
	
	await tween2.finished
	
	get_tree().set_current_scene(new_scene)
	rootControl.queue_free()
	Events.menuOpen = false
	Events.enable_controls()

func fade_in(to, duration := 0.8):
	Events.controlsEnabled = false
	var rootControl = CanvasLayer.new()
	var colorRect = ColorRect.new()
	rootControl.set_process_mode(PROCESS_MODE_ALWAYS)
	colorRect.color = Color.BLACK
	
	get_tree().get_root().add_child.call_deferred(rootControl)
	rootControl.add_child(colorRect)
	colorRect.set_size(Vector2(SCREEN.width, SCREEN.height))
	
	get_tree().current_scene.queue_free()
	var new_scene = load(to).instantiate()
	get_tree().get_root().add_child.call_deferred(new_scene)
	
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(colorRect, "color", Color(0, 0, 0, 0), duration)
	
	await tween.finished
	
	get_tree().set_current_scene(new_scene)
	rootControl.queue_free()
	Events.menuOpen = false
	Events.enable_controls()
