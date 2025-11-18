extends Node2D
class_name player   # the tutorial doesnt talk about this(because technically they arent required), but class_names's are very important
# every script thats attatched to an object should have a class_name (as far as ive learned) 
# this class name will allow us to statically declare references in other scripts
# which is a mouthful, but I think its vital for good code

@onready var playerBody: CharacterBody2D = %playerBody # this grabs a reference to the Player Body, so you can move the player around
@onready var sprite_2d: Sprite2D = $playerBody/hitBox/Sprite2D
@onready var rich_text_label: RichTextLabel = $playerBody/RichTextLabel
@onready var shadow: Sprite2D = $playerBody/shadow
@onready var hit_box: Node2D = $playerBody/hitBox
@onready var sound_track_1: AudioStreamPlayer2D = $playerBody/soundTrack1
@onready var sound_track_2: AudioStreamPlayer2D = $playerBody/soundTrack2

# load up the player attack hitboxes
const LIGHT_ATTACK = preload("uid://cclox11udehj4")
const HEAVY_ATTACK = preload("uid://df6js1m8i34eb")
const AIR_LIGHT_ATTACK = preload("uid://b1mf0xdo3wvpr")
const AIR_HEAVY_ATTACK = preload("uid://c0ttx055igf8n")

# load up the sounds
const JUMP_SOUND_EFFECT = preload("uid://bdhakvk1lh7cu")
const LIGHT_PUNCH_SOUND = preload("uid://01vr24exuxb1")
const HEAVY_PUNCH_SOUND = preload("uid://c81u1r42jntpc")
const LAND_SOUND_EFFECT = preload("uid://c0fokvn508fgs")

var enemy_inattack_range = false
var enemy_attack_cooldown = true
var health = 100
var player_alive = true

var facingDir = 1
var maxSpeed = 200
var accelaration = 20
var airAccelaration = 1
var groundFriction = 15   # these set up basic ground movement
var yReductionPercent = 0.7

var playerYPosition : float = 0.0
var playerYVelocity : float = 0.0 # to handle movement in the (half-fake) Z direction

var grounded = true                # handles jumping and falling
var jumpVelocity : float = 400      
var gravity: int = 9.8

var stun_timer := 0.0

var attackBusyTimer : float = 0
var comboString : String = ""
var comboTimer : float = 0
const comboChainTime : float = 1

func _physics_process(delta: float) -> void:     # _physics_process runs in fixed(very tiny) intervals, regardless of the framerate
												 # This makes it good for movement and physics-based code
	rich_text_label.text = str(health) # temporary 
	
	if attackBusyTimer > 0:
		attackBusyTimer -= delta
	if comboTimer > 0:
		comboTimer -= delta
	if stun_timer > 0:
		stun_timer -= delta
	
	if health <= 0:
		player_alive = false # add end screen or wtv
		health = 0
		print("player has been killed")
		
	# attacks and stuff
	if Input.is_action_just_pressed("lightAttack") and canAttack():
		if grounded:
			doAttackCheckCombos("L")
		else:
			doAttackCheckCombos("A")
		#print(comboString)
		
	elif Input.is_action_just_pressed("heavyAttack") and canAttack():
		if grounded:
			doAttackCheckCombos("H")
		else:
			doAttackCheckCombos("S")
		#print(comboString)
	
#	basic movement across the plane
	if Input.is_action_pressed("left") and canMove():
		flipToDirection(false)
		if playerBody.velocity.x > -maxSpeed:    # Checks if the player's speed to the left is below the max speed, before accelarating in that direction
			if !grounded:
				playerBody.velocity.x -= airAccelaration
			else:
				playerBody.velocity.x -= accelaration
	elif Input.is_action_pressed("right") and canMove():       
		flipToDirection(true)
		if playerBody.velocity.x < maxSpeed:     # Checks if the player's speed to the right is below the max speed, before accelarating in that direction
			if !grounded:
				playerBody.velocity.x += airAccelaration
			else:
				playerBody.velocity.x += accelaration
	if Input.is_action_pressed("up") and canMove():
		if playerBody.velocity.y > (-maxSpeed * yReductionPercent):
			if !grounded:
				playerBody.velocity.y -= airAccelaration * yReductionPercent
			else:
				playerBody.velocity.y -= accelaration * yReductionPercent
	elif Input.is_action_pressed("down") and canMove():
		if playerBody.velocity.y < maxSpeed * yReductionPercent:
			if !grounded:
				playerBody.velocity.y += airAccelaration * yReductionPercent
			else:
				playerBody.velocity.y += accelaration * yReductionPercent
		
		
#	jump shit
	if Input.is_action_just_pressed("jump") and canMove():
		if grounded:
			jump()
		
	
