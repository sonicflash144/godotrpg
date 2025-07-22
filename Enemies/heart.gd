extends Area2D

@onready var playerHealthComponent: Health_Component = $"../Player/Health_Component"
@onready var princessHealthComponent: Health_Component = $"../Princess/Health_Component"
@onready var blinkAnimationPlayer = $BlinkAnimationPlayer
@onready var flickerTimer = $FlickerTimer
@onready var despawnTimer = $DespawnTimer

var HealSound = load("res://Music and Sounds/heal_sound.tscn")

func _ready() -> void:
	flickerTimer.start(3.5)

func _on_body_entered(body: Node2D) -> void:
	var playerMax: bool = playerHealthComponent.is_max_health()
	var princessMax: bool = princessHealthComponent.is_max_health()
	
	var healSound = HealSound.instantiate()
	get_tree().current_scene.add_child(healSound)
	
	if playerMax and princessMax:
		pass
	elif body.is_in_group("Player"):
		if not playerMax:
			playerHealthComponent.heal()
		else:
			princessHealthComponent.heal()
	elif body.is_in_group("Princess"):
		if not princessMax:
			princessHealthComponent.heal()
		else:
			playerHealthComponent.heal()
			
	queue_free()

func _on_flicker_timer_timeout() -> void:
	blinkAnimationPlayer.play("Flicker")
	despawnTimer.start(1.5)

func _on_despawn_timer_timeout() -> void:
	queue_free()
