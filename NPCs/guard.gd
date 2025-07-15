extends CharacterBody2D

@onready var animationTree = $AnimationTree
@onready var animationState = animationTree.get("parameters/playback")
@onready var tilemap = $"../TileMapLayer"

var MAX_SPEED = 80
var astar_path: Array[Vector2i]

func _physics_process(_delta: float):
	if not astar_path.is_empty():
		var target_position = tilemap.map_to_local(astar_path.front())
		var direction = target_position - global_position
		if direction.length() < 2:
			astar_path.pop_front()
		move_state(direction)
	else:
		move_state(Vector2.ZERO)

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

func move_to_position_astar(target_position: Vector2):
	if tilemap.is_point_walkable(target_position):
		astar_path = tilemap.astar.get_id_path(
			tilemap.local_to_map(global_position),
			tilemap.local_to_map(target_position)
		).slice(1)
