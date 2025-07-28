extends CharacterBody2D

@onready var swordHitbox: Hitbox = $HitboxPivot/SwordHitbox
@onready var health_component: Health_Component = $Health_Component
@onready var movement_component: Movement_Component = $Movement_Component
@onready var follow_component: Follow_Component = $Follow_Component

@onready var princess: CharacterBody2D = get_node_or_null("../Princess")

@export var stats: Stats
@export var equipment: Array[Equipment]

enum {
	MOVE,
	ATTACK,
	FOLLOW,
	NAV
}
var state = MOVE
var storage: Array[Equipment]

func _ready() -> void:
	follow_component.set_target(princess)
	if not Events.deferred_load_data.is_empty():
		load_equipment()
	else:
		update_stats()

func _physics_process(_delta: float) -> void:
	if state != ATTACK:
		if Events.is_player_controlled:
			state = MOVE
		else: 
			state = FOLLOW

	match state:
		MOVE:
			move_state()
		ATTACK:
			attack_state()
		FOLLOW:
			follow_component.follow()

func load_equipment():
	equipment.clear()
	for item_name in Events.deferred_load_data["player_equipment"]:
		var item_path = "res://Equipment/%s.tres" % item_name
		var item = load(item_path)
		equipment.append(item)
	update_stats()
		
	if princess and Events.num_party_members > 1:
		princess.equipment.clear()
		for item_name in Events.deferred_load_data["princess_equipment"]:
			var item_path = "res://Equipment/%s.tres" % item_name
			var item = load(item_path)
			princess.equipment.append(item)
		princess.update_stats()
		
	storage.clear()
	for item_name in Events.deferred_load_data["storage"]:
		var item_path = "res://Equipment/%s.tres" % item_name
		var item = load(item_path)
		storage.append(item)
	
func update_stats():
	stats.attack = 0
	stats.defense = 0
	for item in equipment:
		stats.attack += item.attack
		stats.defense += item.defense
	swordHitbox.update_damage()
	if princess and Events.num_party_members > 1:
		Events.update_equipment_abilities(equipment, princess.equipment)
	else:
		Events.update_equipment_abilities(equipment)

func move_state():
	var move_direction = movement_component.get_player_input_vector().normalized()
	movement_component.move(move_direction)
	if Events.controlsEnabled and Events.player_has_sword and Input.is_action_just_pressed("attack"):
		state = ATTACK

func attack_state():
	movement_component.move(Vector2.ZERO, movement_component.MAX_SPEED, "Attack")
	var sword_direction = movement_component.animation_tree.get("parameters/Attack/blend_position")
	swordHitbox.knockback_vector = sword_direction

func attack_animation_finished():
	state = MOVE if Events.is_player_controlled else FOLLOW