#	z axis logic
	if !grounded:
		playerYVelocity -= gravity
		playerYPosition += playerYVelocity
	else:
		applyFrictionY()
		applyFrictionX()  # this is to slow the player to a stop if they are not holding a direction
	
	if playerYPosition <= 0 and !grounded:
		land()
	
#	disables ground collision when high enough in the air
	if playerYPosition > 500:
		playerBody.collision_mask = 2
		playerBody.collision_layer = 2
	#rich_text_label.text = str(playerBody.collision_mask)
	
#	Z ordering bs to make it LOOK like the player is moving all 3D-like
	if (playerBody.global_position.y < RenderingServer.CANVAS_ITEM_Z_MAX and playerBody.global_position.y > RenderingServer.CANVAS_ITEM_Z_MIN):
		sprite_2d.z_index = int(playerBody.global_position.y)
		
	
	hit_box.position.y = -(playerYPosition / 100)
	
	playerBody.move_and_slide()  # this function is what actually applies the player's velocity to their position. It also does all the collision checks
	
func doAttackCheckCombos(attack : String):
	var currentAttack : hitBox
#	check for a potential next hit of a combo
	if comboTimer > 0:
		comboString += attack
		comboTimer = comboChainTime
		match comboString:
#			flurry of light attacks
			"LL":
				currentAttack = spawnAttack(LIGHT_ATTACK, 2, 0.05, 0.2, 0.0)
				sound_track_1.pitch_scale = 1.3
				playSound(LIGHT_PUNCH_SOUND)
			"LLL":
				currentAttack = spawnAttack(LIGHT_ATTACK, 5, 0.15, 0.2, 0.05)
				applyKnockback(Vector2(facingDir,0), 100)
				playSound(LIGHT_PUNCH_SOUND, 1.7)
				
#			special debug combo to fly forward
			"LLLL":
				currentAttack = spawnAttack(LIGHT_ATTACK, 0, 0,0)
				playSound(LIGHT_PUNCH_SOUND, 2)
			"LLLLL":
				currentAttack = spawnAttack(LIGHT_ATTACK, 0, 0,0)
				playSound(LIGHT_PUNCH_SOUND, 2.3)
			"LLLLLS":
				currentAttack = spawnAttack(AIR_HEAVY_ATTACK, 0, 0,0)
				applyKnockback(Vector2(facingDir,.2), 1000)
				playSound(LIGHT_PUNCH_SOUND, 3)
#			Classic Combo
			"LLH":
				currentAttack = spawnAttack(HEAVY_ATTACK, 10, 0.1, 0.3, 0.2)
				applyKnockback(Vector2(facingDir,0), 200)
				currentAttack.stunDuration = 1
				playSound(HEAVY_PUNCH_SOUND, 0.7)
#			Slam up then down
			"LH":
				currentAttack = spawnAttack(HEAVY_ATTACK, 4, 0.1, 0.1, 0)
				currentAttack.knockbackDir = Vector2(0.2, -1)
				currentAttack.knockbackStrength = 350
				playSound(HEAVY_PUNCH_SOUND, 0.85)
#				knocks enemy up
			"LHA":
				currentAttack = spawnAttack(AIR_LIGHT_ATTACK, 6, 0.2, 0.2, 0)
				playSound(LIGHT_PUNCH_SOUND, 0.8)
			"LHAS":
				currentAttack = spawnAttack(AIR_HEAVY_ATTACK, 14, 0.1, 0.3, 0.4)
				currentAttack.knockbackDir = Vector2(0,1)
				currentAttack.knockbackStrength = 300
				currentAttack.userKnockbackOnHitDir = Vector2(0,1)
				currentAttack.userKnockbackOnHitStrength = currentAttack.knockbackStrength 
				playSound(HEAVY_PUNCH_SOUND, 0.5)
				#KNOCK ENEMY DOWN (TODO)
			_:
				comboString = attack
				letterToAttack(attack)
			
	#	combo timer is zero, just perform a basic light attack
	else:
		comboTimer = comboChainTime
		comboString = attack
		letterToAttack(attack)
	

