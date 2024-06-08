extends Node

class_name Team

enum { ATTACKING, DEFENDING, WAITING, THROW_IN, FREE_KICK, CORNER_KICK, GOAL_KICK, PENALTY }

const npc_scene = preload("res://objects/npc_player/npc_player.tscn")
const FIELD_SIZE: float = 81 * 2
const TEAM_SIZE: int = 11

var game: Game = null
var players: Array[Humanoid] = []
var side: int = 10
var team_number: int = 0
var possession_player: Humanoid = null

const player_info = [
	"rw",
	"lw",
	"st",
	"cm",
	"rm",
	"lm",
	"rcb",
	"lcb",
	"rb",
	"lb",
	"gk"
]

func _init(team_number: int, side: int, game: Game):
	self.side = side
	self.game = game
	self.team_number = team_number

	for i in range(TEAM_SIZE):
		var inst: Humanoid = npc_scene.instantiate()
		inst.soccer_position = player_info[i]
		inst.team = team_number
		var pos: Vector2 = position_to_vector(inst.soccer_position)
		inst.global_position = Vector3(pos.x * side, 2, pos.y * side)
		game.get_node("Players").add_child(inst)
		players.append(inst)
	
func get_players() -> Array[Humanoid]:
		return self.players

func reset_players():
	for p in players:
		var pos: Vector2 = position_to_vector(p.soccer_position)
		p.global_position = Vector3(pos.x * side, 2, pos.y * side)

func position_to_vector(position: String) -> Vector2:

	match position:
		"st": return Vector2(0, 15)
		"rw": return Vector2(25, 15)
		"lw": return Vector2(-25, 15)
		"rcm": return Vector2(5, 35)
		"lcm": return Vector2(-5, 35)
		"cm": return Vector2(0, 35)
		"rm": return Vector2(15, 35)
		"lm": return Vector2(-15, 35)
		"rcb": return Vector2(5, 55)
		"lcb": return Vector2(-5, 55)
		"rb": return Vector2(15, 55)
		"lb": return Vector2(-15, 55)
		"gk": return Vector2(0, 76)
	
	assert(false, "Invalid position string.")
	return Vector2.ZERO

func get_state() -> int:
	match game.set_possession_team().team_number:
		team_number: return ATTACKING
		_: return DEFENDING

func get_closest_player_to_ball() -> Humanoid:
	var ball: Ball = self.game.get_node("Ball")
	
	return get_closest_player_to_position(ball.global_position)

func get_closest_player_to_position(pos: Vector3) -> Humanoid:
	var closest = null
	var distance = 9999999
	
	for p in self.players:
		var d: float = pos.distance_to(p.global_position)
		if d < distance:
			closest = p
			distance = d
	
	return closest

func set_possession_player() -> Humanoid:
	var ball_landing_pos = game.get_ball_landing_pos()
	possession_player = get_closest_player_to_position(ball_landing_pos)
	return possession_player
