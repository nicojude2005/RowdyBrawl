extends Node2D
class_name hitBox

var myZIndex
var zReach = 5
@export var damage : float
var duration : float = 10000
var activeAfter : float = 0
var lifeTimer : float = 0
var knockbackDir : Vector2 = Vector2.ZERO
var knockbackStrength = 0
var stunDuration = 0

func _on_hurt_area_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	var enemyZIndex = 0
	print("anything")
	if (enemyZIndex < myZIndex + zReach and enemyZIndex > myZIndex - zReach) and lifeTimer >= activeAfter:
		print("thing in range")
		if body.has_method("enemy") and body.name != self.get_parent().name:
			print("ebeny ")
			damageEnemy(body)

func _process(delta: float) -> void:
	lifeTimer += delta
	
	if duration <= 0:
		removeSelf()
	else:
		duration -= delta

func removeSelf():
	self.queue_free()

func damageEnemy(targetEnemy : Enemy):
	targetEnemy.take_hit(damage,knockbackDir, knockbackStrength, stunDuration)
