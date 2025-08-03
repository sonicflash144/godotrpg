extends Area2D

@onready var hitbox: Hitbox = $JellyfishHitbox
@export var stats: Stats

var speed := 400.0
var arc_amplitude := 50.0 # max perpendicular offset
var flight_time := 1.0    # seconds to complete half the ellipse
var P0 := Vector2.ZERO     # start point
var P1 := Vector2.ZERO     # control point
var P2 := Vector2.ZERO     # target point
var P3 := Vector2.ZERO     # return control point
var timer := 0.0
var total_flight_time := 2.0  # Total time for complete ellipse

func _ready() -> void:
	hitbox.knockback_vector = Vector2.ZERO
	total_flight_time = flight_time * 2.0

func set_target_position(target_pos: Vector2) -> void:
	# 1) save start & end
	P0 = global_position
	P2 = target_pos
	
	# 2) compute control points for ellipse
	var dir = (P2 - P0).normalized()
	var perp = dir.orthogonal()
	
	# First half control point (outward arc)
	P1 = P0.lerp(P2, 0.5) + perp * arc_amplitude
	
	# Second half control point (return arc, opposite side)
	P3 = P0.lerp(P2, 0.5) - perp * arc_amplitude
	
	# reset timer
	timer = 0.0

func _physics_process(delta: float) -> void:
	timer += delta
	
	# Normalize timer to 0-2 range (0-1 for first half, 1-2 for second half)
	var normalized_time = timer / flight_time
	
	var pos: Vector2
	
	if normalized_time <= 1.0:
		# First half: P0 -> P2 via P1
		var t = normalized_time
		var one_minus_t = 1.0 - t
		pos = one_minus_t * one_minus_t * P0 + \
			  2.0 * one_minus_t * t * P1 + \
			  t * t * P2
	else:
		# Second half: P2 -> P0 via P3
		var t = normalized_time - 1.0  # Convert to 0-1 range for second curve
		var one_minus_t = 1.0 - t
		pos = one_minus_t * one_minus_t * P2 + \
			  2.0 * one_minus_t * t * P3 + \
			  t * t * P0
	
	# Compute velocity for rotation
	var eps = 0.001
	var future_time = (timer + eps) / flight_time
	var future_pos: Vector2
	
	if future_time <= 1.0:
		var t_f = future_time
		var omt_f = 1.0 - t_f
		future_pos = omt_f * omt_f * P0 + \
					 2.0 * omt_f * t_f * P1 + \
					 t_f * t_f * P2
	else:
		var t_f = future_time - 1.0
		var omt_f = 1.0 - t_f
		future_pos = omt_f * omt_f * P2 + \
					 2.0 * omt_f * t_f * P3 + \
					 t_f * t_f * P0
	
	var velocity = (future_pos - pos) / eps
	
	# Move and rotate
	global_position = pos
	if velocity.length() > 0.0:
		rotation = velocity.angle()
	
	# Remove bullet after completing full ellipse
	if timer >= total_flight_time:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Hurtbox":
		queue_free()
