extends CharacterBody2D

@onready var hurtbox = $Hurtbox
@onready var blinkAnimationPlayer = $BlinkAnimationPlayer
@onready var animationTree = $AnimationTree
@onready var animationState = animationTree.get("parameters/playback")
@onready var navigationAgent = $NavigationAgent2D
@onready var tilemap = $"../TileMapLayer"

var MAX_SPEED = 80
var knockback = Vector2.ZERO
var astar_path: Array[Vector2i]

func _physics_process(delta: float):
	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)
	if not astar_path.is_empty():
		var target_position = tilemap.map_to_local(astar_path.front())
		var direction = target_position - global_position
		if direction.length() < 2:
			astar_path.pop_front()
		move_state(direction)
	elif not navigationAgent.is_navigation_finished():
		var direction = navigationAgent.get_next_path_position() - global_position
		move_state(direction)
	else:
		move_state(Vector2.ZERO)
	velocity += knockback

	move_and_slide()
	
func move_state(input_vector: Vector2):
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		animationState.travel("Run")
		velocity = input_vector * MAX_SPEED
	else:
		animationState.travel("Idle")
		velocity = Vector2.ZERO

func _on_hurtbox_trigger_knockback(knockback_vector: Vector2) -> void:
	knockback = knockback_vector * 100
	
func move_to_position_nav(target_position: Vector2):
	navigationAgent.target_position = target_position
	
func move_to_position_astar(target_position: Vector2):
	if tilemap.is_point_walkable(target_position):
		astar_path = tilemap.astar.get_id_path(
			tilemap.local_to_map(global_position),
			tilemap.local_to_map(target_position)
		).slice(1)
