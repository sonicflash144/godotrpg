extends Node

@onready var player: CharacterBody2D = $"../Player"
@onready var playerMovementComponent: Movement_Component = $"../Player/Movement_Component"
@onready var playerHealthComponent: Health_Component = $"../Player/Health_Component"
@onready var princessHealthComponent: Health_Component = get_node_or_null("../Princess/Health_Component")

func _ready() -> void:
	Events.console_heal.connect(_on_console_heal)
	Events.console_autocomplete.connect(_on_console_autocomplete)
	Events.console_invincibility.connect(_on_console_invincibility)
	Events.console_give.connect(_on_console_give)

func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
		
	if event.is_action_pressed("debug_run"):
		playerMovementComponent.MAX_SPEED = 320
	elif event.is_action_released("debug_run"):
		playerMovementComponent.MAX_SPEED = 80

func _on_console_heal():
	playerHealthComponent.heal(playerHealthComponent.MAX_HEALTH)
	if princessHealthComponent:
		princessHealthComponent.heal(princessHealthComponent.MAX_HEALTH)

func _on_console_autocomplete():
	Events.debug_autocomplete = not Events.debug_autocomplete
	if Events.debug_autocomplete:
		LimboConsole.info("Autocomplete ON")
	else:
		LimboConsole.info("Autocomplete OFF")

func _on_console_invincibility():
	if playerHealthComponent.invincible:
		LimboConsole.info("Invincibility OFF")
		playerHealthComponent.invincible = false
		if princessHealthComponent:
			princessHealthComponent.invincible = false
	else:
		LimboConsole.info("Invincibility ON")
		playerHealthComponent.invincible = true
		if princessHealthComponent:
			princessHealthComponent.invincible = true
	
func _on_console_give(item_name: String):
	var item_path = "res://Equipment/%s.tres" % item_name
	var item = load(item_path)
	player.storage.append(item)
