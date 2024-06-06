extends CharacterBody3D

class_name Humanoid

@export var team: int = 0
@export var soccer_position: String = "gk"

const GRAVITY: float = 11
const KICK_DELAY: float = 0.8
const JUMP_FORCE: float = 3.5
const BALL_KICK_RANGE: float = 2

var kick_direction: Vector3 = Vector3.ZERO
var kick_timer: float = 0.0
var kick_charge: float = 1
var MAX_WALK_SPEED: float = 300
var MAX_RUN_SPEED: float = MAX_WALK_SPEED * 2

func grounded() -> bool:
	return test_move(global_transform, Vector3(0, -0.01, 0))
	
func apply_gravity(delta: float):
	if not grounded():
		velocity.y -= GRAVITY * delta
	
func _process(delta):
	kick_timer += delta

