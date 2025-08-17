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
signal console_noclip()

const SAVE_PATH = "user://save_data.json"
var DEFAULT_GAME_STATE: GameState = preload("res://game_state.tres")
var GAME_STATE
var deferred_load_data: Dictionary = {}
var SaveSound = preload("res://Music and Sounds/save_sound.tscn")

var save_timer_secs := 0.0
var total_playtime_secs := 0
var saved_scene: String
var saved_position: Vector2

var currentScene: String = "prison0"

var menuOpen := false
var controlsEnabled := true
var inCutscene := false

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

var THE_prisoner_fight_started := false
var king_fight_started := false

var debug_autocomplete := false

var playerEquipment: Array[Equipment]
var princessEquipment: Array[Equipment]
var storage: Array[Equipment]

var equipment_abilities: Dictionary[String, bool] = {
	"Multishot": false,
	"Ice": false,
	"Revenge": false,
	"Luck": false,
	"Speed": false
}

func _ready() -> void:
	GAME_STATE = DEFAULT_GAME_STATE.duplicate()
	
	LimboConsole.register_command(set_flag, "set_flag", "Set value for GAME_STATE flag")
	LimboConsole.add_argument_autocomplete_source("set_flag", 0,
			func(): return GAME_STATE.flags.get(currentScene, {}).keys()
	)
	LimboConsole.add_argument_autocomplete_source("set_flag", 1,
			func(): return [true, false]
	)
	
	LimboConsole.register_command(heal, "heal", "Heal party to max health")
	LimboConsole.register_command(autocomplete, "auto", "Toggle autocompletion of rooms")
	LimboConsole.register_command(invincibility, "invincibility", "Toggle invincibility")
	LimboConsole.register_command(give, "give", "Add an item to storage")
	LimboConsole.register_command(noclip, "noclip", "Toggle noclip")
	LimboConsole.add_argument_autocomplete_source("give", 0,
		func(): return ["Better Bow", "Icy Sword", "Iron Sword", "Lucky Armor", "Multi Bow", "Overpriced Armor", "Revenge Armor", "Speedy Armor"]
	)

func _physics_process(delta: float) -> void:
	if not get_tree().paused:
		save_timer_secs += delta

func parse_timer_to_secs(text: String) -> int:
	# Supports "H:MM:SS" or "M:SS"
	var parts := text.split(":")
	if parts.size() == 3:
		return int(parts[0]) * 3600 + int(parts[1]) * 60 + int(parts[2])
	elif parts.size() == 2:
		return int(parts[0]) * 60 + int(parts[1])
	return 0

func format_elapsed_from_secs(total_secs: int) -> String:
	@warning_ignore("integer_division")
	var h := total_secs / 3600
	@warning_ignore("integer_division")
	var m := (total_secs % 3600) / 60
	var s := total_secs % 60
	var s_str := str(s).pad_zeros(2)
	if h > 0:
		# H:MM:SS (no leading zero on hours)
		return "%d:%02d:%s" % [h, m, s_str]
	# M:SS (no leading zero on minutes)
	return "%d:%s" % [m, s_str]

func save_game(player_position: Vector2, player_equipment: Array[String], princess_equipment: Array[String], saved_storage: Array[String], save_point_name: String):
	var saveSound = SaveSound.instantiate()
	get_tree().current_scene.add_child(saveSound)
	
	total_playtime_secs += int(floor(save_timer_secs))
	
	var save_data = {
		"save_point_name": save_point_name,
		"save_file_timer": format_elapsed_from_secs(total_playtime_secs),
		"scene": currentScene,
		"player_x_pos": player_position.x,
		"player_y_pos": player_position.y,
		"flags": GAME_STATE.flags.duplicate(true),
		"player_equipment": player_equipment,
		"princess_equipment": princess_equipment,
		"storage": saved_storage
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data, "\t")
		file.store_string(json_string)
		print("Game saved successfully to %s" % file.get_path_absolute())
	else:
		push_error("Error saving game: %s" % FileAccess.get_open_error())
		
	save_timer_secs = 0.0

func load_save_data():
	if not FileAccess.file_exists(SAVE_PATH):
		deferred_load_data.clear()
		GAME_STATE = DEFAULT_GAME_STATE.duplicate()
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()

		var parse_result = JSON.parse_string(content)
		if parse_result:
			deferred_load_data = parse_result
			GAME_STATE.flags = deferred_load_data.flags.duplicate(true)
			if parse_result.has("save_file_timer"):
				total_playtime_secs = parse_timer_to_secs(str(parse_result.get("save_file_timer", "0:00")))
			return parse_result
		else:
			push_error("Error loading game: Save file is corrupted.")
	else:
		push_error("Error loading game: %s" % FileAccess.get_open_error())

func load_game():
	var parse_result = load_save_data()
	if parse_result:
		TransitionHandler.console_fade_out(parse_result["scene"])
	else:
		TransitionHandler.console_fade_out(currentScene)

func store_equipment(player_equipment: Array[Equipment], princess_equipment: Array[Equipment], saved_storage: Array[Equipment]):
	playerEquipment = player_equipment.duplicate()
	princessEquipment = princess_equipment.duplicate()
	storage = saved_storage.duplicate()

func set_flag(flag_name: String, value = true):
	GAME_STATE.flags[currentScene][flag_name] = value

func get_flag(flag_name: String, scene_name := ""):
	if not scene_name:
		scene_name = currentScene
	return GAME_STATE.flags[scene_name].get(flag_name, false)

func heal():
	console_heal.emit()
	
func autocomplete():
	console_autocomplete.emit()
	
func invincibility():
	console_invincibility.emit()
	
func give(item_name: String):
	console_give.emit(item_name)

func noclip():
	console_noclip.emit()

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
