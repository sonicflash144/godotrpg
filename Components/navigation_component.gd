extends Node

class_name Navigation_Component

@onready var pathfindingManager: PathfindingManager = $"../../PathfindingManager"
@onready var character: CharacterBody2D = $".."
@onready var movement_component: Movement_Component = $"../Movement_Component"

var astar_path: Array[Vector2i] = []
var ending_direction := Vector2.ZERO

func _ready() -> void:
	update_physics_process()

func _physics_process(_delta: float) -> void:
	if Events.inCutscene:
		return
	
	if astar_path.size() > 0:
		# 1) get next cell and turn it into a world position
		var cell = astar_path[0]
		var cell_size = pathfindingManager.astar.cell_size
		var world_pos = Vector2(cell) * cell_size + cell_size * 0.5
		var direction = world_pos - character.global_position

		# 2) advance when close
		if direction.length() < 2.0:
			astar_path.pop_front()
		movement_component.move(direction.normalized())
	else:
		movement_component.move(Vector2.ZERO)
		if ending_direction != Vector2.ZERO:
			movement_component.update_animation_direction(ending_direction)

func move_to_position_astar(target_pos: Vector2, end_dir := Vector2.ZERO) -> void:
	ending_direction = end_dir
	var cell_size := pathfindingManager.astar.cell_size
	var start_cell = Vector2i(
		floor(character.global_position.x / cell_size.x),
		floor(character.global_position.y / cell_size.y)
	)
	var end_cell = Vector2i(
		floor(target_pos.x / cell_size.x),
		floor(target_pos.y / cell_size.y)
	)

	# only pathfind if inside region and not solid
	var region = pathfindingManager.astar.region
	if region.has_point(end_cell) and not pathfindingManager.astar.is_point_solid(end_cell):
		astar_path = pathfindingManager.astar.get_id_path(start_cell, end_cell)
		if astar_path.size() > 0:
			astar_path.pop_front()
	else:
		astar_path.clear()
	
	update_physics_process()

func update_physics_process():
	# Enable physics process only when in NAV state
	set_physics_process(character.state == character.NAV)
