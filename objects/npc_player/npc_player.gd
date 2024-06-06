extends Humanoid

class_name NpcPlayer

const SHOOT_DISTANCE = 30

@onready var game: Game = get_parent().get_parent()
@onready var ball: Ball = game.get_node("Ball")

func _ready():
	MAX_RUN_SPEED = 8

func _physics_process(delta):
	apply_gravity(delta)
	
	if is_closest():
		kick_direction = get_direction_to_node(get_opposing_net())
		travel_to_node(delta, ball)
		try_shoot()
	move_and_slide()

func try_shoot():
	if can_shoot():
		ball.kicked(self, get_direction_to_node(get_opposing_net()), 6, true)
			

func travel_to_node(delta: float, node: Node3D):
	travel_to_position(delta, node.global_position)

func can_shoot() -> bool:
	return get_distance_to_attacking_net() < SHOOT_DISTANCE and get_ball_distance() < BALL_KICK_RANGE

func get_distance_to_attacking_net():
	return get_opposing_net_position().distance_to(global_position)

func is_closest() -> bool:
	return get_team().get_closest_player_to_ball() == self

func get_team_state() -> int:
	return get_team().get_state()

func get_teammates() -> Array[Humanoid]:
	return get_team().get_players()

func get_team() -> Team:
	return game.teams[team]

func get_side_multiplier() -> int:
	return get_team().side

func get_position_vector() -> Vector3:
	var vec: Vector2 = get_team().position_to_vector(soccer_position)
	return Vector3(vec.x, 0, vec.y * get_side_multiplier())

func _process(delta):
	super(delta)
	
func travel_to_position(delta: float, pos: Vector3):
	var dir: Vector3 = get_direction_to_position(pos)
	velocity = dir * MAX_RUN_SPEED
	
func get_opposing_net_position() -> Vector3:
	return get_opposing_net().global_position

func get_opposing_net() -> Goal:
	return game.goals_to_attack[team]

func pass_to_player(player: Humanoid):
	if not can_kick(): return
	
	kick_direction = get_direction_to_node(player)
	ball.kicked(self, kick_direction, 8, false)

func get_direction_to_node(node: Node3D):
	return get_direction_to_position(node.global_position)

func get_direction_to_position(pos: Vector3) -> Vector3:
	var p1: Vector2 = Vector2(pos.x, pos.z)
	var p2: Vector2 = Vector2(global_position.x, global_position.z)
	
	var dir = (p1 - p2).normalized()
	return Vector3(dir.x, 0, dir.y)
	
func get_ball_distance():
	return ball.global_position.distance_to(global_position)
	
func get_ball_position():
	return ball.global_position

func can_kick():
	return get_ball_distance() < BALL_KICK_RANGE
