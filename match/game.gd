extends Node3D

class_name Game

@onready var timer_label: Label = $Timer
@onready var score_label: Label = $Score
@onready var ball: Ball = $Ball
@onready var center_ball_position: Vector3 = Vector3(1, 0.8, 0)
@onready var goal_line_z: float = $GoalLineZ.global_position.z
@onready var touch_line_x: float = $TouchLineX.global_position.x
@onready var net_length_x: float = $NetLengthX.global_position.x
@onready var goal_0: Node3D = $Goal0
@onready var goal_1: Node3D = $Goal1
@onready var goals_to_attack: Array[Node3D] = [goal_1, goal_0]

@onready var teams: Array[Team] = [Team.new(0, 1, self), Team.new(1, -1, self)]

var possession_team: Team = null
var ball_scene = preload("res://objects/ball/ball.tscn")

enum { WARMUP, LIVE, HALF_TIME, END }

const npc_player = preload("res://objects/npc_player/npc_player.tscn")
const length: Dictionary = {
	WARMUP: 5,
	LIVE: 100,
	HALF_TIME: 5,
	END: 5,
}

var intermediate_timer: float = 1
const INTERMEDIATE_TIME: float = 1

var started: bool = false
var state: int = WARMUP

var score: Array = [0, 0]
var timer: float = 0
var half_time_passed: bool = false
	
func _ready():
	RenderingServer.set_debug_generate_wireframes(true)

func get_center_pos():
	return Vector3(0, 2, 0)

func _input(event):
	if event is InputEventKey and Input.is_key_pressed(KEY_P):
		var vp = get_viewport()
		vp.debug_draw = (vp.debug_draw + 1 ) % 6

func _process(delta):
	
	update_ui()
	update_game_state(delta)

func update_game_state(delta: float):
	if intermediate_timer > INTERMEDIATE_TIME:
		timer += delta
		started = true
		
	intermediate_timer += delta
	
	if timer > length[state]:
		match state:
			WARMUP:
				intermediate_timer = 0
				started = false
				state = LIVE
				reset_field()
			HALF_TIME:
				intermediate_timer = 0
				started = false
				for team in teams:
					team.side = team.side * -1
				reset_field()
				half_time_passed = true
				state = LIVE
			END:
				print("game ended")
				print(score)
				get_tree().reload_current_scene()
			LIVE:
				state = END if half_time_passed else HALF_TIME

		timer = 0
		
func update_ui():
	timer_label.text = state_to_string(state) + " " + str(floor(timer))
	score_label.text = "%d / %d" % [score[0], score[1]]
	
func reset_field():
	started = false
	
	for team in teams:
		team.reset_players()
		
	get_team_on_side_one().players.pick_random().global_position = get_center_pos()
		
	
	ball.global_position = center_ball_position
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO

func get_team_on_side_one() -> Team:
	return teams[0] if teams[0].side == 1 else teams[1]

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

func set_possession_team() -> Team:
	var p0 = teams[0].set_possession_player()
	var p1 = teams[1].set_possession_player()
	
	var blp = get_ball_landing_pos()
	
	var closest = closest_from_two(p0, p1, blp)
	
	return teams[closest.team]
	
func closest_from_two(p0: Humanoid, p1: Humanoid, pos: Vector3) -> Humanoid:
	
	var d0 = p0.global_position.distance_to(pos)
	var d1 = p1.global_position.distance_to(pos)
	
	return p0 if d0 < d1 else p1
