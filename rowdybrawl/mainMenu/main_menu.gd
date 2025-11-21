extends Node2D

@onready var timer: Timer = $Timer


func _on_start_pressed() -> void:
	timer.start()

func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()


func loadLevel1():
	get_tree().change_scene_to_file("res://Level1/level_1.tscn")


func _on_timer_timeout() -> void:
	loadLevel1()
