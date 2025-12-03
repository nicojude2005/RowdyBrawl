extends Node2D

@onready var timer: Timer = $Timer
@onready var color_rect: AnimationPlayer = $ColorRect/AnimationPlayer


func _on_start_pressed() -> void:
	timer.start()
	color_rect.get_parent().show()
	color_rect.play("fadeIn")

func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()


func loadLevel1():
	get_tree().change_scene_to_file("res://Level1/level_1.tscn")


func _on_timer_timeout() -> void:
	loadLevel1()
