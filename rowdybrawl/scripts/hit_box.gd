extends Node2D
class_name hitBox

var myZIndex
var zReach = 12
@export var damage : float
var duration : float = 10000
var activeAfter : float = 0
var lifeTimer : float = 0
@export var knockbackDir : Vector2 = Vector2.ZERO
@export var knockbackStrength = 0
@export var stunDuration = 0
var dir = 1



func zPosCheck(body : Node2D) -> bool:
	var enemyZIndex = body.global_position.y
	#print(str(enemyZIndex) + "\n")
	#print(str(myZIndex) + "\n")
	if (enemyZIndex < myZIndex + zReach and enemyZIndex > myZIndex - zReach) :
		if body.has_method("enemy") and body.name != self.get_parent().name:
			return true
			
	return false

func _process(delta: float) -> void:
	lifeTimer += delta
	
	if duration <= 0:
		removeSelf()
	else:
		duration -= delta

func removeSelf():
	self.queue_free()

func damageEnemy(targetEnemy : Enemy):
	targetEnemy.take_hit(damage,Vector2(knockbackDir.x * dir,knockbackDir.y), knockbackStrength, stunDuration)


func _on_hurt_area_area_entered(area: Area2D) -> void:
	var body : Enemy
	if area.name == "enemy_hitbox":
		body = area.get_parent()
		if zPosCheck(body):
			damageEnemy(body)
		
