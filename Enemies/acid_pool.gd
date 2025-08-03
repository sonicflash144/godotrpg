extends Node

@onready var hitbox: Hitbox = $ShockwaveHitbox
@onready var animationPlayer = $AnimationPlayer

@export var stats: Stats

func _ready() -> void:
	animationPlayer.play("Animate")

func _on_timer_timeout() -> void:
	queue_free()
