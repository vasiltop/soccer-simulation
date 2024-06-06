extends Node

enum { WARMUP, LIVE, HALF_TIME, END }

var game_state: int = WARMUP

var half_time_passed: bool = false

signal start_half
signal half_time
signal full_time

var score: Array = [0, 0]

var length: Dictionary = {
	WARMUP: 2,
	LIVE: 1000,
	HALF_TIME: 5,
	END: 10,
}

func state_to_string(state: int):
	match game_state:
		WARMUP:
			return "Warmup"
		HALF_TIME:
			return "Half Time"
		END:
			return "End"
		LIVE:
			return "Live"

var timer: float = 0

func start_match():
	get_tree().change_scene_to_file("res://levels/game.tscn")

func _ready():
	start_match()
	start_half.emit()

func _process(delta):
	timer += delta
	
	if timer > length[game_state]:
		match game_state:
			WARMUP:
				game_state = LIVE
				start_half.emit()
			HALF_TIME:
				half_time_passed = true
				game_state = LIVE
			END:
				game_state = WARMUP
				score = [0, 0]
				get_tree().change_scene_to_file("res://levels/game.tscn")
			LIVE:
				game_state = END if half_time_passed else HALF_TIME
				if half_time_passed: full_time.emit()  
				else: half_time.emit()

		timer = 0
