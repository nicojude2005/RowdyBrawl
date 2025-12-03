extends CharacterBody2D
class_name Enemy

# import some nodes for messin' with
@onready var animated_sprite_2d: AnimatedSprite2D = $enemy_hitbox/AnimatedSprite2D
@onready var enemy_hitbox: Area2D = $enemy_hitbox
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var enemy_collision: CollisionShape2D = $enemyCollision
@onready var stun_indicator: Sprite2D = $enemy_hitbox/stunIndicator
@onready var sound_track_1: AudioStreamPlayer2D = $soundTrack1
@onready var sprite_2d: Sprite2D = $Sprite2D

# load some hitboxes for use
@onready var ENEMY_EXAMPLE_ATTACK = load("uid://d3g686l1tme5q")
# load sounds
@onready var ENEMY_DIE_SOUND_EFFECT_DEFAULT = load("uid://bksdr80lhktaq")


# movement
@export var maxSpeed : float = 100
@export var accelaration : float 
var friction: float = 10.0
var yReductionAmount = 0.7
var facingDir = 1

# movement Z direction
var yPosition : float = 0.0
var yVelocity : float = 0.0        # to handle movement in the (half-fake) Z direction
var grounded = true                # handles jumping and falling
var jumpVelocity : float = 300      
var gravity: float = 9.8

var airTimer := 0.0  # to make it harder to permanantly air lock enemies
var weightIncrease := 0.0

# movement for chasing
var moveDirection : Vector2
var targetPos = Vector2.ZERO

var playerRef: player = null
enum aiStates {IDLE, CHASE, ATTACK}
var ai = aiStates.IDLE
var goRight := randi_range(0,1)

# getting attacked
var knockback_velocity: Vector2 = Vector2.ZERO
var stun_timer: float = 0.0
var health = 100
var enemy_alive = true
var removeTimer := 3.0

var armorTimer := 0.0

# attacking
var attackBusyTimer : float = 0.0
var hitRate : float = .45
var hitTimer : float = hitRate

func _ready() -> void:
	sound_track_1.play()
	animation_player.play("spawnIN")
	stun_timer = 1

func _physics_process(delta: float) -> void:
	# stun countdown
	if stun_timer > 0 and grounded:
		stun_timer -= delta
	elif stun_timer <= 0 and stun_indicator.visible:
		stun_indicator.visible = false
	# remove from scene countdown
	if !enemy_alive:
		removeTimer -= delta
		if removeTimer <= 0:
			removeFromScene()
			
	if attackBusyTimer > 0:
		attackBusyTimer -= delta
	
	# friction to knockback velocity
	if grounded:
		applyFrictionX()
		applyFrictionY()
	
	# make the enemy fall when in air
	if airTimer >= 3:
		weightIncrease += delta * 2
	
	if !grounded:
		yVelocity -= gravity + weightIncrease
		yPosition += yVelocity
		airTimer += delta
	
	if yPosition <= 0 and !grounded:
		land()
	
#	disables ground collision when high enough in the air
	if yPosition > 500:
		#set_collision_layer_value(1, false)
		#set_collision_layer_value(2, true)
		
		set_collision_layer_value(5, false)
		set_collision_layer_value(2, true)
	
	if (global_position.y < RenderingServer.CANVAS_ITEM_Z_MAX and global_position.y > RenderingServer.CANVAS_ITEM_Z_MIN):
		animated_sprite_2d.z_index = int(global_position.y)
		sprite_2d.z_index =  int(global_position.y) - 1
	
	enemy_hitbox.position.y = -(yPosition / 100)
	
	if stun_timer <= 0:
		if isCloseToTarget() and ai == aiStates.CHASE:
			ai = aiStates.ATTACK
			targetPos = Vector2.ZERO
			# make the enemy enter an attacking state
			# change ai to be an Enum that will sorta decide the ai actions	
		match ai:
			aiStates.IDLE:
				aiIdleFunction()
			aiStates.CHASE:
				aiChaseFunction()
			aiStates.ATTACK:
				aiAttackFunction(delta)
	
	if targetPos != Vector2.ZERO:
		moveDirection = (targetPos - global_position).normalized()
	else:
		moveDirection = Vector2.ZERO
		
	if moveDirection != Vector2.ZERO and grounded and canMove():
		accelarateInDirection()
	
	move_and_slide()


# Combat attacking stuff
func spawnAttack(hitboxToUse : PackedScene, attackDamage : float, attackStartup : float, attackDuration: float, attackEndlag : float = 0.0, customAttachSlot = enemy_hitbox) -> hitBox:
	var attackHitbox : hitBox = hitboxToUse.instantiate();
	attackHitbox.myZIndex = self.global_position.y
	customAttachSlot.add_child(attackHitbox)
	attackHitbox.activeAfter = attackStartup
	attackHitbox.damage = attackDamage
	attackHitbox.dir = facingDir
	if facingDir == -1:
		attackHitbox.rotation_degrees = 180
		attackHitbox.scale.y = -1
	attackHitbox.userRef = self
	
	attackHitbox.duration = attackDuration + attackStartup
	attackBusyTimer = attackStartup + attackDuration + attackEndlag
	
	return attackHitbox
