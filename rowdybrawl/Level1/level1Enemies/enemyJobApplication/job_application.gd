extends Enemy
class_name jobApplication

var targetPos = Vector2.ZERO

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if playerRef != null:
		targetPos.y = playerRef.playerBody.global_position.y
		if global_position.x < playerRef.playerBody.global_position.x:
			targetPos.x = playerRef.playerBody.global_position.x - 50 # offset so that they can hit the player easier
		else:
			targetPos.x = playerRef.playerBody.global_position.x + 50
	
	if targetPos != Vector2.ZERO:
		moveDirection = (targetPos - global_position).normalized()
	else:
		moveDirection = Vector2.ZERO
		
	if moveDirection != Vector2.ZERO:
		accelarateInDirection()
	super(delta)

func accelarateInDirection():
	if abs((moveDirection.x * accelaration) + velocity.x) <= maxSpeed:
		velocity.x += moveDirection.x * accelaration
		
	
	if abs((moveDirection.y * accelaration) + velocity.y) <= maxSpeed * yReductionAmount:
		velocity.y += moveDirection.y * accelaration * yReductionAmount
