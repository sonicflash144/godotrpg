extends Node

@warning_ignore("unused_signal")
signal room_entered(room)
@warning_ignore("unused_signal")
signal room_exited(room)
@warning_ignore("unused_signal")
signal room_locked(room)
@warning_ignore("unused_signal")
signal room_combat_locked(room)
@warning_ignore("unused_signal")
signal room_un_combat_locked(room)

@warning_ignore("unused_signal")
signal player_down(down: bool)
@warning_ignore("unused_signal")
signal princess_down(down: bool)
@warning_ignore("unused_signal")
signal player_died()

@warning_ignore("unused_signal")
signal dialogue_movement(key: String)

signal console_heal()
signal console_autocomplete()
signal console_invincibility()
signal console_give()

const SAVE_PATH = "user://save_data.json"
var GAME_STATE: GameState = preload("res://game_state.tres")
var deferred_load_data: Dictionary = {}
var SaveSound = preload("res://Music and Sounds/save_sound.tscn")

var saved_scene: String
var saved_position: Vector2

var menuOpen := false
var controlsEnabled := true

var player_has_sword := true
var player_transition := ""

var num_party_members := 2
var is_player_controlled := true

var currentRoom: DungeonRoom
var combat_locked := false
var overworld_hazard_active := false

var playerDown := false
var princessDown := false
var playerDead := false

var debug_autocomplete := false

var equipment_abilities: Dictionary[String, bool] = {
	"Piercing": false,
	"Multishot": false,
	"Ice": false,
	"Shockwave": false,
	"Revenge": false,
	"Luck": false,
	"Speed": false
}

func _ready() -> void:
	load_game()
	
	LimboConsole.register_command(set_flag, "set_flag", "Set value for GAME_STATE flag")
	LimboConsole.add_argument_autocomplete_source("set_flag", 0,
			func(): return GAME_STATE.flags.get(get_current_scene_key(), {}).keys()
	)
	LimboConsole.add_argument_autocomplete_source("set_flag", 1,
			func(): return [true, false]
	)
	
	LimboConsole.register_command(heal, "heal", "Heal party to max health")
	LimboConsole.register_command(autocomplete, "auto", "Toggle autocompletion of rooms")
	LimboConsole.register_command(invincibility, "invincibility", "Toggle invincibility")
	LimboConsole.register_command(give, "give", "Add an item to storage")
	LimboConsole.add_argument_autocomplete_source("give", 0,
		func(): return ["Better Bow", "Icy Sword", "Iron Sword", "Lucky Armor", "Multi Bow", "Overpriced Armor", "Piercing Bow", "Revenge Armor", "Shock Sword", "Speedy Armor"]
	)

func save_game(player_position: Vector2, player_equipment: Array[String], princess_equipment: Array[String], storage: Array[String]):
	var saveSound = SaveSound.instantiate()
	get_tree().current_scene.add_child(saveSound)
	
	var save_data = {
		"scene": get_current_scene_key(),
		"player_x_pos": player_position.x,
		"player_y_pos": player_position.y,
		"flags": GAME_STATE.flags.duplicate(true),
		"player_equipment": player_equipment,
		"princess_equipment": princess_equipment,
		"storage": storage
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data, "\t")
		file.store_string(json_string)
		print("Game saved successfully to %s" % file.get_path_absolute())
	else:
		push_error("Error saving game: %s" % FileAccess.get_open_error())

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found.")
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()

		var parse_result = JSON.parse_string(content)
		if parse_result:
			deferred_load_data = parse_result
			Events.GAME_STATE.flags = parse_result.flags.duplicate(true)
			TransitionHandler.console_fade_in(parse_result["scene"])
		else:
			push_error("Error loading game: Save file is corrupted.")
	else:
		push_error("Error loading game: %s" % FileAccess.get_open_error())

func get_current_scene_key():
	var current_scene = get_tree().current_scene
	if current_scene:
		return current_scene.scene_file_path.get_file().get_basename()
	return deferred_load_data["scene"]

func set_flag(flag_name: String, value = true):
	var scene_key = get_current_scene_key()
	GAME_STATE.flags[scene_key][flag_name] = value

func get_flag(flag_name: String, scene_key := ""):
	if not scene_key:
		scene_key = get_current_scene_key()
	return GAME_STATE.flags[scene_key].get(flag_name)

func heal():
	console_heal.emit()
	
func autocomplete():
	console_autocomplete.emit()
	
func invincibility():
	console_invincibility.emit()
	
func give():
	console_give.emit()

func enable_controls():
	await get_tree().create_timer(0.1).timeout
	controlsEnabled = true

func update_equipment_abilities(player_equipment: Array, princess_equipment := []):
	for ability in equipment_abilities:
		equipment_abilities[ability] = false
	
	var all_equipment = player_equipment + princess_equipment
	for item in all_equipment:
		if item.ability:
			equipment_abilities[item.ability] = true

func _unhandled_key_input(event: InputEvent) -> void:
	if currentRoom and event.is_action_pressed("debug_killall"):
		currentRoom.debug_killall()
