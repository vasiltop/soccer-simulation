extends Humanoid

class_name NpcPlayer

const SHOOT_DISTANCE_SHORT: float = 30
const SHOOT_DISTANCE_LONG: float = 50
const TACKLE_DISTANCE: float = 1
const STOP_DRIBBLE_RANGE: float = 13
const ZONE_DISTANCE: float = 30
const BALL_DIRECT_FOLLOW_DISTANCE: float = 30
const TIME_UNTIL_PASS: float = 0.3

var black_mat = preload("res://materials/black.tres")
var brown_mat = preload("res://materials/brown.tres")
var green_mat = preload("res://materials/green.tres")

var pass_timer: float = 0

func _ready():
	MAX_RUN_SPEED = randf_range(6, 8)

func _process(delta):
	pass_timer += delta
	super(delta)

func _physics_process(delta):
	var mi: MeshInstance3D = get_node("MeshInstance3D")
		
	if get_team().team_number == 1:
		mi.set_surface_override_material(0, black_mat)
	else:
		mi.set_surface_override_material(0, brown_mat)
	
	apply_gravity(delta)
	if stunned: return
	if not game.started: return
	
	if soccer_position != "gk":
		match get_team_state():
			get_team().DEFENDING: defend(delta)
			get_team().ATTACKING: attack(delta)
	else:
		goalkeeper(delta)
	
	move_and_slide()

func goalkeeper(delta: float):
	kick_timer = KICK_DELAY + 1
	
	travel_to_node(delta, ball)
	
	if get_team().side == 1:
		global_position.z = clamp(global_position.z, 76 * get_team().side, abs(game.goal_line_z))
	else:
		global_position.z = clamp(global_position.z, game.goal_line_z, 76 * get_team().side )
	global_position.x = clamp(global_position.x, -game.net_length_x - 1, game.net_length_x + 1)
	
	if can_kick():
		var cl = get_closest_player_to_me()
		pass_to_player(cl, 9)
	
func get_closest_player_to_me() -> Humanoid:
	var closest = null
	var distance = 9999999
	
	for p in get_team().players:
		var d: float = p.global_position.distance_to(global_position)
		if d < distance and p != self:
			closest = p
			distance = d
	
	return closest
	
func defend(delta: float):
	
	if get_team().set_possession_player() == self:
		travel_to_node(delta, ball)
	else:
		var defense_pos: Vector2 = get_team().position_to_vector(soccer_position) * get_team().side
		var vec3_pos = Vector3(defense_pos.x, 1, defense_pos.y)
		
		var co = get_closest_opponent()
		if vec3_pos.distance_to(global_position) < ZONE_DISTANCE and co.global_position.distance_to(vec3_pos) < ZONE_DISTANCE and get_other_team().set_possession_player() == co:
			travel_to_node(delta, co)
			try_tackle(co)
		else:
			travel_to_position(delta, vec3_pos + Vector3(0, 0, distance_of_ball_from_my_half() * get_team().side * -1))

func distance_of_ball_from_my_half() -> float:
	var pos = ball.global_position
	
	if not is_ball_on_opponent_side():
		return 0
	else:
		return abs(pos.z)
	
func is_ball_on_opponent_side() -> bool:
	var side = get_team().side
	return (side == 1 and ball.global_position.z < 0) or (side == -1 and ball.global_position.z > 0)
	
func try_tackle(mark: Humanoid):
	if can_tackle(mark):
		mark.stunned = true

func can_tackle(mark: Humanoid) -> bool:
	return get_distance_to_node(mark) < TACKLE_DISTANCE

func get_closest_opponent() -> Humanoid:
	var other_team: Array[Humanoid] = get_other_team().players
	other_team.sort_custom(sort_closest)
	return other_team[0]

func sort_closest(a: Humanoid, b: Humanoid) -> bool:
	var d1 = a.global_position.distance_to(global_position)
	var d2 = b.global_position.distance_to(global_position)
	
	return d1 < d2

class PositionalWeight:
	
	var positions: Array[Vector3] = []
	var player: Humanoid = null
	var touch_line_x: float = 41
	var goal_line_z: float = 81
	
	func _init(positions: Array[Vector3], player: Humanoid):
		self.positions = positions
		self.player = player
		self.touch_line_x = abs(player.game.touch_line_x)
		self.goal_line_z = abs(player.game.goal_line_z)
	
	func get_most_favorable_pass_index() -> int:
		
		var weights: Array[float] = []
		
		for p in self.positions:
			var distance_to_closest_opponent: float = player.get_other_team().get_closest_player_to_position(p).global_position.distance_to(p)
			var distance_to_goal: float = player.get_opposing_net().global_position.distance_to(p)
			weights.append(-distance_to_goal + distance_to_closest_opponent / 4)

		return Util.get_max_index(weights)
		
	func get_most_favorable_index_without_possession() -> int:
		var weights: Array[float] = []
		
		for p in self.positions:
			var distance_to_closest_opponent: float = player.get_other_team().get_closest_player_to_position(p).global_position.distance_to(player.global_position + p)
			var distane_to_closest_teammate: float = player.get_team().get_closest_player_to_position(p).global_position.distance_to(player.global_position + p)
			
			weights.append(-distance_to_closest_opponent)
			
		return Util.get_max_index(weights)

