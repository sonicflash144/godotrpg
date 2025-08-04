extends Area2D

@onready var hitbox: Hitbox = $SpearHitbox
@onready var spearSound: AudioStreamPlayer = $SpearSound

@export var stats: Stats

var speed := 500.0
var direction := Vector2.ZERO
var target_position := Vector2.ZERO
var is_launched := false

var target_to_follow: Node2D = null
var offset_from_target := Vector2.ZERO

func _physics_process(delta: float) -> void:
	if is_launched:
		global_position += direction * speed * delta
	elif target_to_follow:
		global_position = target_to_follow.global_position + offset_from_target
		# Continuously update rotation to track the player before launch
		rotation = global_position.direction_to(target_to_follow.global_position).angle() - (3 * PI / 4.0)

func initialize(player: Node2D, offset: Vector2) -> void:
	target_to_follow = player
	offset_from_target = offset

func set_target(pos: Vector2) -> void:
	target_position = pos
	direction = global_position.direction_to(target_position)
	hitbox.knockback_vector = direction
	
	var sw_angle_offset = 3 * PI / 4.0
	rotation = direction.angle() - sw_angle_offset

func stop_tracking_player():
	if target_to_follow:
		target_position = target_to_follow.global_position
	target_to_follow = null

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Start":
		if target_position != Vector2.ZERO:
			set_target(target_position)
		
		is_launched = true
		spearSound.play()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
