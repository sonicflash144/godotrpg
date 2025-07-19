extends Node

@onready var hitbox: Hitbox = $ShockwaveHitbox
@onready var animationPlayer = $AnimationPlayer

func _ready() -> void:
	hitbox.damage = 10
	animationPlayer.play("Animate")

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()
