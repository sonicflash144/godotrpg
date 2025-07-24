extends TileMapLayer

@onready var pathfindingManager = $"../PathfindingManager"

func _ready() -> void:
	await get_tree().process_frame
	pathfindingManager.register_tilemap(self)

func _exit_tree() -> void:
	if pathfindingManager:
		pathfindingManager.unregister_tilemap(self)
