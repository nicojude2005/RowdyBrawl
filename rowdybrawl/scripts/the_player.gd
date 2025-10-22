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
@onready var enemy_attack_cooldown_timer: Timer = $playerBody/enemy_attack_cooldown_timer

const LIGHT_ATTACK = preload("uid://cclox11udehj4")
const HEAVY_ATTACK = preload("uid://df6js1m8i34eb")
const AIR_LIGHT_ATTACK = preload("uid://b1mf0xdo3wvpr")
const AIR_HEAVY_ATTACK = preload("uid://c0ttx055igf8n")

var enemy_inattack_range = false
var enemy_attack_cooldown = true
var health = 100
var player_alive = true


var maxSpeed = 100
var accelaration = 20
var groundFriction = 10      # these set up basic ground movement
var yReductionPercent = 0.7

var playerYPosition : float = 0.0
var playerYVelocity : float = 0.0 # to handle movement in the (half-fake) Z direction

var grounded = true                # handles jumping and falling
var jumpVelocity : float = 300      
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity") 

var attackBusyTimer : float = 0
var comboString : String = ""
var validCombos = ["LLH", "LLL", "LHAS"]
var comboTimer : float = 0
const comboChainTime : float = 1

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
	
#	basic movement across the plane
	if Input.is_action_pressed("left"):
		flipToDirection(false)
		if playerBody.velocity.x > -maxSpeed:    # Checks if the player's speed to the left is below the max speed, before accelarating in that direction
			playerBody.velocity.x -= accelaration
			
	elif Input.is_action_pressed("right"):       
		flipToDirection(true)
		if playerBody.velocity.x < maxSpeed:     # Checks if the player's speed to the right is below the max speed, before accelarating in that direction
			playerBody.velocity.x += accelaration
	else:
		applyFrictionX()  # this is to slow the player to a stop if they are not holding a direction
	if Input.is_action_pressed("up"):
		if playerBody.velocity.y > -maxSpeed * yReductionPercent:
			playerBody.velocity.y -= accelaration * yReductionPercent
	elif Input.is_action_pressed("down"):
		if playerBody.velocity.y < maxSpeed * yReductionPercent:
			playerBody.velocity.y += accelaration * yReductionPercent
	else:
		applyFrictionY()
		
#	jump shit
	if Input.is_action_just_pressed("jump"):
		if grounded:
			jump()
		
	
#	z axis logic
	if !grounded:
		playerYVelocity -= 9.8
		playerYPosition += playerYVelocity
	
	if playerYPosition <= 0 and !grounded:
		land()
	
#	disables ground collision when high enough in the air
	if playerYPosition > 2500:
		playerBody.collision_mask = 2
	#rich_text_label.text = str(playerBody.collision_mask)
	
#	Z ordering bs to make it LOOK like the player is moving all 3D-like
	if (playerBody.global_position.y < RenderingServer.CANVAS_ITEM_Z_MAX and playerBody.global_position.y > RenderingServer.CANVAS_ITEM_Z_MIN):
		sprite_2d.z_index = int(playerBody.global_position.y)
		
	
	hit_box.position.y = -(playerYPosition / 100)
	
	playerBody.move_and_slide()  # this function is what actually applies the player's velocity to their position. It also does all the collision checks
	

func doAttackCheckCombos(attack : String):
#	check for a potential next hit of a combo
	if comboTimer > 0:
		comboString += attack
		comboTimer = comboChainTime
		match comboString:
#			flurry of light attacks
			"LL":
				spawnAttack(LIGHT_ATTACK, 0.2, 0.1, 10)
			"LLL":
				spawnAttack(LIGHT_ATTACK, 0.15, 0.1, 10)
#			Classic Combo
			"LLH":
				spawnAttack(HEAVY_ATTACK, 0.3, 0.4, 20)
				#STUN ENEMY (TODO)
#			Slam up then down
			"LH":
				spawnAttack(HEAVY_ATTACK, 0.2, 0.4, 20)
				#KNOCK ENEMY UP (TODO)
			"LHA":
				spawnAttack(AIR_LIGHT_ATTACK, 0.2, 0.3, 10)
			"LHAS":
				spawnAttack(AIR_HEAVY_ATTACK, 0.6, 0.7, 50)
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
	match attack:
		"L":
			# spawn a hitbox in front of the player, for a Duration equal to the first number
			# and it has the size and position that is defined in LIGHT_ATTACK
			# Second number denotes how long the player is stuck in the attack animation
			# Third number denotes the damage amount
			spawnAttack(LIGHT_ATTACK, 0.15, 0.2, 10)
		"H":
			# same thing as light attack but with different numbers
			spawnAttack(HEAVY_ATTACK, 0.4, 0.5, 20)
		"A":
			spawnAttack(AIR_LIGHT_ATTACK, 0.10, 0.15, 8)
		"S":
			spawnAttack(AIR_HEAVY_ATTACK, 0.3, 0.4, 16)
		_:
			print("ERROR, UNKNOWN ATTACK REQUESTED")

func flipToDirection(flipToRight : bool):
	if flipToRight and playerBody.scale.y < 1:
		playerBody.rotation_degrees = 0
		playerBody.scale.y = 1
	elif !flipToRight and playerBody.scale.y > -1:
		playerBody.rotation_degrees = 180
		playerBody.scale.y = -1

func spawnAttack(hitboxToUse : PackedScene, attackDuration : float, attackEndlag : float, attackDamage: float):
	var attackHitbox : hitBox = hitboxToUse.instantiate();
	attackHitbox.myZIndex = playerBody.position.y
	hit_box.add_child(attackHitbox)
	attackHitbox.damage = attackDamage
	
	attackHitbox.duration = attackDuration
	attackBusyTimer = attackEndlag

func jump():
	playerYVelocity = jumpVelocity
	grounded = false
	#playerBody.collision_mask = 2

func land():
	grounded = true
	playerYVelocity = 0
	playerYPosition = 0
	playerBody.collision_mask = 1

func applyFrictionX():
	if abs(playerBody.velocity.x) > groundFriction:   # if the player is moving faster than the friction force
		playerBody.velocity.x -= (playerBody.velocity.x / abs(playerBody.velocity.x)) * groundFriction # subtracts friction force opposite of their direction of movement
	else:
		playerBody.velocity.x = 0 
	

func applyFrictionY():
	if abs(playerBody.velocity.y) > groundFriction:   # if the player is moving faster than the friction force
		playerBody.velocity.y -= (playerBody.velocity.y / abs(playerBody.velocity.y)) * groundFriction * yReductionPercent # subtracts friction force opposite of their direction of movement
	else:
		playerBody.velocity.y = 0 
		
func player():
	pass #used to check if player enters enemies hitbox

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("enemy"):
		enemy_inattack_range = true
	
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.has_method("enemy"):
		enemy_inattack_range = false
		
func enemy_attack():
	if enemy_inattack_range and enemy_attack_cooldown:
		health -= 10
		enemy_attack_cooldown = false
		enemy_attack_cooldown_timer.start()
		print(health)
		
func _on_enemy_attack_cooldown_timer_timeout() -> void:
	enemy_attack_cooldown = true
