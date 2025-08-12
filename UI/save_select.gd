extends Control

enum { 
	SELECT, 
	CONFIRM_ERASE,
	LOAD_GAME
}

@onready var saveFileVBox = %SaveFileVBoxContainer
@onready var locationLabel = %LocationLabel
@onready var timeLabel = %TimeLabel
@onready var playLabel = %PlayLabel
@onready var eraseLabel = %EraseLabel
@onready var pointer = %Pointer

@onready var menuSound: AudioStreamPlayer = $MenuSound
@onready var selectSound: AudioStreamPlayer = $Select
@onready var disabledSound: AudioStreamPlayer = $Disabled
@onready var eraseSound: AudioStreamPlayer = $Erase

const DISABLED_COLOR := Color("888888")
var BackSound = load("res://Music and Sounds/back_sound.tscn")

var current_state = SELECT
var selection_index := 0
var has_save_file := false

var current_options: Array[Label] = []
var confirmation_nodes: Array[Node] = []

func _ready() -> void:
	Events.load_save_data()
	current_options = [playLabel, eraseLabel]
	
	if Events.deferred_load_data.is_empty():
		update_empty_save_labels()
	else:
		has_save_file = true
		locationLabel.text = Events.deferred_load_data["save_point_name"]
		timeLabel.text = Events.deferred_load_data["save_file_timer"]
	
	call_deferred("update_pointer_position")

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	match current_state:
		SELECT:
			handle_select_input(event)
		CONFIRM_ERASE:
			handle_confirm_erase_input(event)

func update_empty_save_labels():
	eraseLabel.modulate = DISABLED_COLOR
	locationLabel.text = "------------"
	timeLabel.text = "--:--"
	playLabel.text = "Start"
	
func handle_select_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right") and selection_index < current_options.size() - 1:
		selection_index += 1
		menuSound.play()
		update_pointer_position()
			
	elif event.is_action_pressed("ui_left") and selection_index > 0:
		selection_index -= 1
		menuSound.play()
		update_pointer_position()
			
	elif event.is_action_pressed("ui_accept"):
		selectSound.play()
		if selection_index == 0: # Corresponds to "Play"
			current_state = LOAD_GAME
			Events.load_game()
			Events.save_timer_secs = 0.0
		elif selection_index == 1: # Corresponds to "Erase"
			if not has_save_file:
				disabledSound.play()
				return
			else:
				show_erase_confirmation()

func handle_confirm_erase_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"):
		if selection_index < current_options.size() - 1:
			selection_index += 1
			menuSound.play()
			update_pointer_position()
			
	elif event.is_action_pressed("ui_left"):
		if selection_index > 0:
			selection_index -= 1
			menuSound.play()
			update_pointer_position()
			
	elif event.is_action_pressed("ui_accept"):
		selectSound.play()
		if selection_index == 0: # "Yes"
			erase_save_file()
			current_state = SELECT
			selection_index = 0
			hide_erase_confirmation()
		elif selection_index == 1: # "No"
			current_state = SELECT
			selection_index = 1
			hide_erase_confirmation()
			
	elif event.is_action_pressed("ui_cancel"):
		var backSound = BackSound.instantiate()
		add_child(backSound)
		current_state = SELECT
		selection_index = 1
		hide_erase_confirmation()

func update_pointer_position() -> void:
	if current_options.is_empty() or not is_instance_valid(current_options[selection_index]):
		return
	
	var pointer_offset = Vector2(-14, 0)
	var selected_label = current_options[selection_index]
	pointer.global_position = selected_label.global_position + pointer_offset

func show_erase_confirmation() -> void:
	current_state = CONFIRM_ERASE
	selection_index = 0
	for child in saveFileVBox.get_children():
		child.visible = false

	var prompt_label = Label.new()
	prompt_label.text = "Really erase this file?"
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var yes_label = Label.new()
	yes_label.text = "Yes"
	yes_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var no_label = Label.new()
	no_label.text = "No"
	no_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	hbox.add_child(yes_label)
	hbox.add_child(no_label)
	
	saveFileVBox.add_child(prompt_label)
	saveFileVBox.add_child(hbox)
	
	confirmation_nodes = [prompt_label, hbox]
	current_options = [yes_label, no_label]

	call_deferred("update_pointer_position")

func hide_erase_confirmation() -> void:
	for child in saveFileVBox.get_children():
		child.visible = true
	
	for node in confirmation_nodes:
		node.queue_free()
	confirmation_nodes.clear()
	
	current_options = [playLabel, eraseLabel]
	
	await get_tree().process_frame
	update_pointer_position()

func erase_save_file() -> void:
	eraseSound.play()
	var err = DirAccess.remove_absolute(Events.SAVE_PATH)
	if err == OK:
		has_save_file = false
		update_empty_save_labels()
		print("Save file erased.")
	else:
		push_error("Error erasing save file.")
