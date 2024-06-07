extends Humanoid

class_name  Player

@onready var camera: Camera3D = $Eye/Camera3D
@onready var original_cam_pos: Vector3 = camera.position

const MIN_KICK_CHARGE: float = 1
const SENS: float = 0.001

const CAMERA_LERP_SPEED: float = 0.08
const WALK_TIME_AUDIO_DELAY: float  = 0.6
const RUN_TIME_AUDIO_DELAY: float  = 0.4
const CAMERA_TILT_INCREMENT = 0.04
const CAMERA_TILT_ANGLE = 3
const KICK_CHARGE_INCREMENT: float = 12
const MAX_KICK_CHARGE: float = 10

const SLOW_CAMERA_BOB_SPEED: float = 6
const FAST_CAMERA_BOB_SPEED: float = 15
const SLOW_CAMERA_BOB_HEIGHT: float = 5
const FAST_CAMERA_BOB_HEIGHT: float = 1
const CAMERA_BOB_LERP_SLEEP: float = 0.01
const MOUSE_KICK_DIRECTION_MIN_MOVEMENT: float = 3.0
const MOUSE_KICK_DIRECTION_SPEED: float = 700.0

var current_run_speed: float = 0.0
var b: Basis = Basis()
var camera_locked: bool = true

var mouse_kick_direction: Vector3 = Vector3.ZERO
var camera_bob: float = 0
var time_since_last_walk_audio: float  = 0
var camera_height: int = 0

var walking_sound = preload("res://sounds/walk.mp3")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _process(delta):
	super(delta)
	check_for_camera_switch()
	set_kick_direction()
	check_for_restart()
	update_timers(delta)
	bob_camera()
	handle_shooting(delta)
	smoothly_change_run_speed()
	apply_camera_tilt()

func _physics_process(delta: float):
	velocity = movement(delta)
	apply_gravity(delta)
	
	move_and_slide()
	
	if camera_locked:
		update_camera_locked()
		
func check_for_camera_switch():
	if Input.is_action_just_pressed("switch_movement") and grounded():
		camera_locked = not camera_locked

func check_for_restart():
	if Input.is_action_just_pressed("restart"):
		ball.global_position = global_position
		ball.linear_velocity = Vector3.ZERO
		ball.linear_damp = 0
		
func update_timers(delta: float):
	camera_bob += delta
	time_since_last_walk_audio += delta
	
func apply_camera_tilt():
	var l: bool = Input.is_action_pressed("left")
	var r: bool = Input.is_action_pressed("right")
	var multiplier: int = 0
	
	if l:
		multiplier = 1
	elif r:
		multiplier = -1
		
	var target: float = CAMERA_TILT_ANGLE * multiplier
	
	camera.rotation.z = lerp_angle(camera.rotation.z, deg_to_rad(target), CAMERA_TILT_INCREMENT)
	
func smoothly_change_run_speed():
	var sprinting: bool = Input.is_action_pressed("sprint")

	var target: float = 0
	const RUN_SPEED_INCREMENT: float = 0.04
	
	target = MAX_RUN_SPEED if sprinting else MAX_WALK_SPEED
	
	if not trying_to_move():
		target = 0.0

	current_run_speed = lerp(current_run_speed, target, RUN_SPEED_INCREMENT)

func trying_to_move():
	return Input.get_vector("left", "right", "up", "down").length() > 0.0

func play_walking_audio():
	var sprinting = Input.is_action_pressed("sprint")
	var vel = Vector2(velocity.x, velocity.z)
	
	if time_since_last_walk_audio > (RUN_TIME_AUDIO_DELAY if sprinting else WALK_TIME_AUDIO_DELAY) and vel != Vector2.ZERO and grounded():
		time_since_last_walk_audio = 0
		
		$Audio.stream = walking_sound
		$Audio.pitch_scale = randf_range(0.9, 1.1)
		$Audio.play()

func handle_shooting(delta):
	if Input.is_action_just_pressed("shoot") || Input.is_action_just_pressed("pass"):
		kick_charge = MIN_KICK_CHARGE
		
	check_for_shot_release()
	draw_charge_bar()
	charge_shot_bar(delta)

