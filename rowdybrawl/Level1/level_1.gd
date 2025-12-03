extends Node2D
class_name level1

@onready var fade_transition: ColorRect = $fadeTransition

func fadeIntoLevel():
	fade_transition.show()
	fade_transition.get_child(0).play("fadeIn")
	
func _ready() -> void:
	fadeIntoLevel()
