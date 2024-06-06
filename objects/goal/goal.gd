extends Node3D
class_name  Goal

signal goal_scored

var goals_blocked: bool = false
@onready var game = get_parent()
@onready var area = $Area3D
@export var team: int

func _ready():
	area.body_entered.connect(goal)

func goal(ball: Node3D):

	if not ball is Ball or goals_blocked or GameManager.game_state != GameManager.LIVE: return
	GameManager.score[team] += 1
	goals_blocked = true
	game.scored(self)
	