func is_direction_to_opposing_net_blocked() -> bool:
	var c = get_other_team().get_closest_player_to_position(global_position)
	
	var dir = get_direction_to_node(get_opposing_net())
	
	dir = dir.rotated(Vector3.UP, deg_to_rad(-20))
	
	for i in range(8):
		dir = dir.rotated(Vector3.UP, deg_to_rad(5))
		var r = raycast(global_position, global_position + dir * 10)
		
		if r != null and r is Humanoid:
			return true
	
	return false

func attack(delta: float):
	if get_team().set_possession_player() == self:
		var mi: MeshInstance3D = get_node("MeshInstance3D")
		mi.set_surface_override_material(0, green_mat)
		try_shoot()
		
		var closest: Humanoid = get_closest_opponent()
		
		if get_distance_to_node(closest) < STOP_DRIBBLE_RANGE and is_direction_to_opposing_net_blocked():
			
			var available_passes: Array[Humanoid] = get_available_passes()
			var positions: Array[Vector3] = []
			
			for p in available_passes:
				positions.append(p.global_position)
				
			if len(positions) == 0:
				positions.append(get_direction_to_node(get_opposing_net()))
				
			var pw = PositionalWeight.new(positions, self)
			var i = pw.get_most_favorable_pass_index()
			
			if i < len(available_passes) and pass_timer > TIME_UNTIL_PASS:
				pass_timer = 0
				pass_to_position(positions[i])
			elif get_ball_distance() < BALL_DIRECT_FOLLOW_DISTANCE:
				kick_direction = get_direction_to_position(positions[i])
				travel_to_node(delta, ball)
			else:
				travel_to_position(delta, game.get_ball_landing_pos())
		else:
			if get_ball_distance() < BALL_DIRECT_FOLLOW_DISTANCE:
				kick_direction = get_direction_to_node(get_opposing_net())
				travel_to_node(delta, ball)
			else:
				travel_to_position(delta, game.get_ball_landing_pos())
	else:
		var pos = get_team().position_to_vector(soccer_position) * get_team().side
		var vec3pos = Vector3(pos.x * 1.5, 1, pos.y)
		var pos_on_other_half = vec3pos + Vector3(0, 0, abs(get_team().game.goal_line_z) * get_other_team().side + randi_range(-10, 10))
		
		#if pos_on_other_half.distance_to(global_position) < ZONE_DISTANCE:
		if is_ball_on_opponent_side():
			travel_to_position(delta, pos_on_other_half)
		else:
			var p: Humanoid = get_team().set_possession_player() 
			
			var positions: Array[Vector3] = []
			
			positions.append(global_position + Vector3(0, 0, 10 * get_other_team().side))
			positions.append(global_position + Vector3(0, 0, 4 * get_team().side))
			positions.append(global_position + get_direction_to_node(p) * 4)
			
			var pw = PositionalWeight.new(positions, self)
			var i = pw.get_most_favorable_index_without_possession()
			travel_to_position(delta, positions[i])
			
func get_relative_position(to: Vector3, direction: Vector3):
	var relative_direction = (to - global_position).normalized()
	var perpendicular_direction = relative_direction.cross(direction).normalized()
	var relative_position = to + perpendicular_direction 
	return relative_position

func raycast(start: Vector3, end: Vector3) -> Object:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(start, end)
	var result = space_state.intersect_ray(query)
	
	return result.collider if result.has("collider") else null

func get_available_passes() -> Array[Humanoid]:
	var passes: Array[Humanoid] = []
	
	for p in get_team().get_players():
		var result = raycast(global_position, p.global_position)
		
		if result != null and result == p:
			passes.append(p)
	
	return passes

func try_shoot():
	if can_shoot():
		ball.kicked(self, get_direction_to_node(get_opposing_net()), 9, true)

func travel_to_node(delta: float, node: Node3D):
	travel_to_position(delta, node.global_position)

func can_shoot() -> bool:
	return ( (not is_direction_to_opposing_net_blocked() and get_distance_to_attacking_net() < SHOOT_DISTANCE_LONG) or (get_distance_to_attacking_net() < SHOOT_DISTANCE_SHORT) ) and get_ball_distance() < BALL_KICK_RANGE

func is_closest() -> bool:
	return get_team().get_closest_player_to_ball() == self

func travel_to_position(delta: float, pos: Vector3):
	
	var dir: Vector3 = get_direction_to_position(pos)
	var p = raycast(global_position, global_position + dir)
	
	if p != null and p is Humanoid:
		dir = dir.rotated(Vector3.UP, deg_to_rad(60))
		
	velocity = dir * MAX_RUN_SPEED

func pass_to_player(player: Humanoid, strength: float):
	if not can_kick(): return
	
	kick_direction = get_direction_to_node(player)
	
	ball.kicked(self, kick_direction, strength, false)

func pass_to_position(pos: Vector3):
	if not can_kick(): return
	
	kick_direction = get_direction_to_position(pos)
	ball.kicked(self, kick_direction, 8, false)
	
func can_kick():
	return get_ball_distance() < BALL_KICK_RANGE
