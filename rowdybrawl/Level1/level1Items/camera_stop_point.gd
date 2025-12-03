extends Node2D
class_name cameraStopPoint
@onready var left_side_lock: Node2D = $leftSideLock
@onready var right_side_lock: Node2D = $rightSideLock

var playerRef : player
var triggerHit = false

@export var leftLockOffset : float = 100
@export var rightLockOffset : float = 100

var tempTimer := 0.0

func _on_player_detector_body_entered(body: Node2D) -> void:
	pass
	#if body.get_parent().has_method("player") and triggerHit == false:
		#triggerHit = true
		#playerRef = body.get_parent()
		#lockCamera()
		#tempTimer = 10

func lockCamera():
	if playerRef == null:
		print("ERROR: lock camera called when no player ref set")
		return
	playerRef.camera_controller.leftSideStop = global_position.x - leftLockOffset
	playerRef.camera_controller.rightSideStop = global_position.x + rightLockOffset

func freeCamera():
	if playerRef == null:
		return
	
	playerRef.camera_controller.leftSideStop = playerRef.camera_controller.leftOfStage
	playerRef.camera_controller.rightSideStop = playerRef.camera_controller.rightOfStage
