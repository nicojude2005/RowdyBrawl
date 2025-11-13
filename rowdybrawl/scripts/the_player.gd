extends Node2D
class_name Player   # the tutorial doesnt talk about this(because technically they arent required), but class_names's are very important
# every script thats attatched to an object should have a class_name (as far as ive learned) 
# this class name will allow us to statically declare references in other scripts
# which is a mouthful, but I think its vital for good code

@onready var playerBody: CharacterBody2D = %playerBody # this grabs a reference to the Player Body, so you can move the player around
@onready var sprite_2d: Sprite2D = $playerBody/hitBox/Sprite2D
@onready var rich_text_label: RichTextLabel = $playerBody/RichTextLabel
@onready var shadow: Sprite2D = $playerBody/shadow
@onready var hit_box: Node2D = $playerBody/hitBox

const LIGHT_ATTACK = preload("uid://cclox11udehj4")
const HEAVY_ATTACK = preload("uid://df6js1m8i34eb")
const AIR_LIGHT_ATTACK = preload("uid://b1mf0xdo3wvpr")
const AIR_HEAVY_ATTACK = preload("uid://c0ttx055igf8n")

var enemy_inattack_range = false
var enemy_attack_cooldown = true
var health = 100
var player_alive = true

var facingDir = 1
var maxSpeed = 200
var accelaration = 20
var groundFriction = 15   # these set up basic ground movement
var yReductionPercent = 0.7

var playerYPosition : float = 0.0
var playerYVelocity : float = 0.0 # to handle movement in the (half-fake) Z direction

var grounded = true                # handles jumping and falling
var jumpVelocity : float = 400      
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity") 

var stun_timer := 0.0

var attackBusyTimer : float = 0
var comboString : String = ""
var validCombos = ["LLH", "LLL", "LHAS"]
var comboTimer : float = 0
const comboChainTime : float = 1


#parry variables
var is_parrying = false
var perfect_parry = false
var parry_timer: float = 0.0

const PARRY_WINDOW: float = 0.3          # total duration
const PERFECT_PARRY_WINDOW: float = 0.1  # timing for “perfect parry”
const PARRY_COOLDOWN: float = 0.5        # parry cooldown



func _physics_process(delta: float) -> void:     # _physics_process runs in fixed(very tiny) intervals, regardless of the framerate
												 # This makes it good for movement and physics-based code
	
	if attackBusyTimer > 0:
		attackBusyTimer -= delta
	if comboTimer > 0:
		comboTimer -= delta
	
	#enemy_attack()
	
	if health <= 0:
		player_alive = false # add end screen or wtv
		health = 0
		print("player has been killed")
		
	
	# attacks and stuff
	if Input.is_action_just_pressed("lightAttack") and attackBusyTimer <= 0:
		if grounded:
			doAttackCheckCombos("L")
		else:
			doAttackCheckCombos("A")
		#print(comboString)
		
	elif Input.is_action_just_pressed("heavyAttack") and attackBusyTimer <= 0:
		if grounded:
			doAttackCheckCombos("H")
		else:
			doAttackCheckCombos("S")
		#print(comboString)
		
	#parry stuff
	elif Input.is_action_just_pressed("Parry") and not is_parrying and attackBusyTimer <= 0:
		start_parry()
	
#	basic movement across the plane
	if Input.is_action_pressed("left"):
		flipToDirection(false)
		if playerBody.velocity.x > -maxSpeed:    # Checks if the player's speed to the left is below the max speed, before accelarating in that direction
			if !grounded:
				playerBody.velocity.x -= accelaration * 0.1
			else:
				playerBody.velocity.x -= accelaration
			
	elif Input.is_action_pressed("right"):       
		flipToDirection(true)
		if playerBody.velocity.x < maxSpeed:     # Checks if the player's speed to the right is below the max speed, before accelarating in that direction
			if !grounded:
				playerBody.velocity.x += accelaration * 0.1
			else:
				playerBody.velocity.x += accelaration

	if Input.is_action_pressed("up"):
		if playerBody.velocity.y > (-maxSpeed * yReductionPercent):
			if !grounded:
				playerBody.velocity.y -= accelaration * yReductionPercent * 0.1
			else:
				playerBody.velocity.y -= accelaration * yReductionPercent
	elif Input.is_action_pressed("down"):
		if playerBody.velocity.y < maxSpeed * yReductionPercent:
			if !grounded:
				playerBody.velocity.y += accelaration * yReductionPercent * 0.1
			else:
				playerBody.velocity.y += accelaration * yReductionPercent
		
		
#	jump shit
	if Input.is_action_just_pressed("jump"):
		if grounded:
			jump()
		
	
#	z axis logic
	if !grounded:
		playerYVelocity -= 9.8
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
	
	#changes sprite color to show when parrying
		if perfect_parry:
		sprite_2d.modulate = Color(0, 1, 1)  # cyan = perfect
	elif is_parrying:
		sprite_2d.modulate = Color(0, 0.5, 1)  # blue = normal parry
	else:
		sprite_2d.modulate = Color(1, 1, 1)  # reset


func doAttackCheckCombos(attack : String):
	var currentAttack : hitBox
#	check for a potential next hit of a combo
	if comboTimer > 0:
		comboString += attack
		comboTimer = comboChainTime
		print(comboString)
		match comboString:
#			flurry of light attacks
			"LL":
				currentAttack = spawnAttack(LIGHT_ATTACK, 0.2, 0.1, 10)
			"LLL":
				currentAttack = spawnAttack(LIGHT_ATTACK, 0.15, 0.1, 10)
				applyKnockback(Vector2(facingDir,0), 100)
				
