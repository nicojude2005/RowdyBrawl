extends Node2D
class_name enemySpawnPoint

@export var enemyToSpawn : PackedScene = null
var parentEnemyEncounter : enemyEncounter
var enterFromTop : bool = true

func spawnEnemy() -> Enemy:
	if enemyToSpawn == null:
		print("ERROR: tried to spawn enemy, but none was provided")
		return
	
	var spawnedEnemy = enemyToSpawn.instantiate()
	return spawnedEnemy
