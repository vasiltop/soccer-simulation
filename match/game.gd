extends Node3D

class_name Game

@onready var timer_label: Label = $Timer
@onready var score_label: Label = $Score
@onready var ball: Ball = $Ball
@onready var center_ball_position: Vector3 = ball.global_position
@onready var goal_line_z: float = $GoalLineZ.global_position.z
@onready var goal_0: Node3D = $Goal0
@onready var goal_1: Node3D = $Goal1
@onready var goals_to_attack: Array[Node3D] = [goal_1, goal_0]
@onready var players: Array[Humanoid] = []
@onready var teams: Array[Team] = []
@export var spawns: Array[Node3D]

enum { WARMUP, LIVE, HALF_TIME, END }

const npc_player = preload("res://objects/npc_player/npc_player.tscn")
const length: Dictionary = {
	WARMUP: 1000,
	LIVE: 300,
	HALF_TIME: 5,
	END: 10,
}

var started: bool = false
var state: int = WARMUP
var black_mat = preload("res://materials/black.tres")
var brown_mat = preload("res://materials/brown.tres")
var green_mat = preload("res://materials/green.tres")
var score: Array = [0, 0]
var timer: float = 0
var half_time_passed: bool = false

func _ready():
	players.assign(find_children("", "Humanoid", true))
	teams = [Team.new(0, players, 1, self), Team.new(1, players, -1, self)]
	
func _process(delta):
	update_ui()
	update_game_state(delta)

func update_game_state(delta: float):
	timer += delta
	
	if timer > length[state]:
		match state:
			WARMUP:
				state = LIVE
				reset_field()
			HALF_TIME:
				half_time_passed = true
				state = LIVE
			END:
				state = WARMUP
				score = [0, 0]
				reset_field()
			LIVE:
				state = END if half_time_passed else HALF_TIME

		timer = 0
		
func update_ui():
	timer_label.text = state_to_string(state) + " " + str(floor(timer))
	score_label.text = "%d / %d" % [score[0], score[1]]
	
func reset_field():
	ball.global_position = center_ball_position
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO

func scored(goal: Goal):
	score[goal.team] += 1
	reset_field()
	goal.goals_blocked = false

func state_to_string(state: int):
	match state:
		WARMUP:
			return "Warmup"
		HALF_TIME:
			return "Half Time"
		END:
			return "End"
		LIVE:
			return "Live"


