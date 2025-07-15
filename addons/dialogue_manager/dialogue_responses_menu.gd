@icon("./assets/responses_menu.svg")
## A [Container] for dialogue responses provided by [b]Dialogue Manager[/b].
class_name DialogueResponsesMenu extends VBoxContainer

## Emitted when a response is selected.
signal response_selected(response)

## Optionally specify a control to duplicate for each response
@export var response_template: Control
## The action for accepting a response (is possibly overridden by parent dialogue balloon).
@export var next_action: StringName = &""
## Hide any responses where [code]is_allowed[/code] is false
@export var hide_failed_responses: bool = false

var first_navigation_input_received = false

## The list of dialogue responses.
var responses: Array = []:
	get:
		return responses
	set(value):
		responses = value
		first_navigation_input_received = false
		# Remove any current items
		for item in get_children():
			if item == response_template:
				continue
			remove_child(item)
			item.queue_free()
		
		# Add new items
		if responses.size() > 0:
			for response in responses:
				if hide_failed_responses and not response.is_allowed:
					continue
				
				var item: Control
				if is_instance_valid(response_template):
					item = response_template.duplicate(DUPLICATE_GROUPS | DUPLICATE_SCRIPTS | DUPLICATE_SIGNALS)
					item.show()
				else:
					# Create a horizontal container for the arrow and button
					var container = HBoxContainer.new()
					container.name = "ResponseContainer%d" % get_child_count()
					
					# Create the arrow sprite (TextureRect)
					var arrow_texture = TextureRect.new()
					arrow_texture.name = "Arrow"
					arrow_texture.texture = preload("res://UI/pointer.png")
					arrow_texture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
					arrow_texture.modulate.a = 0.0
					container.add_child(arrow_texture)

					# Create the button
					var button = Button.new()
					button.name = "Response%d" % get_child_count()
					button.text = response.text
					container.add_child(button)
					
					item = container
					# Store reference to button for focus handling
					item.set_meta("button", button)
				
				if not response.is_allowed:
					if item.has_method("set_disabled"):
						item.disabled = true
					elif item.has_meta("button"):
						item.get_meta("button").disabled = true
					item.name = item.name + "Disallowed"
				
				# If the item has a response property then use that
				if "response" in item:
					item.response = response
				# Otherwise assume we can just set the text
				else:
					item.set_meta("response", response)
				
				add_child(item)
		
		_configure_focus()


func _ready() -> void:
	if is_instance_valid(response_template):
		response_template.hide()


func _physics_process(delta: float) -> void:
	# This function handles grabbing focus on the first navigation input (`ui_up`/`ui_down`)
	# after the responses have been displayed.

	# Stop processing if the menu is hidden, empty, or if the first input was already received.
	if not visible or first_navigation_input_received or get_menu_items().is_empty():
		return

	var items = get_menu_items()
	var target_button: Control = null

	if Input.is_action_just_pressed(&"ui_down"):
		# If 'down' is pressed, select the second item, or the first if it's the only one.
		# This feels more natural than starting at the top.
		var item_to_focus = items[0]
		if items.size() > 1:
			item_to_focus = items[1]
		target_button = _get_button_from_item(item_to_focus)
	elif Input.is_action_just_pressed(&"ui_up"):
		# If 'up' is pressed, always select the top item.
		target_button = _get_button_from_item(items[0])

	if target_button:
		target_button.grab_focus()
		first_navigation_input_received = true


## Get the selectable items in the menu.
func get_menu_items() -> Array:
	var items: Array = []
	for child in get_children():
		if not child.visible:
			continue
		if "Disallowed" in child.name:
			continue
		items.append(child)
	return items


## Get the button control from an item (handles both direct buttons and containers)
func _get_button_from_item(item: Control) -> Control:
	if item is Button:
		return item
	elif item.has_meta("button"):
		return item.get_meta("button")
	elif item.has_method("find_child"):
		return item.find_child("Response*", true, false)
	return null


## Get the arrow from an item
func _get_arrow_from_item(item: Control) -> TextureRect:
	if item.has_method("find_child"):
		return item.find_child("Arrow", true, false)
	return null


## Update arrow visibility based on focus (currently unused, focus callbacks are used instead)
func _update_arrow_visibility():
	var items = get_menu_items()
	for item in items:
		var arrow = _get_arrow_from_item(item)
		var button = _get_button_from_item(item)
		
		if arrow and button:
			arrow.visible = button.has_focus()

#region Internal

# Prepare the menu for keyboard navigation.
func _configure_focus() -> void:
	var items = get_menu_items()
	
	for i in items.size():
		var item: Control = items[i]
		var button = _get_button_from_item(item)
		
		if not button:
			continue
			
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.focus_neighbor_left = button.get_path()
		button.focus_neighbor_right = button.get_path()
		
		if i == 0:
			button.focus_neighbor_top = button.get_path()
			button.focus_previous = button.get_path()
		else:
			var prev_button = _get_button_from_item(items[i - 1])
			if prev_button:
				button.focus_neighbor_top = prev_button.get_path()
				button.focus_previous = prev_button.get_path()
		
		if i == items.size() - 1:
			button.focus_neighbor_bottom = button.get_path()
			button.focus_next = button.get_path()
		else:
			var next_button = _get_button_from_item(items[i + 1])
			if next_button:
				button.focus_neighbor_bottom = next_button.get_path()
				button.focus_next = next_button.get_path()
		
		# Connect signals for input handling and focus changes
		button.gui_input.connect(_on_response_gui_input.bind(button, item.get_meta("response")))
		button.focus_entered.connect(_on_button_focus_entered.bind(item))
		button.focus_exited.connect(_on_button_focus_exited.bind(item))

#endregion

#region Signals

func _on_response_gui_input(event: InputEvent, button: Control, response) -> void:
	if button.disabled:
		return
	
	if event.is_action_pressed(&"ui_accept" if next_action.is_empty() else next_action):
		get_viewport().set_input_as_handled()
		response_selected.emit(response)


func _on_button_focus_entered(item: Control) -> void:
	var arrow = _get_arrow_from_item(item)
	if arrow:
		arrow.modulate.a = 1.0


func _on_button_focus_exited(item: Control) -> void:
	var arrow = _get_arrow_from_item(item)
	if arrow:
		arrow.modulate.a = 0.0

#endregion
