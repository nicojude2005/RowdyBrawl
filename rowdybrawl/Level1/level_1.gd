extends Node2D
class_name level1

@onready var color_rect: AnimationPlayer = $ColorRect/AnimationPlayer

func _ready() -> void:
	fadeIn()
	
func fadeIn():
	color_rect.play("fadeOut")

func fadeOut():
	color_rect.play("fadeIn")
