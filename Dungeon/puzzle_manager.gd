extends TileMapLayer

class_name Box_Puzzle

@onready var dialogueRoomManager: DialogueRoomManager = $"../../DialogueRoomManager"
@onready var player: CharacterBody2D = $"../../Player"
@onready var princess: CharacterBody2D = $"../../Princess"
@onready var playerAnimationTree: AnimationTree = $"../../Player/AnimationTree"
@onready var playerPushCast: RayCast2D = $"../../Player/PushCast"
@onready var resetButton = $ResetButton
@onready var boxSlideSound: AudioStreamPlayer = $BoxSlide
@onready var doorSound: AudioStreamPlayer = $DoorSound

@onready var sideDoor = get_node_or_null("../SideDoor")
@onready var puzzleDialogueBarrier: DialogueBarrier = get_node_or_null("../PuzzleDialogueBarrier")
@onready var puzzleDialogueBarrierCollisionShape = get_node_or_null("../PuzzleDialogueBarrier/CollisionShape2D")

@export var no_reset := false

var is_puzzle_complete: bool = false
var grid_types: Dictionary = {}
var goals: Array[Vector2i] = []
var boxes_dict: Dictionary = {}
var boxes_list: Array[Node] = []
var initial_positions: Array[Vector2] = []
var initial_grids: Array[Vector2i] = []
var tile_size: float = 16.0
var tile_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	if no_reset:
		resetButton.queue_free()
		
	var used_cells = get_used_cells()
	
	for cell in used_cells:
		var tile_data = get_cell_tile_data(cell)
		if tile_data:
			var type = tile_data.get_custom_data("type")

			if type in ["floor", "goal"]:
				grid_types[cell] = type
				if type == "goal":
					goals.append(cell)

	for sibling in get_parent().get_children():
		if sibling.is_in_group("Box") and sibling != self:
			boxes_list.append(sibling)
	if boxes_list.size() > 0:
		tile_offset = boxes_list[0].position - Vector2(pos_to_grid(boxes_list[0].position) * tile_size)
	for box in boxes_list:
		var grid = pos_to_grid(box.position)
		boxes_dict[grid] = box
		initial_positions.append(box.position)
		initial_grids.append(grid)

func pos_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(floor((pos.x - tile_offset.x) / tile_size), floor((pos.y - tile_offset.y) / tile_size))

func grid_to_pos(grid: Vector2i) -> Vector2:
	return Vector2(grid.x * tile_size, grid.y * tile_size) + tile_offset

func autocomplete():
	set_completed_state()
	doorSound.play()
	dialogueRoomManager.dialogue(get_parent().flag)

func set_completed_state():
	is_puzzle_complete = true
	get_parent().roomCompleted = true
	sideDoor.queue_free()
	puzzleDialogueBarrier.queue_free()
	
	boxes_dict.clear()
	for i in range(min(boxes_list.size(), goals.size())):
		var box = boxes_list[i]
		var goal_grid = goals[i]
		var new_pos = grid_to_pos(goal_grid)
		box.position = new_pos
		boxes_dict[goal_grid] = box

func _unhandled_key_input(event: InputEvent) -> void:
	if is_puzzle_complete or Events.currentRoom != get_parent():
		return
	
	if event.is_action_pressed("debug_killall") and OS.is_debug_build() and Events.controlsEnabled and not no_reset:
		autocomplete()
	elif event.is_action_pressed("ui_accept") and Events.controlsEnabled:
		var facing = playerAnimationTree.get("parameters/Idle/blend_position")
		if facing == Vector2.ZERO:
			return

		var push_dir: Vector2
		if abs(facing.x) > abs(facing.y):
			push_dir = Vector2(sign(facing.x), 0)
		else:
			push_dir = Vector2(0, sign(facing.y))
		
		playerPushCast.target_position = push_dir * tile_size * 0.5
		playerPushCast.force_raycast_update()
		
		if playerPushCast.is_colliding():
			var box = playerPushCast.get_collider()
			if box and box.is_in_group("Box"):
				var box_grid = pos_to_grid(box.position)
				var dest_grid = box_grid + Vector2i(push_dir)
				if grid_types.has(dest_grid) and not boxes_dict.has(dest_grid):
					Events.controlsEnabled = false
					boxSlideSound.play()
					boxes_dict.erase(box_grid)
					var dest_pos = grid_to_pos(dest_grid)
					var tween = create_tween()
					tween.tween_property(box, "position", dest_pos, 0.2).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
					tween.finished.connect(_on_box_moved.bind(box, dest_grid))

func _on_box_moved(box: StaticBody2D, dest_grid: Vector2i):
	Events.controlsEnabled = true
	boxes_dict[dest_grid] = box
	check_win()

func check_win() -> void:
	if goals.is_empty():
		return
		
	var filled = true
	for goal in goals:
		if not boxes_dict.has(goal):
			filled = false
			break
	if filled:
		is_puzzle_complete = true
		get_parent().roomCompleted = true
		sideDoor.queue_free()
		puzzleDialogueBarrier.queue_free()
		doorSound.play()
		dialogueRoomManager.dialogue(get_parent().flag)

func start_puzzle():
	princess.set_nav_state()
	puzzleDialogueBarrierCollisionShape.set_deferred("disabled", false)
	dialogueRoomManager.dialogue("enter_%s" % get_parent().flag)

func reset_puzzle() -> void:
	if is_puzzle_complete:
		return
		
	for i in range(boxes_list.size()):
		var box = boxes_list[i]
		var init_pos = initial_positions[i]
		box.position = init_pos
	boxes_dict.clear()
	for i in range(boxes_list.size()):
		boxes_dict[initial_grids[i]] = boxes_list[i]
