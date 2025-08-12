extends CanvasLayer

@onready var player: CharacterBody2D = $"../Player"
@onready var princess: CharacterBody2D = get_node_or_null("../Princess")
@onready var player_hbox: HBoxContainer = %PlayerHBox
@onready var princess_hbox: HBoxContainer = %PrincessHBox
@onready var weapon_hbox: HBoxContainer = %WeaponHBox
@onready var armor_hbox: HBoxContainer = %ArmorHBox
@onready var description_label: Label = %DescriptionLabel
@onready var player_icon: TextureRect = %PlayerIcon
@onready var princess_icon: TextureRect = %PrincessIcon
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

enum {
	SELECT_CHARACTER,
	SELECT_SLOT,
	SELECT_ITEM
}
const DISABLED_COLOR := Color("#888888")
var onLoad := true
var state = SELECT_CHARACTER
var current_char_index: int = 0  # 0: Player, 1: Princess
var selected_character: Node
var current_slot_index: int = 0  # 0: Weapon, 1: Armor
var current_item_index: int = 0
var all_equipment: Array[Equipment] = []
var current_items: Array[Equipment] = []
var characters: Array[Node] = []
var character_hboxes: Array[HBoxContainer] = []

const SLOT_TYPES: Array[Equipment.Type] = [Equipment.Type.SWORD, Equipment.Type.BOW, Equipment.Type.ARMOR]  # But weapons are character-specific
const ICON_MAP: Dictionary = {
	Equipment.Type.SWORD: { "normal": preload("res://UI/Sprites/sword icon.png"), "disabled": preload("res://UI/Sprites/sword disabled icon.png") },
	Equipment.Type.BOW: { "normal": preload("res://UI/Sprites/bow icon.png"), "disabled": preload("res://UI/Sprites/bow disabled icon.png") },
	Equipment.Type.ARMOR: { "normal": preload("res://UI/Sprites/armor icon.png"), "disabled": null }
}
const ABILITY_ICON: Texture = preload("res://UI/Sprites/ability icon.png")

var slot_hboxes: Array[HBoxContainer]
var slot_icons: Array[TextureRect]
var slot_names: Array[Label]
var ability_labels: Array[Label]
var ability_icons: Array[TextureRect]

var BackSound = load("res://Music and Sounds/back_sound.tscn")
var unequip_armor_resource = load("res://Equipment/unequip_armor.tres")

func _ready() -> void:
	Events.controlsEnabled = false
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	selectSound.play()
	if Events.num_party_members > 1 and not Events.princessDown:
		characters = [player, princess]
		character_hboxes = [player_hbox, princess_hbox]
		princess_hbox.visible = true
	else:
		characters = [player]
		character_hboxes = [player_hbox]
		princess_hbox.visible = false

	slot_hboxes = [weapon_hbox, armor_hbox]
	slot_icons = [equipped_weapon_icon, equipped_armor_icon]
	slot_names = [equipped_weapon_name, equipped_armor_name]
	ability_labels = [ability_1_label, ability_2_label]
	ability_icons = [ability_1_icon, ability_2_icon]
	all_equipment = player.storage
	enter_state(SELECT_CHARACTER)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var backSound = BackSound.instantiate()
		get_tree().current_scene.add_child(backSound)
		match state:
			SELECT_CHARACTER:
				Events.menuOpen = false
				Events.enable_controls()
				queue_free()
			SELECT_SLOT:
				enter_state(SELECT_CHARACTER)
			SELECT_ITEM:
				enter_state(SELECT_SLOT)
		return

	match state:
		SELECT_CHARACTER:
			if event.is_action_pressed("ui_up"):
				var old_index = current_char_index
				current_char_index = max(0, current_char_index - 1)
				if old_index == current_char_index:
					return
				menuSound.play()
				update_char_icons()
				refresh_equipped()
				update_stats_display()
				populate_inventory_list()
				update_pointer_position()
			elif event.is_action_pressed("ui_down"):
				var old_index = current_char_index
				current_char_index = min(characters.size() - 1, current_char_index + 1)
				if old_index == current_char_index:
					return
				menuSound.play()
				update_char_icons()
				refresh_equipped()
				update_stats_display()
				populate_inventory_list()
				update_pointer_position()
			elif event.is_action_pressed("ui_accept"):
				selectSound.play()
				current_slot_index = 0
				enter_state(SELECT_SLOT)
		SELECT_SLOT:
			if event.is_action_pressed("ui_up"):
				var old_index = current_slot_index
				current_slot_index = max(0, current_slot_index - 1)
				if old_index == current_slot_index:
					return
				menuSound.play()
			elif event.is_action_pressed("ui_down"):
				var old_index = current_slot_index
				current_slot_index = min(1, current_slot_index + 1)
				if old_index == current_slot_index:
					return
				menuSound.play()
			elif event.is_action_pressed("ui_accept"):
				selectSound.play()
				if current_items.is_empty():
					disabledSound.play()
					return
				enter_state(SELECT_ITEM)
			populate_inventory_list()
			update_pointer_position()
			update_description()
		SELECT_ITEM:
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
					enter_state(SELECT_SLOT)
				else:
					disabledSound.play()
			update_pointer_position()
			inventory_scroll.ensure_control_visible(items_vbox.get_child(current_item_index))
			update_description()
			update_stats_display(true, current_items[current_item_index])

