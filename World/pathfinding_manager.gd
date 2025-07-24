# NavigationManager.gd
extends Node

class_name PathfindingManager

var astar := AStarGrid2D.new()

func _ready() -> void:
	await get_tree().process_frame
	
	var tilemaps := get_tree().get_nodes_in_group("NavTileMap")
	
	# figure out global grid bounds (in cells)
	var cell_size = tilemaps[0].get_tile_set().tile_size
	var global_min := Vector2i(99999,  99999)
	var global_max := Vector2i(-99999, -99999)
	for tilemap in tilemaps:
		# used_rect is in local-cell coords
		var rect = tilemap.get_used_rect()
		# offset each map by its world‑position in cells
		var offset := Vector2i(tilemap.global_position.x / cell_size.x, tilemap.global_position.y / cell_size.y)
		global_min = Vector2i(min(global_min.x, rect.position.x + offset.x), min(global_min.y, rect.position.y + offset.y))
		global_max = Vector2i(max(global_max.x, rect.end.x + offset.x), max(global_max.y, rect.end.y + offset.y))
		
	astar.region = Rect2i(global_min, global_max - global_min)
	astar.cell_size = cell_size
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()
	
	# mark every blocked tile
	for tilemap in tilemaps:
		var rect = tilemap.get_used_rect()
		var offset := Vector2i(tilemap.global_position.x / cell_size.x, tilemap.global_position.y / cell_size.y)
		for x in range(rect.position.x, rect.end.x):
			for y in range(rect.position.y, rect.end.y):
				var cell := Vector2i(x, y) + offset
				var data = tilemap.get_cell_tile_data(Vector2i(x, y))
				if data == null or data.get_custom_data("type") == "wall":
					astar.set_point_solid(cell)
