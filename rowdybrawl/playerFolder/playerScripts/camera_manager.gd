extends Node2D
class_name cameraController

@onready var playerReference : player = self.get_parent()
@onready var camera2d: Camera2D = $Camera2D

#reminder that smaller values correspond to higher up on the screen
var topLimit := -70
var bottomLimit := 20.0

var topOfStage := -167.0
var bottomOfStage := 300.0

var leftOfStage := 100.0
var rightOfStage := 3700.0

var leftSideStop := 100.0
var rightSideStop := 3700.0

var trackPos : Vector2 

var stop = false

func _process(_delta: float) -> void:
	
	if stop:
		trackPos
	else:
		trackPos = playerReference.hit_box.global_position
	 
	if trackPos.x > leftSideStop and trackPos.x < rightSideStop:
		camera2d.position.x = trackPos.x
	
	if trackPos.y > topOfStage and trackPos.y < bottomOfStage:
		camera2d.position.y = lerpf(topLimit, bottomLimit, (trackPos.y - topOfStage) / (bottomOfStage - topOfStage))
		#camera2d.position.y = trackPos.y
		
