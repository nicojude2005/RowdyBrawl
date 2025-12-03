extends Enemy
class_name jobApplication

var JOB_APPLICATION_SLAM = load("uid://5e4q3284mm0e")
@onready var job_application_animator: AnimationPlayer = $jobApplicationAnimator

var currentAttack : hitBox
func _ready() -> void:
	hitRate = 1
	health = 200

#func _process(delta: float) -> void:
	#pass

func _physics_process(delta: float) -> void:
	super(delta)

func aiAttackFunction(delta :float):
	hitTimer -= delta 
	#targetPos = playerRef.playerBody.global_position
	#uncomment the line above if you wanna see what EXTRA HARD enemies could act like
	if hitTimer <= 0:
		if playerRef.playerYPosition > yPosition:
			jump()
		if canAttack():
			currentAttack = spawnAttack(JOB_APPLICATION_SLAM, 10, 1, 0.35, 0.15)
			currentAttack.zReach = 20
			if facingDir == 1:
				job_application_animator.play("jobApplicationSlam")
			else:
				job_application_animator.play("jobApplicationSlamLeft")
			hitTimer = hitRate
			ai = aiStates.CHASE
<<<<<<< Updated upstream
<<<<<<< Updated upstream
			goRight = randi_range(0,1)
		
=======
=======
>>>>>>> Stashed changes
func take_hit(damage: int, knockback_dir: Vector2, knockback_strength: float, stun_duration: float, attacker : Node2D = null) -> void:
	if currentAttack != null:
		currentAttack.duration = 0
	job_application_animator.stop()
	job_application_animator.play("RESET")
	job_application_animator.play("hurt")
	super(damage, knockback_dir, knockback_strength, stun_duration, attacker)
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