#			special debug combo to fly forward
			"LLLL":
				currentAttack = spawnAttack(LIGHT_ATTACK, 0, 0,0)
			"LLLLL":
				currentAttack = spawnAttack(LIGHT_ATTACK, 0, 0,0)
			"LLLLLS":
				currentAttack = spawnAttack(AIR_HEAVY_ATTACK, 0, 0,0)
				applyKnockback(Vector2(facingDir,.2), 1000)
#			Classic Combo
			"LLH":
				currentAttack = spawnAttack(HEAVY_ATTACK, 0.3, 0.4, 20)
				applyKnockback(Vector2(facingDir,0), 200)
				currentAttack.stunDuration = 1
#			Slam up then down
			"LH":
				currentAttack = spawnAttack(HEAVY_ATTACK, 0.2, 0.4, 20)
				currentAttack.knockbackDir = Vector2(0, -1)
				currentAttack.knockbackStrength = 350
				#KNOCK ENEMY UP (TODO)
			"LHA":
				currentAttack = spawnAttack(AIR_LIGHT_ATTACK, 0.2, 0.3, 10)
			"LHAS":
				currentAttack = spawnAttack(AIR_HEAVY_ATTACK, 0.6, 0.7, 50)
				currentAttack.knockbackDir = Vector2(0,1)
				currentAttack.knockbackStrength = 300
				currentAttack.userKnockbackOnHitDir = Vector2(0,1)
				currentAttack.userKnockbackOnHitStrength = currentAttack.knockbackStrength 
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
			# spawn a hitbox in front of the player, for a Duration equal to the first number
			# and it has the size and position that is defined in LIGHT_ATTACK
			# Second number denotes how long the player is stuck in the attack animation
			# Third number denotes the damage amount
			currentAttack = spawnAttack(LIGHT_ATTACK, 0.15, 0.2, 10)
		"H":
			# same thing as light attack but with different numbers
			currentAttack = spawnAttack(HEAVY_ATTACK, 0.4, 0.5, 20)
			applyKnockback(Vector2(facingDir,0), 100)
		"A":
			currentAttack = spawnAttack(AIR_LIGHT_ATTACK, 0.10, 0.15, 8)
			currentAttack.userKnockbackOnHitDir = Vector2(0,-1)
			currentAttack.userKnockbackOnHitStrength = 150
		"S":
			currentAttack = spawnAttack(AIR_HEAVY_ATTACK, 0.3, 0.4, 16)
			currentAttack.userKnockbackOnHitDir = Vector2(0,-1)
			currentAttack.userKnockbackOnHitStrength = 150
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

func spawnAttack(hitboxToUse : PackedScene, attackDuration : float, attackEndlag : float, attackDamage: float) -> hitBox:
	var attackHitbox : hitBox = hitboxToUse.instantiate();
	attackHitbox.myZIndex = playerBody.global_position.y
	hit_box.add_child(attackHitbox)
	attackHitbox.damage = attackDamage
	attackHitbox.dir = facingDir
	if facingDir == -1:
		attackHitbox.rotation_degrees = 180
		attackHitbox.scale.y = -1
	attackHitbox.userRef = self
	
	attackHitbox.duration = attackDuration
	attackBusyTimer = attackEndlag
	
	return attackHitbox

func jump():
	playerYVelocity = jumpVelocity
	grounded = false
	#playerBody.collision_mask = 2

func land():
	grounded = true
	playerYVelocity = 0
	playerYPosition = 0
	playerBody.collision_mask = 1
	playerBody.collision_layer = 1

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

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("enemy"):
		enemy_inattack_range = true
	
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.has_method("enemy"):
		enemy_inattack_range = false
		
		
func take_hit(damage: int, knockback_dir: Vector2, knockback_strength: float, stun_duration: float) -> void:
	#check if parrying first
	if is_parrying:
		print("Blocked damage!")
	elif enemy_inattack_range and enemy_attack_cooldown:
		health -= damage
		#animation_player.play("hitFlash")
		# Apply knockback and stun
		applyKnockback(knockback_dir,knockback_strength)
		stun_timer = stun_duration
	
	if health <= 0:
		die()

func die():
	pass
		
func _on_enemy_attack_cooldown_timer_timeout() -> void:
	enemy_attack_cooldown = true

#this is where the parrying happens
func start_parry() -> void:
	is_parrying = true
	perfect_parry = true
	parry_timer = PARRY_WINDOW
	attackBusyTimer = PARRY_WINDOW  # lock movement/attacks during parry
	print("Parry started")

	# Perfect parry window
	await get_tree().create_timer(PERFECT_PARRY_WINDOW).timeout
	perfect_parry = false
	print("Perfect parry window ended")

	# Rest of parry duration
	await get_tree().create_timer(PARRY_WINDOW - PERFECT_PARRY_WINDOW).timeout
	is_parrying = false
	print("Parry ended")

func handle_parry(enemy_attack):
	# direction check
	var dir_to_attack = (enemy_attack.global_position - playerBody.global_position).x
	if sign(dir_to_attack) != facingDir:
		print("Parry failed (attack from behind)")
		enemy_attack()
		return

	if perfect_parry:
		print("✨ PERFECT PARRY ✨")
		do_slow_mo()
		# Knockback enemy, play spark, etc.
		if enemy_attack.has_method("on_parried"):
			enemy_attack.on_parried(true)
	else:
		print("Parry success")
		if enemy_attack.has_method("on_parried"):
			enemy_attack.on_parried(false)

func do_slow_mo():
	Engine.time_scale = 0.2
	await get_tree().create_timer(0.15, true, false, 0.15).timeout  # real-time timer
	Engine.time_scale = 1.0
