extends Node2D
class_name enemyEncounter

@onready var enemies_to_spawn: Node2D = $enemiesToSpawn

var spawned := false
var enemyArray = []
var playerRef : player = null
var flag2 = false

@export var ragTag = 0

var babyCount = 0
var deadCount = 0

@onready var camera_stop_point: cameraStopPoint = $CameraStopPoint
@onready var static_body_2d: StaticBody2D = $StaticBody2D


func spawnEnemies():
	for enemySpawn : enemySpawnPoint in enemies_to_spawn.get_children():
		var spawnedEnemy = enemySpawn.spawnEnemy()
		if spawnedEnemy == null:
			print("YEA spawning enemy error")
			return
		enemyArray.append(spawnedEnemy)
		babyCount += 1
		spawnedEnemy.playerRef = playerRef
		spawnedEnemy.ai = spawnedEnemy.aiStates.CHASE
		call_deferred("addMyEnemyChild",spawnedEnemy, enemySpawn.global_position)
		static_body_2d.set_collision_layer_value(1, true)
		static_body_2d.set_collision_layer_value(2, true)
		static_body_2d.set_collision_layer_value(3, true)
		static_body_2d.set_collision_layer_value(5, true)
		
		
func addMyEnemyChild(spawnedEnemy : Enemy, location : Vector2):
	add_child(spawnedEnemy)
	spawnedEnemy.global_position = location

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug"):
		pass
	
	if spawned and deadCount >= babyCount and !flag2:
		camera_stop_point.freeCamera()
		flag2 = true
		static_body_2d.set_collision_layer_value(1, false)
		static_body_2d.set_collision_layer_value(2, false)
		static_body_2d.set_collision_layer_value(3, false)
		static_body_2d.set_collision_layer_value(5, false)
		if ragTag == 1:
			playerRef.victory()


func _on_player_trigger_body_entered(body: Node2D) -> void:
	if body.get_parent() is player and !spawned:
		playerRef = body.get_parent()
		playerRef.enterCombat()
		spawnEnemies()
		spawned = true
		camera_stop_point.playerRef =body.get_parent()
		camera_stop_point.lockCamera()
