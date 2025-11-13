extends Node2D
class_name hitBox

var myZIndex
var zReach = 12
@export var damage : float
var duration : float = 10000
var activeAfter : float = 0
var lifeTimer : float = 0
@export var knockbackDir : Vector2 = Vector2.ZERO
@export var knockbackStrength := 0.0
@export var stunDuration := 0.0

var hitEnemies : Array

var userKnockbackOnHitDir : Vector2 = Vector2.ZERO
var userKnockbackOnHitStrength : float = 0.0
var dir = 1

var userRef : Node2D

func zPosCheck(body : Node2D) -> bool:
	var enemyZIndex = body.global_position.y
	if (enemyZIndex < myZIndex + zReach and enemyZIndex > myZIndex - zReach) :
		if body.name != userRef.name and body.get_parent().name != userRef.name:
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
	if targetEnemy.grounded:
		knockbackDir = knockbackDir.normalized()
		targetEnemy.applyKnockback(Vector2(knockbackDir.x * dir,0), knockbackStrength * 10)

func damagePlayer(targetPlayer : player):
	targetPlayer.take_hit(damage, Vector2(knockbackDir.x * dir,knockbackDir.y), knockbackStrength, stunDuration)
	if targetPlayer.grounded:
		knockbackDir = knockbackDir.normalized()
		targetPlayer.applyKnockback(Vector2(knockbackDir.x * dir,0), knockbackStrength * 5)

func _on_hurt_area_area_entered(area: Area2D) -> void:
	var body : Node2D
	if area.name == "enemy_hitbox":
		body = area.get_parent()
		#check for parry
		if body.has_method("can_parry_attack"):
			if body.can_parry_attack(self):
				queue_free()
				return
		if zPosCheck(body) and hitEnemies.find(body) == -1:
			damageEnemy(body)
			hitEnemies.append(body)
			if userKnockbackOnHitDir != Vector2.ZERO and userRef.has_method("applyKnockback"):
				userRef.applyKnockback(userKnockbackOnHitDir, userKnockbackOnHitStrength)
	elif area.get_parent().name == "hitBox":
		body = area.get_parent().get_parent().get_parent()
		if zPosCheck(body.playerBody) and hitEnemies.find(body.playerBody) == -1:
			damagePlayer(body)
			hitEnemies.append(body)
			if userKnockbackOnHitDir != Vector2.ZERO and userRef.has_method("applyKnockback"):
				userRef.applyKnockback(userKnockbackOnHitDir, userKnockbackOnHitStrength)