func enter_state(new_state) -> void:
	state = new_state
	match state:
		SELECT_CHARACTER:
			selected_character = null
			description_label.text = ""
			update_char_icons()
			clear_inventory_list()
			refresh_equipped()
			update_stats_display()
			populate_inventory_list()
			if onLoad:
				onLoad = false
				call_deferred("update_pointer_position")
			else:
				update_pointer_position()
		SELECT_SLOT:
			selected_character = characters[current_char_index]
			refresh_equipped()
			update_stats_display()
			update_description()
			update_pointer_position()
		SELECT_ITEM:
			current_item_index = 0
			update_pointer_position()
			populate_inventory_list()
			update_description()
			update_stats_display(true, current_items[current_item_index])

func get_display_char() -> Node:
	return selected_character if selected_character else characters[current_char_index]

func get_icon_for_item(item: Equipment, disabled: bool = false) -> Texture:
	if not item:
		return null
	var type_map = ICON_MAP.get(item.type, {})
	if disabled and type_map.has("disabled"):
		return type_map["disabled"]  
	else:
		return type_map.get("normal", null)

func update_char_icons():
	var current_char = get_display_char()
	if current_char == player:
		player_icon.material.set_shader_parameter("enabled", false)
		princess_icon.material.set_shader_parameter("enabled", true)
	else:
		player_icon.material.set_shader_parameter("enabled", true)
		princess_icon.material.set_shader_parameter("enabled", false)

func update_pointer_position() -> void:
	var pointer_offset = Vector2(-14, 0)
	match state:
		SELECT_CHARACTER:
			if not character_hboxes.is_empty() and current_char_index < character_hboxes.size():
				var char_label = character_hboxes[current_char_index]
				pointer.global_position = char_label.global_position + pointer_offset
		SELECT_SLOT:
			pointer.global_position = slot_hboxes[current_slot_index].global_position + pointer_offset
		SELECT_ITEM:
			if items_vbox.get_child_count() > 0 and current_item_index < items_vbox.get_child_count():
				var item_hbox = items_vbox.get_child(current_item_index)
				pointer.global_position = item_hbox.global_position + pointer_offset

func refresh_equipped() -> void:
	var display_char: Node = get_display_char()
	for slot_idx in range(2):  # 0: weapon, 1: armor
		var item = display_char.equipment[slot_idx] if display_char.equipment.size() > slot_idx else null
		slot_icons[slot_idx].texture = get_icon_for_item(item)
		slot_names[slot_idx].text = item.name if item else "(No %s)" % ["weapon", "armor"][slot_idx]
		if slot_idx == 1 and not item:  # Armor-specific gray
			slot_names[slot_idx].add_theme_color_override("font_color", DISABLED_COLOR)
		else:
			slot_names[slot_idx].add_theme_color_override("font_color", Color.WHITE)
	update_ability_labels()

func clear_inventory_list() -> void:
	for child in items_vbox.get_children():
		child.queue_free()
	current_items = []

func get_filtered_items(is_weapon_slot: bool) -> Array[Equipment]:
	var all_equipped: Array[Equipment] = []
	for current_char in [player, princess]:
		if current_char:
			all_equipped += current_char.equipment.filter(func(i): return i != null)
	
	var filtered = all_equipment.filter(func(item: Equipment):
		if all_equipped.has(item): return false
		if is_weapon_slot:
			return item.type != Equipment.Type.ARMOR
		return item.type == Equipment.Type.ARMOR
	)
	
	if not is_weapon_slot:
		filtered.append(unequip_armor_resource)
	
	return filtered

