extends CharacterBody2D
class_name Enemy

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var speed = 45
var playerRef: Node2D = null
var chase = false
var health = 100
var enemy_alive = true

var yReductionAmount = 0.7

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
	
	# friction to knockback velocity
	applyFrictionX()
	applyFrictionY()
	
	# Only chase if not stunned
	if chase and playerRef and not stunned:
		var direction = (playerRef.global_position - global_position).normalized()
		velocity = direction * speed
		animated_sprite_2d.play("walk")
		animated_sprite_2d.flip_h = global_position.x > playerRef.global_position.x
	else:
		if not stunned:
			#velocity = Vector2.ZERO
			animated_sprite_2d.play("idle")
	
	# Combine movement and knockback
	
	
	move_and_slide()

# Called when the player attacks the enemy
func take_hit(damage: int, knockback_dir: Vector2, knockback_strength: float, stun_duration: float) -> void:
	
	health -= damage
	
	
	# Apply knockback and stun
	velocity = knockback_dir.normalized() * knockback_strength
	stunned = true
	stun_timer = stun_duration
	
	if health <= 0:
		die()
	

func die():
	enemy_alive = false
	health = 0
	print("enemy has been killed")

func _on_detection_area_body_entered(body: Node2D) -> void:
	playerRef= body
	chase = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	playerRef= null
	chase = false

func applyFrictionX():
	if abs(velocity.x) > friction:   # if the player is moving faster than the friction force
		velocity.x -= (velocity.x / abs(velocity.x)) * friction # subtracts friction force opposite of their direction of movement
	else:
		velocity.x = 0 
	
func applyFrictionY():
	if abs(velocity.y) > friction:   # if the player is moving faster than the friction force
		velocity.y -= (velocity.y / abs(velocity.y)) * friction * yReductionAmount# subtracts friction force opposite of their direction of movement
	else:
		velocity.y = 0 
func enemy():
	pass # used for player hitbox checks
