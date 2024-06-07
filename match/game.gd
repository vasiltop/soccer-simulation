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
@onready var teams: Array[Team] = [Team.new(0, 1, self), Team.new(1, -1, self)]

var ball_scene = preload("res://objects/ball/ball.tscn")

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
	RenderingServer.set_debug_generate_wireframes(true)

func _input(event):
	if event is InputEventKey and Input.is_key_pressed(KEY_P):
		var vp = get_viewport()
		vp.debug_draw = (vp.debug_draw + 1 ) % 6

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

func get_ball_landing_pos() -> Vector3:
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	
	var vel: Vector3 = ball.linear_velocity
	var pos: Vector3 = ball.global_position
	var step: float = 0.015
	
	while pos.y > 0:
		vel.y -= gravity * step
		pos += vel * step
		
	pos.y = 1
	
	return pos
