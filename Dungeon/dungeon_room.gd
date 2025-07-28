extends Node2D

class_name DungeonRoom

enum {
	COMBAT,
	PUZZLE,
	LASER
}
@onready var princess: CharacterBody2D = $"../Princess"
@onready var princessCollider = $"../Princess/CollisionShape2D"
@onready var princessHurtbox: Hurtbox = $"../Princess/Hurtbox"
@onready var princessBlinkAnimation = $"../Princess/BlinkAnimationPlayer"

@export var flag: String
@export var combatLockOverride := false

var roomType
var players_in_room := {}
var roomCompleted := false
var CombatLockSound = load("res://Music and Sounds/combat_lock_sound.tscn")
var enemies: Array[CharacterBody2D]
var spikes: Array[StaticBody2D]
var lasers: Array[StaticBody2D]

func _ready() -> void:
	await get_tree().create_timer(1).timeout
	for child in get_children():
		if child.is_in_group("Enemy"):
			enemies.append(child)
			var health_component = child.get_node_or_null("Health_Component")
			health_component.enemy_died.connect(_on_enemy_died)
		elif child.is_in_group("Spikes"):
			spikes.append(child)
			var anim_sprite = child.get_node_or_null("AnimatedSprite2D")
			anim_sprite.set_frame(0)
		elif child.is_in_group("BoxPuzzle") and not child.no_reset:
			roomType = PUZZLE
			if Events.get_flag(flag):
				var puzzle = get_node_or_null("BoxPuzzle")
				puzzle.set_completed_state()
		elif child.is_in_group("Laser"):
			if child is Laser:
				lasers.append(child)
			else:
				lasers.append(child.get_node_or_null("Laser"))
				
	if not enemies.is_empty():
		roomType = COMBAT
		if Events.get_flag(flag):
			roomCompleted = true
			for enemy in enemies:
				enemy.queue_free()
	elif not lasers.is_empty():
		roomType = LASER
	
func activate_spikes():
	for spike in spikes:
		var anim_sprite = spike.get_node_or_null("AnimatedSprite2D")
		anim_sprite.play("Animate")
		
		var collision_shape = spike.get_node_or_null("CollisionShape2D")
		collision_shape.set_deferred("disabled", false)
			
func deactivate_spikes():
	for spike in spikes:
		var anim_sprite = spike.get_node_or_null("AnimatedSprite2D")
		anim_sprite.play_backwards("Animate")

		var collision_shape = spike.get_node_or_null("CollisionShape2D")
		collision_shape.set_deferred("disabled", true)

func start_overworld_hazard():
	Events.overworld_hazard_active = true
	princessCollider.set_deferred("disabled", true)
	princessHurtbox.disable_collider()
	princessBlinkAnimation.play("Disabled")
	princess.z_index = -1

func end_overworld_hazard():
	Events.overworld_hazard_active = false
	if Events.combat_locked:
		return
	princessCollider.set_deferred("disabled", false)
	princessHurtbox.enable_collider()
	princessBlinkAnimation.play("RESET")
	princess.z_index = 0

func activate_lasers():
	start_overworld_hazard()
	for laser in lasers:
		laser.start()
		
func deactivate_lasers():
	for laser in lasers:
		laser.end()

func combat_lock_room():
	if Events.combat_locked or roomCompleted:
		return
	
	Events.combat_locked = true
	if Events.debug_autocomplete:
		debug_killall()
		return
		
	Events.emit_signal("room_combat_locked")
	var combatLockSound = CombatLockSound.instantiate()
	get_tree().current_scene.add_child(combatLockSound)
	activate_spikes()
	
	for enemy in enemies:
		enemy.set_idle_state()

func un_combat_lock_room():
	Events.combat_locked = false
	Events.set_flag(flag)
	Events.emit_signal("room_un_combat_locked")
	var combatLockSound = CombatLockSound.instantiate()
	get_tree().current_scene.add_child(combatLockSound)
	deactivate_spikes()
	roomCompleted = true

func debug_killall():
	if not OS.is_debug_build() or not Events.combat_locked:
		return
	
	for enemy in enemies.duplicate():
		var health_component = enemy.get_node_or_null("Health_Component")
		health_component.damage(INF, "debug_killall")
		
func _on_enemy_died(enemy: CharacterBody2D):
	enemies.erase(enemy)
	if enemies.size() <= 0:
		un_combat_lock_room()
		
func _on_player_detector_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
		
	Events.currentRoom = self
	Events.room_entered.emit(self)
	if roomType == LASER:
		activate_lasers()
	elif Events.overworld_hazard_active:
		end_overworld_hazard()

func _on_player_detector_body_exited(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
		
	Events.room_exited.emit(self)
	if roomType == LASER:
		deactivate_lasers()

func _on_room_detector_body_entered(body: Node2D) -> void:
	if Events.num_party_members == 1 and body.is_in_group("Princess"):
		return
		
	players_in_room[body.get_instance_id()] = true
	if players_in_room.size() < Events.num_party_members:
		return
		
	Events.room_locked.emit(self)
	if roomType == COMBAT and not combatLockOverride:
		combat_lock_room()
		
func _on_room_detector_body_exited(body: Node2D) -> void:
	if Events.num_party_members == 1 and body.is_in_group("Princess"):
		return
		
	players_in_room.erase(body.get_instance_id())