func populate_inventory_list() -> void:
	clear_inventory_list()
	var is_weapon_slot = current_slot_index == 0
	inventory_title.text = "WEAPONS" if is_weapon_slot else "ARMORS"
	current_items = get_filtered_items(is_weapon_slot)
	
	var display_char = get_display_char()
	for item in current_items:
		var hbox = HBoxContainer.new()
		var icon = TextureRect.new()
		var disabled = not can_equip_item(display_char, item, current_slot_index)
		
		if item == unequip_armor_resource:
			icon.self_modulate.a = 0.0

		icon.texture = get_icon_for_item(item, disabled)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		hbox.add_child(icon)
		
		var name_label = Label.new()
		name_label.text = item.name
		if disabled:
			name_label.add_theme_color_override("font_color", DISABLED_COLOR)
		hbox.add_child(name_label)
		
		hbox.set_meta("disabled", disabled)
		items_vbox.add_child(hbox)

func can_equip_item(current_char: Node, item: Equipment, slot_idx: int) -> bool:
	if slot_idx == 0:  # Weapon
		return (current_char == player and item.type == Equipment.Type.SWORD) or (current_char == princess and item.type == Equipment.Type.BOW)
	return true  # Armor for all

func update_description() -> void:
	var item: Equipment = null
	match state:
		SELECT_SLOT:
			if selected_character.equipment.size() > current_slot_index:
				item = selected_character.equipment[current_slot_index]
		SELECT_ITEM:
			if current_items.size() > current_item_index:
				item = current_items[current_item_index]
	description_label.text = item.description if item else ""

func update_stats_display(preview: bool = false, preview_item: Equipment = null) -> void:
	var display_char = get_display_char()
	var base_attack = display_char.stats.attack
	var base_defense = display_char.stats.defense
	var attack_diff = 0
	var defense_diff = 0

	var show_preview = preview and preview_item and can_equip_item(display_char, preview_item, current_slot_index)

	if show_preview:
		var current_attack = 0
		var current_defense = 0
		if current_slot_index < display_char.equipment.size():
			var current_item = display_char.equipment[current_slot_index]
			current_attack = current_item.attack
			current_defense = current_item.defense
		
		attack_diff = preview_item.attack - current_attack
		defense_diff = preview_item.defense - current_defense
	
	attack_label.text = format_colored_stat(base_attack + attack_diff, attack_diff)
	defense_label.text = format_colored_stat(base_defense + defense_diff, defense_diff)
	
	update_ability_labels(show_preview, preview_item)
		
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
	var display_char: Node = get_display_char()
	var no_ability_text = "(No ability)"

	for slot_idx in range(2):
		var item = display_char.equipment[slot_idx] if display_char.equipment.size() > slot_idx else null
		var ability_text = item.ability if item and item.ability != "" else no_ability_text
		ability_labels[slot_idx].text = ability_text
		ability_labels[slot_idx].add_theme_color_override("font_color", DISABLED_COLOR if ability_text == no_ability_text else Color.WHITE)
		ability_icons[slot_idx].self_modulate.a = 0.0 if ability_text == no_ability_text else 1.0
		ability_icons[slot_idx].texture = ABILITY_ICON

	if preview and new_item:
		var new_ability = new_item.ability if new_item.ability != "" else no_ability_text
		var current_ability = ability_labels[current_slot_index].text
		if new_ability != current_ability:
			ability_labels[current_slot_index].text = new_ability
			ability_icons[current_slot_index].self_modulate.a = 0.0 if new_ability == no_ability_text else 1.0
			var color = Color.RED if new_ability == no_ability_text else Color.YELLOW
			ability_labels[current_slot_index].add_theme_color_override("font_color", color)

func equip_item(new_item: Equipment) -> void:
	var slot_idx = current_slot_index

	var old_item: Equipment = null
	if selected_character.equipment.size() > slot_idx and selected_character.equipment[slot_idx]:
		old_item = selected_character.equipment[slot_idx]

	while selected_character.equipment.size() <= slot_idx:
		selected_character.equipment.append(null)

	var new_item_inventory_index = all_equipment.find(new_item)

	if new_item == unequip_armor_resource:
		if old_item:
			all_equipment.append(old_item)
		selected_character.equipment.remove_at(slot_idx)

	else:
		selected_character.equipment[slot_idx] = new_item

		if new_item_inventory_index != -1:
			if old_item:
				all_equipment[new_item_inventory_index] = old_item
			else:
				all_equipment.remove_at(new_item_inventory_index)

	selected_character.update_stats()
	refresh_equipped()
	update_stats_display()

func _on_dialogue_started(_resource: DialogueResource):
	Events.menuOpen = false
	queue_free()
