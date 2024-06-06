extends Node

class_name Team

enum { ATTACKING, DEFENDING, WAITING, THROW_IN, FREE_KICK, CORNER_KICK, GOAL_KICK, PENALTY }

const FIELD_SIZE: float = 81 * 2

var game: Game = null
var players: Array[Humanoid] = []
var side = 1

func _init(number: int, players: Array[Humanoid], side: int, game: Game):
	
	for p in players:
		if p.team == number:
			self.players.append(p)
	
	self.side = side
	self.game = game
	
func get_players() -> Array[Humanoid]:
		return self.players

func position_to_vector(position: String) -> Vector2:

	match position:
		"st": return Vector2(0, 10)
	
	Error.throw("Invalid position string.")
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
