extends Node2D

@onready var headAnimationPlayer = $Head/HeadAnimationPlayer
@onready var bodyAnimationPlayer = $Body/BodyAnimationPlayer
@onready var tailAnimationPlayer = $Tail/TailAnimationPlayer
@onready var activeTimer = $ActiveTimer
@onready var cooldownTimer = $CooldownTimer

@export var stats: Stats

var ACTIVE_LENGTH := 3.0
var COOLDOWN_LENGTH := 3.0

func _ready() -> void:
	start()

func start():
	activeTimer.start(ACTIVE_LENGTH)
	headAnimationPlayer.play("Start")
	bodyAnimationPlayer.play("Start")
	tailAnimationPlayer.play("Start")

func start_animation_finished():
	tailAnimationPlayer.play("Active")

func _on_active_timer_timeout() -> void:
	headAnimationPlayer.play("End")
	bodyAnimationPlayer.play("End")
	tailAnimationPlayer.play("End")
	cooldownTimer.start(COOLDOWN_LENGTH)

func _on_cooldown_timer_timeout() -> void:
	start()
