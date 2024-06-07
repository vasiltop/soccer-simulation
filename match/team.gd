extends Node

class_name Team

enum { ATTACKING, DEFENDING, WAITING, THROW_IN, FREE_KICK, CORNER_KICK, GOAL_KICK, PENALTY }

const npc_scene = preload("res://objects/npc_player/npc_player.tscn")
const FIELD_SIZE: float = 81 * 2
const TEAM_SIZE: int = 1

var game: Game = null
var players: Array[Humanoid] = []
var side = 1
var team_number = 0

const player_info = [
	"st"
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
		inst.global_position = Vector3(pos.x, 1, pos.y * side)
		game.get_node("Players").add_child(inst)
		players.append(inst)
	
func get_players() -> Array[Humanoid]:
		return self.players

func position_to_vector(position: String) -> Vector2:

	match position:
		"st": return Vector2(0, 10)
	
	assert(false, "Invalid position string.")
	return Vector2.ZERO

func get_state() -> int:
	# TODO: Determine state based off of the probability of this team getting the ball next
	return ATTACKING
	
func get_closest_player_to_ball() -> Humanoid:
	var ball: Ball = self.game.get_node("Ball")
	
	var closest = null
	var distance = 9999999
	
	for p in self.players:
		var d: float = ball.global_position.distance_to(p.global_position)
		if d < distance:
			closest = p
			distance = d
	
	return closest
