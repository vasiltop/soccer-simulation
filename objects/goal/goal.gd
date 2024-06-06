extends Node3D
class_name  Goal

@onready var game = get_parent()
@onready var area = $Area3D
@export var team: int

signal goal_scored

var goals_blocked: bool = false

func _ready():
	area.body_entered.connect(goal)

func goal(ball: Node3D):

	if not ball is Ball or goals_blocked or game.state != game.LIVE: return
	goals_blocked = true
	game.scored(self)
	
