extends Node2D
class_name enemyEncounter

@onready var enemies_to_spawn: Node2D = $enemiesToSpawn

var spawned := false
var enemyArray = []
var playerRef : player = null

func spawnEnemies():
	for enemySpawn : enemySpawnPoint in enemies_to_spawn.get_children():
		var spawnedEnemy = enemySpawn.spawnEnemy()
		enemyArray.append(spawnedEnemy)
		spawnedEnemy.playerRef = playerRef
		spawnedEnemy.ai = spawnedEnemy.aiStates.CHASE
		call_deferred("addMyEnemyChild",spawnedEnemy, enemySpawn.global_position)
		
func addMyEnemyChild(spawnedEnemy : Enemy, location : Vector2):
	add_child(spawnedEnemy)
	spawnedEnemy.global_position = location

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug"):
		pass


func _on_player_trigger_body_entered(body: Node2D) -> void:
	if body.get_parent() is player and !spawned:
		playerRef = body.get_parent()
		playerRef.enterCombat()
		spawnEnemies()
		spawned = true
