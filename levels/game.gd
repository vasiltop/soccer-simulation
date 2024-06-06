extends Node3D

class_name Game

@onready var timer: Label = $Timer
@onready var score: Label = $Score
@onready var ball: Ball = $Ball
@onready var center_ball_position = ball.global_position
@onready var goal_line_z: float = $GoalLineZ.global_position.z
@onready var goal_0 = $Goal0
@onready var goal_1 = $Goal1
@onready var goals_to_attack = [goal_0, goal_1]
@export var spawns: Array[Node3D]

const npc_player = preload("res://objects/npc_player/npc_player.tscn")

var started: bool = false

var black_mat = preload("res://materials/black.tres")
var brown_mat = preload("res://materials/brown.tres")
var green_mat = preload("res://materials/green.tres")

func _ready():
	GameManager.start_half.connect(reset_field)

func _process(delta):
	timer.text = GameManager.state_to_string(GameManager.game_state) + " " + str(floor(GameManager.timer))
	score.text = "%d / %d" % [GameManager.score[0], GameManager.score[1]]
	

func reset_field():
	ball.global_position = center_ball_position
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	
	

func _physics_process(delta):
	pass
	

func scored(goal: Goal):
	reset_field()
	goal.goals_blocked = false
