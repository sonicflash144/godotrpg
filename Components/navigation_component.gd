extends Node

class_name Navigation_Component

@onready var character: CharacterBody2D = $".."
@onready var movement_component: Movement_Component = $"../Movement_Component"
@onready var tilemap: TileMapLayer = $"../../TileMapLayer"

var astar_path: Array[Vector2i] = []

func _ready() -> void:
	update_physics_process()

func _physics_process(_delta: float) -> void:
	if not astar_path.is_empty():
		var target_position = tilemap.map_to_local(astar_path.front())
		var direction = target_position - character.global_position
		if direction.length() < 2:
			astar_path.pop_front()
		movement_component.move(direction.normalized())
	else:
		movement_component.move(Vector2.ZERO)

func move_to_position_astar(target_position: Vector2):
	if tilemap.is_point_walkable(target_position):
		astar_path = tilemap.astar.get_id_path(
			tilemap.local_to_map(character.global_position),
			tilemap.local_to_map(target_position)
		).slice(1)
	else:
		astar_path.clear()
	update_physics_process()

func update_physics_process():
	# Enable physics process only when in NAV state
	set_physics_process(character.state == character.NAV)
