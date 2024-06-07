extends Humanoid

class_name NpcPlayer

const SHOOT_DISTANCE = 30
const TACKLE_DISTANCE = 3

var black_mat = preload("res://materials/black.tres")
var brown_mat = preload("res://materials/brown.tres")
var green_mat = preload("res://materials/green.tres")

func _ready():
	
	MAX_RUN_SPEED = 8

func _process(delta):
	super(delta)

func _physics_process(delta):
	if stunned: return
	var mi: MeshInstance3D = get_node("MeshInstance3D")
	if get_team().team_number == 1:
		mi.set_surface_override_material(0, black_mat)
	else:
		mi.set_surface_override_material(0, brown_mat)
	apply_gravity(delta)
	
	match get_team_state():
		get_team().DEFENDING: defend(delta)
		get_team().ATTACKING: attack(delta)
	
	move_and_slide()

func defend(delta: float):
	var mark: Humanoid = get_man_to_mark()
	if mark.get_team().set_possession_player() == mark:
		travel_to_node(delta, mark)
		try_tackle(mark)
	else:
		mark_player(delta, mark)
	
	mark.marked_by = null

func mark_player(delta: float, mark: Humanoid):
	var n = get_own_net()
	var dir = get_direction_to_node(n)
	travel_to_position(delta, mark.global_position + dir * 3)
	
func try_tackle(mark: Humanoid):
	if can_tackle(mark):
		mark.stunned = true

func can_tackle(mark: Humanoid) -> bool:
	return get_distance_to_node(mark) < TACKLE_DISTANCE

func get_man_to_mark() -> Humanoid:
	var other_team: Array[Humanoid] = get_other_team().players
	other_team.sort_custom(sort_closest)
	
	for p in other_team:
		if p.marked_by == null and p.soccer_position != "gk":
			p.marked_by = self
			return p
	
	assert(false, "Nobody found to mark?")
	return null

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
	
	func _init(positions: Array[Vector3], player: Humanoid):
		self.positions = positions
		self.player = player
	
	func get_most_favorable_index_with_possession() -> int:
		var weights: Array[float] = []
		
		for p in self.positions:
			var distance_to_closest_opponent: float = player.get_other_team().get_closest_player_to_position(p).global_position.distance_to(p)
			var distance_to_goal: float = player.get_opposing_net().global_position.distance_to(p)
			var distance_to_touch_line: float = abs(player.game.touch_line_x) - abs(p.x)
			var distane_to_cloest_teammate: float = player.get_team().get_closest_player_to_position(p).global_position.distance_to(p)
			weights.append(-distance_to_closest_opponent - distance_to_goal - distance_to_touch_line- distane_to_cloest_teammate)
			
		
		return Util.get_max_index(weights)
		
	func get_most_favorable_index_without_possession() -> int:
		var weights: Array[float] = []
		
		for p in self.positions:
			var distance_to_closest_opponent: float = player.get_other_team().get_closest_player_to_position(p).global_position.distance_to(p)
			var distane_to_cloest_teammate: float = player.get_team().get_closest_player_to_position(p).global_position.distance_to(p)
			var distance_to_ball: float = player.ball.global_position.distance_to(p)
			var pos = player.get_team().position_to_vector(player.soccer_position)
			var distance_to_position_x: float = ((pos.x * player.get_team().side) - p.x) * 500
			
			weights.append(-distance_to_closest_opponent - distance_to_ball - distance_to_position_x - distane_to_cloest_teammate)
			
		return Util.get_max_index(weights)


func attack(delta: float):
	if get_team().set_possession_player() == self:
		if can_kick():
			var closest: Humanoid = get_closest_opponent()
			var available_passes: Array[Humanoid] = get_available_passes()
			
			var positions: Array[Vector3] = []
			for p in available_passes:
				positions.append(p.global_position)
			
			positions.append(get_relative_position(closest.global_position, Vector3.RIGHT))
			positions.append(get_relative_position(closest.global_position, Vector3.LEFT))
			positions.append(get_direction_to_node(get_opposing_net()))
			
			var pw = PositionalWeight.new(positions, self)
			var i = pw.get_most_favorable_index_with_possession()
			
			if i < len(available_passes):
				pass_to_position(positions[i])
			else:
				kick_direction = get_direction_to_position(positions[i])
				travel_to_node(delta, ball)
		else:
			travel_to_position(delta, game.get_ball_landing_pos())
	else:
		
		var positions: Array[Vector3] = []
		#positions.append(global_position + get_direction_to_node(get_team().set_possession_player()))
		positions.append(global_position + Vector3(0, 0, 5 * get_team().side))
		positions.append(global_position + Vector3(5, 0, 0))
		positions.append(global_position + Vector3(-5, 0, 0))
		positions.append(global_position + Vector3(0, 0, 2 * get_team().side * -1))
		
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
		ball.kicked(self, get_direction_to_node(get_opposing_net()), 6, true)

func travel_to_node(delta: float, node: Node3D):
	travel_to_position(delta, node.global_position)

func can_shoot() -> bool:
	return get_distance_to_attacking_net() < SHOOT_DISTANCE and get_ball_distance() < BALL_KICK_RANGE

func is_closest() -> bool:
	return get_team().get_closest_player_to_ball() == self

func travel_to_position(delta: float, pos: Vector3):
	var dir: Vector3 = get_direction_to_position(pos)
	velocity = dir * MAX_RUN_SPEED

func pass_to_player(player: Humanoid):
	if not can_kick(): return
	
	kick_direction = get_direction_to_node(player)
	ball.kicked(self, kick_direction, 8, false)

func pass_to_position(pos: Vector3):
	if not can_kick(): return
	
	kick_direction = get_direction_to_position(pos)
	ball.kicked(self, kick_direction, 8, false)
	
func can_kick():
	return get_ball_distance() < BALL_KICK_RANGE
