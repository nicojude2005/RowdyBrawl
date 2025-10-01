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

const LIGHT_ATTACK = preload("uid://cclox11udehj4")
const HEAVY_ATTACK = preload("uid://df6js1m8i34eb")



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

func _physics_process(delta: float) -> void:     # _physics_process runs in fixed(very tiny) intervals, regardless of the framerate
												 # This makes it good for movement and physics-based code
	
	if attackBusyTimer > 0:
		attackBusyTimer -= delta
	
	# attacks and stuff
	if Input.is_action_just_pressed("lightAttack") and attackBusyTimer <= 0:
		lightAttack()
	elif Input.is_action_just_pressed("heavyAttack") and attackBusyTimer <= 0:
		heavyAttack()
	
	
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
	

func flipToDirection(flipToRight : bool):
	if flipToRight and playerBody.scale.y < 1:
		playerBody.rotation_degrees = 0
		playerBody.scale.y = 1
	elif !flipToRight and playerBody.scale.y > -1:
		playerBody.rotation_degrees = 180
		playerBody.scale.y = -1

func lightAttack():
	# spawn a hitbox in front of the player, for a Duration equal to the Light Attack Duration time
	# and it has the size of Light attack Size
	# and it does Light Attack Damage
	var lightAttackHitbox : hitBox = LIGHT_ATTACK.instantiate();
	lightAttackHitbox.myZIndex = playerBody.position.y
	hit_box.add_child(lightAttackHitbox)
	
	lightAttackHitbox.position = hit_box.position
	lightAttackHitbox.duration = .15
	attackBusyTimer = .2
	

func heavyAttack():
	# same thing as light attack but with different numbers
	var heavyAttackHitbox : hitBox = HEAVY_ATTACK.instantiate();
	heavyAttackHitbox.myZIndex = playerBody.position.y
	hit_box.add_child(heavyAttackHitbox)
	
	heavyAttackHitbox.position = hit_box.position
	heavyAttackHitbox.duration = .4
	attackBusyTimer = .5

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
	
