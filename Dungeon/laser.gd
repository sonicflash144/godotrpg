extends Node2D

class_name Laser

@onready var body = $Body
@onready var tail = $Tail
@onready var head_sprite = $Head/Sprite2D
@onready var body_sprite = $Body/Sprite2D
@onready var tail_sprite = $Tail/Sprite2D
@onready var headAnimationPlayer = $Head/HeadAnimationPlayer
@onready var bodyAnimationPlayer = $Body/BodyAnimationPlayer
@onready var tailAnimationPlayer = $Tail/TailAnimationPlayer
@onready var hitbox_shape = $LaserHitbox/CollisionShape2D
@onready var ray_cast = $RayCast2D
@onready var offsetTimer = $OffsetTimer
@onready var activeTimer = $ActiveTimer
@onready var cooldownTimer = $CooldownTimer

@export var stats: Stats
@export var permanent := false
@export var offset_length := 0.0
@export var active_length := 2.0
@export var cooldown_length := 1.0

var permanentSprite = preload("res://Dungeon/Sprites/permanent laser.png")

var isActive := false
const tail_height := 16.0
const head_height := 16.0
var original_body_height := 0.0

func _ready() -> void:
	if permanent:
		head_sprite.texture = permanentSprite
		body_sprite.texture = permanentSprite
		tail_sprite.texture = permanentSprite
		
	if body_sprite.texture:
		original_body_height = body_sprite.texture.get_height() / float(body_sprite.vframes) if body_sprite.vframes > 0 else body_sprite.texture.get_height()

func _physics_process(_delta: float) -> void:
	if isActive:
		update_laser_length()

func start():
	isActive = true
	if offset_length > 0:
		offsetTimer.start(offset_length)
	else:
		active()

func start_animation_finished():
	tailAnimationPlayer.play("Active")

func active():
	if not permanent:
		activeTimer.start(active_length)
	headAnimationPlayer.play("Start")
	bodyAnimationPlayer.play("Start")
	tailAnimationPlayer.play("Start")
	
func end():
	isActive = false
	activeTimer.stop()
	cooldownTimer.stop()
	
	if get_parent() is Laser_Movement:
		get_parent().reset_position()
	
	headAnimationPlayer.call_deferred("play", "End")
	bodyAnimationPlayer.call_deferred("play", "End")
	tailAnimationPlayer.call_deferred("play", "End")

func update_laser_length() -> void:
	ray_cast.position.y = head_height / 2.0
	ray_cast.force_raycast_update()
	
	if ray_cast.is_colliding():
		var collision_point: Vector2 = ray_cast.get_collision_point()
		
		var total_length: float = ray_cast.global_position.distance_to(collision_point)
		var body_length: float = max(0.0, total_length - tail_height)
		
		body_sprite.scale.y = body_length / original_body_height if original_body_height > 0 else 0.0
		body_sprite.position.y = body_length / 2.0
		
		body.position.y = head_height / 2.0
		tail.position.y = body.position.y + body_length + tail_height / 2.0
		
		var hitbox_rect = hitbox_shape.shape as RectangleShape2D
		if hitbox_rect:
			hitbox_rect.size.y = total_length
			hitbox_shape.position.y = head_height / 2.0 + total_length / 2.0

func _on_offset_timer_timeout() -> void:
	active()

func _on_active_timer_timeout() -> void:
	headAnimationPlayer.play("End")
	bodyAnimationPlayer.play("End")
	tailAnimationPlayer.play("End")
	cooldownTimer.start(cooldown_length)

func _on_cooldown_timer_timeout() -> void:
	active()
