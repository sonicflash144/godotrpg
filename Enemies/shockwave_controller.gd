extends Node

@onready var hitbox: Hitbox = $ShockwaveHitbox
@onready var animationPlayer = $AnimationPlayer

@export var stats: Stats

func _ready() -> void:
	animationPlayer.play("Animate")

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()
