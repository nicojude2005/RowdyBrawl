extends hitBox
class_name canvas_projectile

var targetPos : Vector2 = Vector2.ZERO
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	spawnIn()
	teamAttack = false

func _process(delta: float) -> void:
	global_position += (targetPos - global_position).normalized() * 1.7
	super(delta)

func spawnIn():
	animation_player.play("spawn")