func letterToAttack(attack):
	var currentAttack : hitBox
	match attack:
		"L":
			# spawn a hitbox in front of the player, with Damage equal to the first number
			# the wind up for the attack is the second number
			# the duration of the hitbox is the third number
			# and the endlag in which the player can not attack after the attack has finished is the last one
			currentAttack = spawnAttack(LIGHT_ATTACK, 3, 0.1, 0.3, 0.1)
			currentAttack.stunDuration = .8
			playSound(LIGHT_PUNCH_SOUND)
		"H":
			# same thing as light attack but with different numbers
			currentAttack = spawnAttack(HEAVY_ATTACK, 8, 0.2, 0.1, 0.1)
			currentAttack.stunDuration = 1
			currentAttack.zReach = 25
			applyKnockback(Vector2(facingDir,0), 100)
			playSound(HEAVY_PUNCH_SOUND)
		"A":
			currentAttack = spawnAttack(AIR_LIGHT_ATTACK, 2, 0.05, 0.25, 0.05)
			currentAttack.userKnockbackOnHitDir = Vector2(0,-1)
			currentAttack.userKnockbackOnHitStrength = 150
			playSound(LIGHT_PUNCH_SOUND)
		"S":
			currentAttack = spawnAttack(AIR_HEAVY_ATTACK, 6, 0.05, 0.3, 0.35)
			currentAttack.knockbackStrength = 200
			currentAttack.knockbackDir = Vector2(0, 1)
			currentAttack.userKnockbackOnHitDir = Vector2(0,-1)
			currentAttack.userKnockbackOnHitStrength = 150
			playSound(HEAVY_PUNCH_SOUND)
		_:
			print("ERROR, UNKNOWN ATTACK REQUESTED")

func flipToDirection(flipToRight : bool):
	if flipToRight and  sprite_2d.flip_h:
		#playerBody.rotation_degrees = 0
		#playerBody.scale.y = 1
		sprite_2d.flip_h = false
		facingDir = 1
	elif !flipToRight and not sprite_2d.flip_h:
		#playerBody.rotation_degrees = 180
		#playerBody.scale.y = -1
		sprite_2d.flip_h = true
		facingDir = -1

func spawnAttack(hitboxToUse : PackedScene, attackDamage : float, attackStartup : float, attackDuration: float, attackEndlag : float = 0.0) -> hitBox:
	var attackHitbox : hitBox = hitboxToUse.instantiate();
	attackHitbox.myZIndex = playerBody.global_position.y
	hit_box.add_child(attackHitbox)
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

func playSound(sound : AudioStream, pitch : float = 1.0, volumedB : float = 0):
	
	if sound_track_1.playing:
		sound_track_2.stream = sound
		sound_track_2.pitch_scale = pitch
		sound_track_2.volume_db = volumedB
		sound_track_2.play()
	else:
		sound_track_1.stream = sound
		sound_track_1.pitch_scale = pitch
		sound_track_1.volume_db = volumedB
		sound_track_1.play()

func canMove() -> bool:
	if stun_timer <= 0 and attackBusyTimer <= 0:
		return true
	else:
		return false
		
func canAttack() -> bool:
	if stun_timer <= 0 and attackBusyTimer <= 0:
		return true
	else:
		return false

func jump():
	playSound(JUMP_SOUND_EFFECT, (randf() * 0.4) + 1, -5)
	playerYVelocity = jumpVelocity
	grounded = false
	#playerBody.collision_mask = 2

func land():
	grounded = true
	playerYVelocity = 0
	playerYPosition = 0
	playerBody.collision_mask = 1
	playerBody.collision_layer = 1
	playSound(LAND_SOUND_EFFECT, (randf() * 0.4) + 1, -15)

func resetSoundPlayer():
	sound_track_1.volume_db = 0.0
	sound_track_1.pitch_scale = 1.0

func applyFrictionX():
	if abs(playerBody.velocity.x) > groundFriction:   # if the player is moving faster than the friction force
		playerBody.velocity.x -= (playerBody.velocity.x / abs(playerBody.velocity.x)) * groundFriction # subtracts friction force opposite of their direction of movement
	else:
		playerBody.velocity.x = 0 
func applyFrictionY():
	if abs(playerBody.velocity.y) > groundFriction * yReductionPercent:   # if the player is moving faster than the friction force
		playerBody.velocity.y -= (playerBody.velocity.y / abs(playerBody.velocity.y)) * groundFriction * yReductionPercent # subtracts friction force opposite of their direction of movement
	else:
		playerBody.velocity.y = 0 
		
func applyKnockback(direction : Vector2, strength : float):
	direction = direction.normalized()
	if direction.x != 0:
		playerBody.velocity.x = direction.x * strength
	if direction.y != 0:
		playerYVelocity = -direction.y * strength
	if direction.y < 0:
		grounded = false
func player():
	pass #used to check if player enters enemies hitbox
	
func take_hit(damage: int, knockback_dir: Vector2, knockback_strength: float, stun_duration: float) -> void:
	health -= damage
	#animation_player.play("hitFlash")
	# Apply knockback and stun
	applyKnockback(knockback_dir,knockback_strength)
	stun_timer = stun_duration
	
	if health <= 0:
		die()

func die():
	pass

func _on_sound_player_finished() -> void:
	resetSoundPlayer()
