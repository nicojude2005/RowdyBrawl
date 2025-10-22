extends CharacterBody2D
class_name Enemy

var speed = 45
var playerRef: Node2D = null
var chase = false
var health = 100
var enemy_alive = true

var knockback_velocity: Vector2 = Vector2.ZERO
var friction: float = 300.0
var stunned: bool = false
var stun_timer: float = 0.0

func _physics_process(delta: float) -> void:
	# stun countdown
	if stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			stunned = false
	
	if health <= 0:
		enemy_alive = false
		health = 0
		print("enemy has been killed")
	# friction to knockback velocity
	if knockback_velocity.length() > 0.1:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, friction * delta)
	else:
		knockback_velocity = Vector2.ZERO
	
	# Only chase if not stunned
	if chase and playerRef and not stunned:
		var direction = (playerRef.global_position - global_position).normalized()
		velocity = direction * speed
		$AnimatedSprite2D.play("walk")
		$AnimatedSprite2D.flip_h = global_position.x > playerRef.global_position.x
	else:
		if not stunned:
			velocity = Vector2.ZERO
			$AnimatedSprite2D.play("idle")
	
	# Combine movement and knockback
	velocity += knockback_velocity * delta
	
	move_and_slide()

# Called when the player attacks the enemy
func take_hit(damage: int, knockback_dir: Vector2, knockback_strength: float, stun_duration: float) -> void:
	
	health -= damage
	print("Enemy took", damage, "damage. Health =", health)
	
	# Apply knockback and stun
	knockback_velocity = knockback_dir.normalized() * knockback_strength
	stunned = true
	stun_timer = stun_duration
	

func _on_detection_area_body_entered(body: Node2D) -> void:
	playerRef= body
	chase = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	playerRef= null
	chase = false

func enemy():
	pass # used for player hitbox checks