func charge_shot_bar(delta: float):
	if Input.is_action_pressed("shoot") || Input.is_action_pressed("pass"):
		kick_charge = min(kick_charge + (delta * KICK_CHARGE_INCREMENT), MAX_KICK_CHARGE)
	else:
		kick_charge = MIN_KICK_CHARGE

func draw_charge_bar():
	var line: Line2D = $Control2/Line2D
	# TODO: change the bar
	line.set_point_position(1, Vector2(0, -kick_charge * 5))

func check_for_shot_release():
	if (Input.is_action_just_released("shoot") || Input.is_action_just_released("pass")) and in_ball_kick_range():
		var height: bool = Input.is_action_just_released("shoot")
		ball.kicked(self, kick_direction, kick_charge, height)
		kick_timer = 0
		kick_charge = MIN_KICK_CHARGE
		
func in_ball_kick_range():
	return ball.global_position.distance_to(global_position) < BALL_KICK_RANGE
	
func bob_camera():
	var sprinting: bool = Input.is_action_pressed("sprint")
	var should_bob_slow: bool = not sprinting or velocity.length() <= 0.1
	var x: float = camera_bob * (SLOW_CAMERA_BOB_SPEED if should_bob_slow else FAST_CAMERA_BOB_SPEED)
	var height: float = sin(x) / (SLOW_CAMERA_BOB_HEIGHT if should_bob_slow else FAST_CAMERA_BOB_HEIGHT)
	camera.position.y = lerp(camera.position.y, original_cam_pos.y + height, CAMERA_BOB_LERP_SLEEP)
	
func set_kick_direction() -> void:
	if not camera_locked:
		if velocity != Vector3.ZERO:
			kick_direction = velocity.normalized()
	else:
		var temp_mouse_kick_direction: Vector3 = mouse_kick_direction
		temp_mouse_kick_direction.x = -temp_mouse_kick_direction.x
		kick_direction = -temp_mouse_kick_direction.normalized().rotated(Vector3.UP, rotation.y)

func movement(delta: float) -> Vector3:
	
	var wish_dir: Vector2 = Input.get_vector("left", "right", "up", "down")
	wish_dir = wish_dir.rotated(-rotation.y)
	
	var v_y: float = velocity.y;
	var v: Vector2 = Vector2(velocity.x, velocity.z)
	
	if grounded():
		v = wish_dir.normalized() * delta * current_run_speed
		
		if Input.is_action_just_pressed("jump"):
			v_y = JUMP_FORCE

	return Vector3(v.x, v_y, v.y)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if not camera_locked:
			update_camera_unlocked(event)
		else:
			update_mouse_kick_direction(event)

func update_mouse_kick_direction(event: InputEventMouseMotion) -> void:

	if abs(event.relative.x) > MOUSE_KICK_DIRECTION_MIN_MOVEMENT:
		mouse_kick_direction.x += event.relative.x  / MOUSE_KICK_DIRECTION_SPEED
		mouse_kick_direction.x = clamp(mouse_kick_direction.x, -1.0, 1.0)
		
	if abs(event.relative.y) > MOUSE_KICK_DIRECTION_MIN_MOVEMENT:
		mouse_kick_direction.z -= event.relative.y  / MOUSE_KICK_DIRECTION_SPEED
		mouse_kick_direction.z = clamp(mouse_kick_direction.z, -1.0, 1.0)
	
	var line: Line2D = $Control/Line2D
	#TODO: Change this
	line.set_point_position(1, Vector2(mouse_kick_direction.normalized().x * 20, -mouse_kick_direction.normalized().z * 20))
	
func update_camera_unlocked(event: InputEventMouseMotion) -> void:
	rotate(Vector3(0, -1, 0), event.relative.x * SENS)
	camera.rotate_x(-event.relative.y * SENS)
	camera.rotation.x = clamp(camera.global_rotation.x, deg_to_rad(-90), deg_to_rad(90))

func update_camera_locked() -> void:
	var target_direction = (ball.global_position - camera.global_position).normalized()
	var target_rotation = b.looking_at(target_direction).get_euler()
	
	camera.rotation = camera.rotation.slerp(Vector3(target_rotation.x, 0, 0), CAMERA_LERP_SPEED)
	rotation.y  = lerp_angle(rotation.y, target_rotation.y, CAMERA_LERP_SPEED)
	camera.rotation.x = clamp(camera.global_rotation.x, deg_to_rad(-30), deg_to_rad(30))
