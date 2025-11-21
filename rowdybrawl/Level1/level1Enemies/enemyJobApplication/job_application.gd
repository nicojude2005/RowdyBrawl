extends Enemy
class_name jobApplication

var JOB_APPLICATION_SLAM = load("uid://5e4q3284mm0e")
@onready var job_application_animator: AnimationPlayer = $jobApplicationAnimator


func _ready() -> void:
	hitRate = 1
	health = 100

#func _process(delta: float) -> void:
	#pass

#func _physics_process(delta: float) -> void:
	#super(delta)

func aiAttackFunction(delta :float):
	hitTimer -= delta
	#targetPos = playerRef.playerBody.global_position
#	uncomment the line above if you wanna see what EXTRA HARD enemies could act like
	if hitTimer <= 0:
		if playerRef.playerYPosition > yPosition:
			jump()
		if canAttack():
			var currentAttack = spawnAttack(JOB_APPLICATION_SLAM, 10, 1, 0.35, 0.65)
			currentAttack.zReach = 20
			if facingDir == 1:
				job_application_animator.play("jobApplicationSlam")
			else:
				job_application_animator.play("jobApplicationSlamLeft")
			hitTimer = hitRate
			ai = aiStates.CHASE
