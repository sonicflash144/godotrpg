extends TileMapLayer

var astar = AStarGrid2D.new()
var map_rect = Rect2i()

func _ready() -> void:
	var tilemap_size = get_used_rect().end - get_used_rect().position
	map_rect = Rect2i(get_used_rect().position, tilemap_size)
	var tile_size = get_tile_set().tile_size
	
	astar.region = map_rect
	astar.cell_size = tile_size
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	for i in range(get_used_rect().position.x, get_used_rect().end.x):
		for j in range(get_used_rect().position.y, get_used_rect().end.y):
			var coords = Vector2i(i, j)
			var tile_data = get_cell_tile_data(coords)
			if not tile_data or tile_data.get_custom_data("type") == "wall":
				astar.set_point_solid(coords)

func is_point_walkable(pos):
	var map_position = local_to_map(pos)
	if map_rect.has_point(map_position) and not astar.is_point_solid(map_position):
		return true
	return false
