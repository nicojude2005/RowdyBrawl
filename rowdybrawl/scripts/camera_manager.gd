extends Node2D
class_name cameraController

@onready var playerReference : player = self.get_parent()
@onready var camera2d: Camera2D = $Camera2D

func _process(_delta: float) -> void:
	camera2d.position.x = playerReference.playerBody.position.x
	
