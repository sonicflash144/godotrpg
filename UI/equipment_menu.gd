extends CanvasLayer

@onready var player: CharacterBody2D = $"../Player"
@onready var princess: CharacterBody2D = $"../Princess"

enum State {
	SELECT_CHARACTER,
	SELECT_SLOT,
	SELECT_ITEM
}
var state: State = State.SELECT_CHARACTER
var current_char_index: int = 0  # 0: Player, 1: Princess
var selected_character: Node
var current_slot_index: int = 0  # 0: Weapon, 1: Armor
var current_item_index: int = 0
var all_equipment: Array[Equipment] = []
var current_items: Array[Equipment] = []
var characters: Array[Node] = []

@onready var description_label: Label = %DescriptionLabel
@onready var equipped_weapon_icon: TextureRect = %WeaponIcon
@onready var equipped_weapon_name: Label = %WeaponNameLabel
@onready var equipped_armor_icon: TextureRect = %ArmorIcon
@onready var equipped_armor_name: Label = %ArmorNameLabel
@onready var attack_label: RichTextLabel = %AttackValueLabel
@onready var defense_label: RichTextLabel = %DefenseValueLabel
@onready var ability_1_label: Label = %Ability1Label
@onready var ability_1_icon: TextureRect = %Ability1Icon
@onready var ability_2_label: Label = %Ability2Label
@onready var ability_2_icon: TextureRect = %Ability2Icon
@onready var inventory_title: Label = %InventoryTitleLabel
@onready var items_vbox: VBoxContainer = %ItemsVBox
@onready var inventory_scroll: ScrollContainer = %InventoryScroll
@onready var pointer: TextureRect = %Pointer

@onready var menuSound: AudioStreamPlayer = $MenuSound
@onready var selectSound: AudioStreamPlayer = $Select
@onready var equipSound: AudioStreamPlayer = $Equip
@onready var disabledSound: AudioStreamPlayer = $Disabled

var sword_icon: Texture = preload("res://UI/sword icon.png")
var bow_icon: Texture = preload("res://UI/bow icon.png")
var armor_icon: Texture = preload("res://UI/armor icon.png")
var ability_icon: Texture = preload("res://UI/ability icon.png")
var sword_disabled_icon: Texture = preload("res://UI/sword disabled icon.png")
var bow_disabled_icon: Texture = preload("res://UI/bow disabled icon.png")

var BackSound = load("res://Music and Sounds/back_sound.tscn")

func _ready() -> void:
	Events.controlsEnabled = false
	selectSound.play()
	characters = [player, princess]
	pointer.visible = true
	load_all_equipment()
	enter_state(State.SELECT_CHARACTER)

