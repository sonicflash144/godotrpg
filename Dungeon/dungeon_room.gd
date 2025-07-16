extends Node2D

enum {
	INACTIVE,
	IDLE,
	WANDER,
	CHASE
}
var players_in_room: = {}
var combat_locked: bool = false
var CombatLockSound = load("res://Music and Sounds/combat_lock_sound.tscn")
var isFinished: bool = false
var killCount = 0
var killThreshold: int
var enemies: Array[CharacterBody2D]
var spikes: Array[StaticBody2D]

func _ready() -> void:
	for child in get_children():
		if child.is_in_group("Enemy"):
			enemies.append(child)
			var health_component = child.get_node_or_null("Health_Component")
			health_component.enemy_died.connect(_on_enemy_died)
		elif child.is_in_group("Spikes"):
			spikes.append(child)
			var anim_sprite = child.get_node_or_null("AnimatedSprite2D")
			anim_sprite.set_frame(0)
	killThreshold = enemies.size()

func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		Events.room_entered.emit(self)

func _on_room_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") or body.is_in_group("Princess"):
		players_in_room[body.get_instance_id()] = true

		if players_in_room.size() == Events.num_party_members:
			Events.room_locked.emit(self)

func _on_room_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") or body.is_in_group("Princess"):
		players_in_room.erase(body.get_instance_id())
	
func activate_spikes():
	for spike in spikes:
		var anim_sprite = spike.get_node_or_null("AnimatedSprite2D")
		if anim_sprite:
			anim_sprite.play("Animate")
		
		var collision_shape = spike.get_node_or_null("CollisionShape2D")
		if collision_shape:
			collision_shape.set_deferred("disabled", false)
			
func deactivate_spikes():
	for spike in spikes:
		var anim_sprite = spike.get_node_or_null("AnimatedSprite2D")
		anim_sprite.play_backwards("Animate")

		var collision_shape = spike.get_node_or_null("CollisionShape2D")
		collision_shape.set_deferred("disabled", true)

func combat_lock_room():
	if combat_locked or isFinished:
		return
		
	combat_locked = true
	Events.emit_signal("room_combat_locked")
	var combatLockSound = CombatLockSound.instantiate()
	get_tree().current_scene.add_child(combatLockSound)
	activate_spikes()
	for enemy in enemies:
		if enemy:
			enemy.state = IDLE

func _on_enemy_died() -> void:
	killCount += 1
	if killCount >= killThreshold:
		combat_locked = false
		Events.emit_signal("room_un_combat_locked")
		isFinished = true
		var combatLockSound = CombatLockSound.instantiate()
		get_tree().current_scene.add_child(combatLockSound)
		deactivate_spikes()

func debug_killall() -> void:
	if not combat_locked:
		return
		
	for child in get_children():
		if child.is_in_group("Enemy"):
			enemies.append(child)
			var health_component = child.get_node_or_null("Health_Component")
			health_component.damage(INF)
