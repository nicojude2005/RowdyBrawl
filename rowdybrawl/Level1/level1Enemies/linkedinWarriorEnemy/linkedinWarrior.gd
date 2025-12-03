extends Enemy
class_name linkedin_warrior

# Custom stats for LinkedIn Warrior enemy
var damage: int = 10
var attack_cooldown: float = 0.6  # quicker attacks

func _ready() -> void:
	# Override base health and speed
	health = 125
	super()

func _physics_process(delta: float) -> void:
	# Custom movement/AI logic can go here if needed

	super._physics_process(delta)  # call base physics process

func aiAttackFunction(delta: float):
	#hitTimer -= delta
	#if hitTimer <= 0:
	#	hitTimer = hitRate
	#	ai = aiStates.CHASE

	super.aiAttackFunction(delta)