func load_all_equipment() -> void:
	var dir = DirAccess.open("res://Equipment/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var equip = load("res://Equipment/" + file_name) as Equipment
				if equip:
					all_equipment.append(equip)
			file_name = dir.get_next()

func enter_state(new_state: State) -> void:
	state = new_state
	match state:
		State.SELECT_CHARACTER:
			selected_character = null
			description_label.text = ""
			clear_inventory_list()
			refresh_equipped()
			update_stats_display()
			populate_inventory_list()
			update_pointer_position()
		State.SELECT_SLOT:
			selected_character = characters[current_char_index]
			refresh_equipped()
			update_stats_display()
			update_description()
			update_pointer_position()
		State.SELECT_ITEM:
			current_item_index = 0
			update_pointer_position()
			populate_inventory_list()
			update_description()
			update_stats_display(true, current_items[current_item_index])

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var backSound = BackSound.instantiate()
		get_tree().current_scene.add_child(backSound)
		match state:
			State.SELECT_CHARACTER:
				Events.menuOpen = false
				Events.enable_controls()
				queue_free()
			State.SELECT_SLOT:
				enter_state(State.SELECT_CHARACTER)
			State.SELECT_ITEM:
				enter_state(State.SELECT_SLOT)
		return

	match state:
		State.SELECT_CHARACTER:
			if event.is_action_pressed("ui_up"):
				var old_index = current_char_index
				current_char_index = max(0, current_char_index - 1)
				if old_index != current_char_index:
					menuSound.play()
				refresh_equipped()
				update_stats_display()
				populate_inventory_list()
				update_pointer_position()
			elif event.is_action_pressed("ui_down"):
				var old_index = current_char_index
				current_char_index = min(1, current_char_index + 1)
				if old_index != current_char_index:
					menuSound.play()
				refresh_equipped()
				update_stats_display()
				populate_inventory_list()
				update_pointer_position()
			elif event.is_action_pressed("ui_accept"):
				selectSound.play()
				current_slot_index = 0
				enter_state(State.SELECT_SLOT)
		State.SELECT_SLOT:
			if event.is_action_pressed("ui_up"):
				var old_index = current_slot_index
				current_slot_index = max(0, current_slot_index - 1)
				if old_index != current_slot_index:
					menuSound.play()
			elif event.is_action_pressed("ui_down"):
				var old_index = current_slot_index
				current_slot_index = min(1, current_slot_index + 1)
				if old_index != current_slot_index:
					menuSound.play()
			elif event.is_action_pressed("ui_accept"):
				selectSound.play()
				enter_state(State.SELECT_ITEM)
			populate_inventory_list()
			update_pointer_position()
			update_description()
		State.SELECT_ITEM:
			if event.is_action_pressed("ui_up"):
				var old_index = current_item_index
				current_item_index = max(0, current_item_index - 1)
				if old_index != current_item_index:
					menuSound.play()
			elif event.is_action_pressed("ui_down"):
				var old_index = current_item_index
				current_item_index = min(current_items.size() - 1, current_item_index + 1)
				if old_index != current_item_index:
					menuSound.play()
			elif event.is_action_pressed("ui_accept"):
				var item_hbox = items_vbox.get_child(current_item_index)
				if not item_hbox.get_meta("disabled", false):
					equipSound.play()
					equip_item(current_items[current_item_index])
					enter_state(State.SELECT_SLOT)
				else:
					disabledSound.play()
			update_pointer_position()
			inventory_scroll.ensure_control_visible(items_vbox.get_child(current_item_index))
			update_description()
			update_stats_display(true, current_items[current_item_index])

func update_pointer_position() -> void:
	await get_tree().create_timer(0.1).timeout
	var pointer_offset = Vector2(-14, 0)
	match state:
		State.SELECT_CHARACTER:
			var char_label = [%PlayerHBox, %PrincessHBox][current_char_index]
			pointer.global_position = char_label.global_position + pointer_offset
		State.SELECT_SLOT:
			var slot_hbox = [%WeaponHBox, %ArmorHBox][current_slot_index]
			pointer.global_position = slot_hbox.global_position + pointer_offset
		State.SELECT_ITEM:
			if items_vbox.get_child_count() > 0 and current_item_index < items_vbox.get_child_count():
				var item_hbox = items_vbox.get_child(current_item_index)
				pointer.global_position = item_hbox.global_position + pointer_offset

func refresh_equipped() -> void:
	var display_char: Node = selected_character if state != State.SELECT_CHARACTER else characters[current_char_index]
	var weapon = display_char.equipment[0] if display_char.equipment.size() > 0 else null
	equipped_weapon_icon.texture = get_icon_for_item(weapon) if weapon else null
	equipped_weapon_name.text = weapon.name if weapon else "(No weapon)"
	
	var armor = display_char.equipment[1] if display_char.equipment.size() > 1 else null
	
	if armor:
		equipped_armor_icon.texture = get_icon_for_item(armor)
		equipped_armor_name.text = armor.name
		equipped_armor_name.add_theme_color_override("font_color", Color.WHITE)
	else:
		equipped_armor_icon.texture = null
		equipped_armor_name.text = "(No armor)"
		equipped_armor_name.add_theme_color_override("font_color", Color("#888888"))

	update_ability_labels()

func get_icon_for_item(item: Equipment) -> Texture:
	if not item:
		return null
	match item.type:
		Equipment.Type.SWORD:
			return sword_icon
		Equipment.Type.BOW:
			return bow_icon
		Equipment.Type.ARMOR:
			return armor_icon
	return null

func populate_inventory_list() -> void:
	var display_char: Node = selected_character if state != State.SELECT_CHARACTER else characters[current_char_index]
	clear_inventory_list()
	var is_weapon_slot = current_slot_index == 0
	inventory_title.text = "WEAPONS" if is_weapon_slot else "ARMORS"

	var equipped_weapon = display_char.equipment[0] if display_char.equipment.size() > 0 else null
	var equipped_armor = display_char.equipment[1] if display_char.equipment.size() > 1 else null

	current_items = all_equipment.filter(func(item: Equipment) -> bool:
		if is_weapon_slot:
			return item.type != Equipment.Type.ARMOR and item != equipped_weapon
		else:
			return item.type == Equipment.Type.ARMOR and item != equipped_armor
	)
	
	for item in current_items:
		var hbox = HBoxContainer.new()
		var icon = TextureRect.new()
		var disabled = false

		if is_weapon_slot:
			if (display_char == player and item.type != Equipment.Type.SWORD) or (display_char == princess and item.type != Equipment.Type.BOW):
				disabled = true
		elif item.name == "------------":
			icon.self_modulate.a = 0.0

		if disabled:
			match item.type:
				Equipment.Type.SWORD: icon.texture = sword_disabled_icon
				Equipment.Type.BOW: icon.texture = bow_disabled_icon
				_: icon.texture = get_icon_for_item(item)
		else:
			icon.texture = get_icon_for_item(item)

		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		hbox.add_child(icon)

		var name_label = Label.new()
		name_label.text = item.name
		if disabled:
			name_label.add_theme_color_override("font_color", Color("#888888"))
		hbox.add_child(name_label)

		hbox.set_meta("disabled", disabled)
		items_vbox.add_child(hbox)

func clear_inventory_list() -> void:
	for child in items_vbox.get_children():
		child.queue_free()
	current_items = []

func update_description() -> void:
	var item: Equipment = null
	match state:
		State.SELECT_SLOT:
			if selected_character.equipment.size() > current_slot_index:
				item = selected_character.equipment[current_slot_index]
		State.SELECT_ITEM:
			if current_items.size() > current_item_index:
				item = current_items[current_item_index]
	description_label.text = item.description if item else ""

func update_stats_display(preview: bool = false, new_item: Equipment = null) -> void:
	var display_char: Node = selected_character if state != State.SELECT_CHARACTER else characters[current_char_index]
	
	var can_equip = true
	# Check if the character can equip the item before showing a preview
	if state == State.SELECT_ITEM and preview and new_item:
		var is_weapon_slot = current_slot_index == 0
		if is_weapon_slot:
			# Check for character-specific weapon restrictions
			if (display_char == player and new_item.type != Equipment.Type.SWORD) or \
			   (display_char == princess and new_item.type != Equipment.Type.BOW):
				can_equip = false

	# Only show the preview if the item is equippable
	if preview and new_item and can_equip:
		var current_item = display_char.equipment[current_slot_index] if display_char.equipment.size() > current_slot_index else null
		var curr_att = current_item.attack if current_item else 0
		var curr_def = current_item.defense if current_item else 0
		var att_diff = new_item.attack - curr_att
		var def_diff = new_item.defense - curr_def
		var new_att = display_char.stats.attack + att_diff
		var new_def = display_char.stats.defense + def_diff
		attack_label.text = format_colored_stat(new_att, att_diff)
		defense_label.text = format_colored_stat(new_def, def_diff)
		update_ability_labels(true, new_item)
	else:
		# If not previewing or if the item is unequippable, show current stats
		attack_label.text = str(display_char.stats.attack)
		defense_label.text = str(display_char.stats.defense)
		update_ability_labels()
		
func format_colored_stat(stat: int, diff: int) -> String:
	var full_text = str(stat)
	if diff != 0:
		full_text += " (" + (("+" if diff > 0 else "") + str(diff)) + ")"
	
	if diff > 0:
		return "[color=yellow]" + full_text + "[/color]"
	elif diff < 0:
		return "[color=red]" + full_text + "[/color]"
	else:
		return full_text

func update_ability_labels(preview: bool = false, new_item: Equipment = null) -> void:
	var display_char: Node = selected_character if state != State.SELECT_CHARACTER else characters[current_char_index]
	var no_ability_text = "(No ability)"
	var grey_color = Color("#888888")

	var weapon = display_char.equipment[0] if display_char.equipment.size() > 0 else null
	var armor = display_char.equipment[1] if display_char.equipment.size() > 1 else null

	var weapon_ability = ""
	if weapon and weapon.ability != "":
		weapon_ability = weapon.ability
		ability_1_icon.self_modulate.a = 1
	else:
		weapon_ability = no_ability_text
		ability_1_icon.self_modulate.a = 0

	var armor_ability = ""
	if armor and armor.ability != "":
		armor_ability = armor.ability
		ability_2_icon.self_modulate.a = 1
	else:
		armor_ability = no_ability_text
		ability_2_icon.self_modulate.a = 0

	ability_1_label.text = weapon_ability
	ability_2_label.text = armor_ability
	
	ability_1_label.add_theme_color_override("font_color", grey_color if weapon_ability == no_ability_text else Color.WHITE)
	ability_2_label.add_theme_color_override("font_color", grey_color if armor_ability == no_ability_text else Color.WHITE)

	if preview and new_item:
		var new_ability = new_item.ability if new_item and new_item.ability != "" else no_ability_text
		
		if current_slot_index == 0:
			if new_ability != weapon_ability:
				ability_1_label.text = new_ability
				if new_ability == no_ability_text:
					ability_1_icon.self_modulate.a = 0.0
					ability_1_label.add_theme_color_override("font_color", Color.RED)
				else:
					ability_1_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			if new_ability != armor_ability:
				ability_2_label.text = new_ability
				if new_ability == no_ability_text:
					ability_1_icon.self_modulate.a = 0.0
					ability_2_label.add_theme_color_override("font_color", Color.RED)
				else:
					ability_2_label.add_theme_color_override("font_color", Color.YELLOW)

func equip_item(new_item: Equipment) -> void:
	var slot_idx = current_slot_index

	var item_exists = selected_character.equipment.size() > slot_idx

	if new_item.name == "------------":
		if item_exists:
			selected_character.equipment.remove_at(slot_idx)
	else:
		if item_exists:
			selected_character.equipment[slot_idx] = new_item
		else:
			while selected_character.equipment.size() < slot_idx:
				selected_character.equipment.append(null)
			selected_character.equipment.append(new_item)
	
	selected_character.update_stats()
	refresh_equipped()
	update_stats_display()