func take_hit(damage: int, knockback_dir: Vector2, knockback_strength: float, stun_duration: float, attacker : Node2D = null) -> void:
	health -= damage
	animation_player.play("hurt")
	# Apply knockback and stun
	if armorTimer <= 0:
		applyKnockback(knockback_dir,knockback_strength)
	
	if stun_duration > stun_timer:
		ai = aiStates.CHASE
		goRight = randi_range(0,1)
		stun_indicator.visible = true
		stun_timer = stun_duration
	
	if health <= 0:
		die()
func applyKnockback(direction : Vector2, strength : float):
	direction = direction.normalized()
	if direction.x != 0:
		velocity.x = direction.x * strength
	if direction.y != 0:
		yVelocity = -direction.y * strength
	if direction.y < 0:
		grounded = false
func die():
	if !enemy_alive:
		return
	enemy_alive = false
	health = 0
	if get_parent() is enemyEncounter:
		get_parent().deadCount += 1
	elif get_parent().get_parent() is enemyEncounter:
		get_parent().get_parent().deadCount += 1
	elif get_parent().get_parent().get_parent() is enemyEncounter:
		get_parent().get_parent().get_parent().deadCount += 1
	else:
		print("i failed....")
	applyKnockback(Vector2(.3,-1), 5000)
	playSound(ENEMY_DIE_SOUND_EFFECT_DEFAULT, 0.3, 1)
	enemy_collision.set_deferred("disabled", true)		
func removeFromScene():
	call_deferred("queue_free")

# movement stuff
func applyFrictionX():
	if abs(velocity.x) > friction:   # if the player is moving faster than the friction force
		velocity.x -= (velocity.x / abs(velocity.x)) * friction # subtracts friction force opposite of their direction of movement
	else:
		velocity.x = 0 
func applyFrictionY():
	if abs(velocity.y) > friction * yReductionAmount:   # if the player is moving faster than the friction force
		velocity.y -= (velocity.y / abs(velocity.y)) * friction * yReductionAmount# subtracts friction force opposite of their direction of movement
	else:
		velocity.y = 0 

func jump():
	if grounded:
		yVelocity = jumpVelocity
		grounded = false
func land():
	
	if yVelocity < -180 and stun_timer > 0:
		grounded = false
		yVelocity = -yVelocity * 0.7
		
	else:
		grounded = true
		yVelocity = 0
		airTimer = 0
		weightIncrease = 0
	yPosition = 0
	#set_collision_layer_value(1, true)
	#set_collision_layer_value(2, false)
	set_collision_mask_value(5, true)
	set_collision_mask_value(1, false)

func canAttack() -> bool:
	if stun_timer <= 0 and attackBusyTimer <= 0:
		return true
	else:
		return false
func canMove() -> bool:
	if stun_timer <= 0 and attackBusyTimer <= 0:
		return true
	else:
		return false
# ai brain stuff
func accelarateInDirection():
	if abs((moveDirection.x * (accelaration + friction)) + velocity.x) <= maxSpeed:
		velocity.x += moveDirection.x * (accelaration + friction)
		if playerRef.playerBody.global_position.x - global_position.x < 0:
			facingDir = -1
		else:
			facingDir = 1
	
	if abs((moveDirection.y * (accelaration + friction)) + velocity.y) <= maxSpeed * yReductionAmount:
		velocity.y += moveDirection.y * (accelaration + friction) * yReductionAmount

func aiIdleFunction():
	pass
func aiChaseFunction():
	if playerRef != null:
		targetPos.y = playerRef.playerBody.global_position.y
		if !goRight:
			targetPos.x = playerRef.playerBody.global_position.x - 50 # offset so that they can hit the player easier
		else:
			targetPos.x = playerRef.playerBody.global_position.x + 50
func aiAttackFunction(delta :float):
	hitTimer -= delta
	#targetPos = playerRef.playerBody.global_position
#	uncomment the line above if you wanna see what EXTRA HARD enemies could act like
	if hitTimer <= 0:
		if playerRef.playerYPosition > yPosition:
			jump()
		if canAttack():
			spawnAttack(ENEMY_EXAMPLE_ATTACK, 10, 0.4, 0.5, 1.2)
			hitTimer = hitRate
			ai = aiStates.CHASE
			goRight = randi_range(0,1)

	if (playerRef.playerBody.global_position - global_position).length() > 300:
		ai = aiStates.CHASE
		hitTimer = hitRate
		goRight = randi_range(0,1)

func isCloseToTarget(range : float = 15) -> bool:
	var dist : float = (targetPos - global_position).length()
	
	if dist < range:
		return true
	else:
		return false


# misc
func playSound(sound : AudioStream, pitch : float = 1.0, volumedB : float = 0):
	var playback : AudioStreamPlaybackPolyphonic = sound_track_1.get_stream_playback()
	playback.play_stream(sound, 0, volumedB,pitch)
func resetSoundTrack():
	sound_track_1.volume_db = 0.0
	sound_track_1.pitch_scale = 1.0

# node triggered things
func _on_sound_track_1_finished() -> void:
	resetSoundTrack()
func _on_detection_area_body_entered(body: Node2D) -> void:
	sound_track_1.play()
	if body.get_parent() is player:
		playerRef = body.get_parent()
		playerRef.enterCombat()
		ai = aiStates.CHASE
		goRight = randi_range(0,1)
