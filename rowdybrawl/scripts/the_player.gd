extends Node2D
class_name player   # the tutorial doesnt talk about this(because technically they arent required), but class_names's are very important
# every script thats attatched to an object should have a class_name (as far as ive learned) 
# this class name will allow us to statically declare references in other scripts
# which is a mouthful, but I think its vital for good code

@onready var playerBody: CharacterBody2D = %playerBody # this grabs a reference to the Player Body, so you can move the player around

var maxSpeed = 100
var accelaration = 20
var groundFriction = 5      # these set up basic ground movement

var jumpVelocity = 300      

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity") 

func _physics_process(delta: float) -> void:     # _physics_process runs in fixed(very tiny) intervals, regardless of the framerate
												 # This makes it good for movement and physics-based code
	if Input.is_action_pressed("left"):
		if playerBody.velocity.x > -maxSpeed:    # Checks if the player's speed to the left is below the max speed, before accelarating in that direction
			playerBody.velocity.x -= 10
	elif Input.is_action_pressed("right"):       
		if playerBody.velocity.x < maxSpeed:     # Checks if the player's speed to the right is below the max speed, before accelarating in that direction
			playerBody.velocity.x += 10
	else:
		applyFriction()  # this is to slow the player to a stop if they are not holding a direction
	
	
	if Input.is_action_just_pressed("jump"):
		if playerBody.is_on_floor():
			playerBody.velocity.y -= jumpVelocity
	
	if not playerBody.is_on_floor():
		playerBody.velocity.y += gravity * delta
	
	
	playerBody.move_and_slide()  # this function is what actually applies the player's velocity to their position. It also does all the collision checks

func applyFriction():
	
	if abs(playerBody.velocity.x) > groundFriction:   # if the player is moving faster than the friction force
		playerBody.velocity.x -= (playerBody.velocity.x / abs(playerBody.velocity.x)) * groundFriction # subtracts friction force opposite of their direction of movement
	else:
		playerBody.velocity.x = 0 
		
