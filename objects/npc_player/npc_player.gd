extends CharacterBody3D

class_name NpcPlayer
const GRAVITY: float = 11
var MAX_WALK_SPEED: float = randf_range(250, 300)
var MAX_RUN_SPEED: float = MAX_WALK_SPEED * 2
const JUMP_FORCE: float = 3.5

var kick_charge: float = 1
var kick_direction: Vector3 = Vector3.ZERO
var kick_timer: float = 0.0
const KICK_DELAY: float = 0.8

@onready var game: Game = get_parent()

var team: int = 0
var soccer_position: String = "gk"
var spawn_pos: Vector3 = global_position

var previous_pass: NpcPlayer = null
