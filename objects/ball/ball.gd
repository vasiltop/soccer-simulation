extends RigidBody3D

class_name Ball

@onready var audio_player = $Audio
@onready var collider = $Area3D

const DRIBBLE_FORCE: float = 20.0
const KICK_FORCE: float = 15.0
const VELOCITY_BALL_FORCE_SLOWDOWN: float = 5.0
const SHOT_HEIGHT: float = 4.0
const PASS_HEIGHT: float = 30.0
const MIN_VELOCITY_AFFECT: float = 0.6

var ball_kick_sound = preload("res://sounds/ball_kick.mp3")

func _physics_process(delta):
	var col = collider.get_overlapping_bodies()
	
	if len(col) > 0 and col[0] is Humanoid:
		dribble(col[0])

func dribble(player: Humanoid):

	if player.kick_charge != 1: return
	if player.kick_timer < player.KICK_DELAY: return
	
	player.kick_timer = 0
	linear_velocity = Vector3.ZERO
	
	var dir = Vector3(player.kick_direction.x, 0.0, player.kick_direction.z)
	audio_player.stream = ball_kick_sound
	audio_player.play()
	
	apply_impulse(dir * DRIBBLE_FORCE * player.velocity.length() / VELOCITY_BALL_FORCE_SLOWDOWN)

func kicked(body: Humanoid, direction: Vector3, force: float, height = false):
	if body.kick_timer < body.KICK_DELAY: return
	
	var yforce = force / SHOT_HEIGHT if height else force / PASS_HEIGHT
	var dir = Vector3(direction.x * force, yforce, direction.z * force)
	audio_player.stream = ball_kick_sound
	audio_player.play()
	body.kick_timer = 0
	var bv = (body.velocity.length() / VELOCITY_BALL_FORCE_SLOWDOWN / 2)
	var v = max(bv, MIN_VELOCITY_AFFECT)
	apply_impulse(dir * v * KICK_FORCE)
