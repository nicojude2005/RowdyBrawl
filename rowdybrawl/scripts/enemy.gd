extends CharacterBody2D
class_name Enemy

@onready var animated_sprite_2d: AnimatedSprite2D = $enemy_hitbox/AnimatedSprite2D
@onready var enemy_hitbox: Area2D = $enemy_hitbox

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

var yPosition : float = 0.0
var yVelocity : float = 0.0 # to handle movement in the (half-fake) Z direction

var jumpTimer : float = 2
var grounded = true                # handles jumping and falling
var jumpVelocity : float = 300      
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity") 

func _physics_process(delta: float) -> void:
	# stun countdown
	if stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			stunned = false
	
	# friction to knockback velocity
	if grounded:
		applyFrictionX()
		applyFrictionY()
	
	if jumpTimer <= 0:
		if grounded:
			jump()
		jumpTimer = 2;
	else:
		jumpTimer -= delta
	
	# Only chase if not stunned
	if chase and playerRef and not stunned and enemy_alive:
		var direction = (playerRef.global_position - global_position).normalized()
		#velocity = direction * speed
		animated_sprite_2d.play("walk")
		animated_sprite_2d.flip_h = global_position.x > playerRef.global_position.x
	else:
		if not stunned:
			#velocity = Vector2.ZERO
			animated_sprite_2d.play("idle")
	
	# Combine movement and knockback
	if !grounded:
		yVelocity -= 9.8
		yPosition += yVelocity
	
	if yPosition <= 0 and !grounded:
		land()
	
#	disables ground collision when high enough in the air
	if yPosition > 500:
		set_collision_layer_value(1, false)
		set_collision_layer_value(2, true)
		
		set_collision_layer_value(5, false)
		set_collision_layer_value(2, true)
	
	if (global_position.y < RenderingServer.CANVAS_ITEM_Z_MAX and global_position.y > RenderingServer.CANVAS_ITEM_Z_MIN):
		animated_sprite_2d.z_index = int(global_position.y)
	
	enemy_hitbox.position.y = -(yPosition / 100)
	
	move_and_slide()

# Called when the player attacks the enemy
func take_hit(damage: int, knockback_dir: Vector2, knockback_strength: float, stun_duration: float) -> void:
	
	health -= damage
	
	
	# Apply knockback and stun
	applyKnockback(knockback_dir,knockback_strength)
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

func jump():
	yVelocity = jumpVelocity
	grounded = false

func land():
	grounded = true
	yVelocity = 0
	yPosition = 0
	set_collision_layer_value(1, true)
	set_collision_layer_value(2, false)
	set_collision_mask_value(5, true)
	set_collision_mask_value(1, false)
	
func applyKnockback(direction : Vector2, strength : float):
	direction = direction.normalized()
	if direction.x != 0:
		velocity.x = direction.x * strength
	if direction.y != 0:
		yVelocity = -direction.y * strength
	if direction.y < 0:
		grounded = false

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
