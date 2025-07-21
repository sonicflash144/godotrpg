extends Node

@onready var swapCooldownTimer = $SwapCooldownTimer
@onready var swapSound = $AudioStreamPlayer

@onready var player: CharacterBody2D = $"../Player"
@onready var playerCollider = $"../Player/CollisionShape2D"
@onready var playerHurtbox: Hurtbox = $"../Player/Hurtbox"
@onready var playerHealthUI: Health_UI = $"../CanvasLayer/PlayerHealthUI"
@onready var playerBlinkAnimation = $"../Player/BlinkAnimationPlayer"
@onready var playerHealthComponent: Health_Component = $"../Player/Health_Component"

@onready var princess: CharacterBody2D = $"../Princess"
@onready var princessCollider = $"../Princess/CollisionShape2D"
@onready var princessHurtbox: Hurtbox = $"../Princess/Hurtbox"
@onready var princessHealthUI: Health_UI = $"../CanvasLayer/PrincessHealthUI"
@onready var princessBlinkAnimation = $"../Princess/BlinkAnimationPlayer"
@onready var princessHealthComponent: Health_Component = $"../Princess/Health_Component"

const SWAP_COOLDOWN_DURATION := 4.0
var combat_locked := false
var can_swap_control := true
var MenuScene = load("res://UI/equipment_menu.tscn")
var BackSound = load("res://Music and Sounds/back_sound.tscn")

func _ready() -> void:
	Events.room_combat_locked.connect(_on_room_combat_locked)
	Events.room_un_combat_locked.connect(_on_room_un_combat_locked)

func open_menu():
	Events.menuOpen = true
	var menuScene = MenuScene.instantiate()
	get_tree().current_scene.add_child(menuScene)

func swap_controlled_player():
	Events.is_player_controlled = not Events.is_player_controlled
	swapSound.play()
	player.get_node("Follow_Component").clear_path_history()
	princess.get_node("Follow_Component").clear_path_history()
	update_controlled_player()

func update_controlled_player(justEntered := false):
	if Events.is_player_controlled:
		playerCollider.set_deferred("disabled", false)
		princessCollider.set_deferred("disabled", true)
		playerHurtbox.enable_collider()
		princessHurtbox.disable_collider()
		playerHealthUI.enable_texture()
		if justEntered:
			princessHealthUI.disable_texture()
		else:
			princessHealthUI.disable_texture(SWAP_COOLDOWN_DURATION)
		playerBlinkAnimation.play("Enabled")
		princessBlinkAnimation.play("Disabled")
		player.z_index = 0
		princess.z_index = -1
	else:
		playerCollider.set_deferred("disabled", true)
		princessCollider.set_deferred("disabled", false)
		playerHurtbox.disable_collider()
		princessHurtbox.enable_collider()
		playerHealthUI.disable_texture(SWAP_COOLDOWN_DURATION)
		princessHealthUI.enable_texture()
		playerBlinkAnimation.play("Disabled")
		princessBlinkAnimation.play("Enabled")
		player.z_index = -1
		princess.z_index = 0

func _on_room_combat_locked():
	combat_locked = true
	if not Events.playerDown and not Events.princessDown:
		update_controlled_player(true)

func _on_room_un_combat_locked():
	combat_locked = false
	if Events.num_party_members < 2:
		return
	if not Events.is_player_controlled:
		Events.is_player_controlled = true
		player.get_node("Follow_Component").clear_path_history()
		princess.get_node("Follow_Component").clear_path_history()
	if Events.playerDown:
		playerHealthComponent.heal(1)
		Events.playerDown = false
	elif Events.princessDown:
		princessHealthComponent.heal(1)
		Events.princessDown = false
	playerCollider.set_deferred("disabled", false)
	princessCollider.set_deferred("disabled", false)
	playerHurtbox.enable_collider()
	princessHurtbox.enable_collider()
	playerHealthUI.enable_texture()
	princessHealthUI.enable_texture()
	playerBlinkAnimation.play("RESET")
	princessBlinkAnimation.play("RESET")
	player.z_index = 0
	princess.z_index = 0

func _on_health_component_player_down(down: bool) -> void:
	if down:
		swap_controlled_player()
	else:
		update_controlled_player()

func _on_health_component_princess_down(down: bool) -> void:
	if down:
		swap_controlled_player()
	else:
		update_controlled_player()

func _on_swap_cooldown_timer_timeout() -> void:
	can_swap_control = true

func _unhandled_key_input(event: InputEvent) -> void:
	if combat_locked and event.is_action_pressed("swap_player") and can_swap_control \
	and not Events.playerDown and not Events.princessDown:
		swap_controlled_player()
		can_swap_control = false
		swapCooldownTimer.start(SWAP_COOLDOWN_DURATION)
	elif not combat_locked and event.is_action_pressed("open_menu"):
		if not Events.menuOpen and Events.controlsEnabled:
			open_menu()
		else:
			var menuScene = get_parent().get_node_or_null("EquipmentMenu")
			if menuScene:
				Events.menuOpen = false
				var backSound = BackSound.instantiate()
				get_tree().current_scene.add_child(backSound)
				menuScene.queue_free()
				Events.enable_controls()
