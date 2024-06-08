extends CharacterBody3D

class_name Humanoid

@onready var game: Game = get_parent().get_parent()
@onready var ball: Ball = game.get_node("Ball")

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
var marked_by: Humanoid = null
var stunned: bool = false

func grounded() -> bool:
	return test_move(global_transform, Vector3(0, -0.04, 0))
	
func apply_gravity(delta: float):
	if not grounded():
		velocity.y -= GRAVITY * delta
	
func _process(delta):
	kick_timer += delta
	stop_stun()

func stop_stun():
	if stunned:
		await get_tree().create_timer(1).timeout
		stunned = false
		
func get_team() -> Team:
	return game.teams[team]

func get_other_team() -> Team:
	var o = 1 if team == 0 else 0
	return game.teams[o]

func get_teammates() -> Array[Humanoid]:
	return get_team().get_players()

func get_side_multiplier() -> int:
	return get_team().side
	
func get_opposing_net_position() -> Vector3:
	return get_opposing_net().global_position

func get_opposing_net() -> Goal:
	return game.goals_to_attack[team]
	
func get_own_net() -> Goal:
	var o = 1 if team == 0 else 0
	return game.goals_to_attack[o]
	
func get_ball_distance():
	return ball.global_position.distance_to(global_position)
	
func get_ball_position():
	return ball.global_position
	
func get_team_state() -> int:
	return get_team().get_state()

func get_distance_to_attacking_net():
	return get_opposing_net_position().distance_to(global_position)

func get_direction_to_node(node: Node3D):
	return get_direction_to_position(node.global_position)
	
func get_direction_to_position(pos: Vector3) -> Vector3:
	var p1: Vector2 = Vector2(pos.x, pos.z)
	var p2: Vector2 = Vector2(global_position.x, global_position.z)
	
	var dir = (p1 - p2).normalized()
	return Vector3(dir.x, 0, dir.y)
	
func get_position_vector() -> Vector3:
	var vec: Vector2 = get_team().position_to_vector(soccer_position)
	return Vector3(vec.x, 0, vec.y * get_side_multiplier())

func get_distance_to_node(node: Node3D):
	return node.global_position.distance_to(global_position)
