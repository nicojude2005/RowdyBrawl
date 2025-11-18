extends Enemy
class_name canvas_enemy

# Custom stats for canvas enemy
var damage: int = 20
var base_speed: float = 25   # slower 
var attack_cooldown: float = 3.0  # slower 

func _ready() -> void:
	# Override base health and speed
	
	health = 200
	#maxSpeed = base_speed

func _physics_process(delta: float) -> void:
	## Update target position based on player
	#if playerRef != null and enemy_alive and stun_timer <= 0:
		#targetPos.y = playerRef.playerBody.global_position.y
		#if global_position.x < playerRef.playerBody.global_position.x:
			#targetPos.x = playerRef.playerBody.global_position.x - 50  # offset so it can attack
		#else:
			#targetPos.x = playerRef.playerBody.global_position.x + 50
	#else:
		#targetPos = Vector2.ZERO
#
	## Calculate move direction
	#if targetPos != Vector2.ZERO:
		#moveDirection = (targetPos - global_position).normalized()
	#else:
		#moveDirection = Vector2.ZERO
#
	## Apply movement based on canvas_enemy stats
	#if moveDirection != Vector2.ZERO:
		#accelerateInDirection()
#
	## Animate sprite
	#if moveDirection.x != 0:
		#animated_sprite_2d.play("walk")
		#animated_sprite_2d.flip_h = moveDirection.x < 0
	#else:
		#animated_sprite_2d.play("idle")

	super._physics_process(delta)  # call base physics process

func aiAttackFunction(delta :float):
	#hitTimer -= delta
	#if hitTimer <= 0:
		#hitTimer = hitRate
		#ai = aiStates.CHASE
	super.aiAttackFunction(delta)

# Accelerate enemy using custom speed/acceleration
#func accelerateInDirection():
	#if abs((moveDirection.x * accelaration) + velocity.x) <= maxSpeed:
		#velocity.x += moveDirection.x * accelaration
	#
	#if abs((moveDirection.y * accelaration) + velocity.y) <= maxSpeed * yReductionAmount:
		#velocity.y += moveDirection.y * accelaration * yReductionAmount
