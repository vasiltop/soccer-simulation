extends RigidBody3D

class_name Ball

const DRIBBLE_FORCE = 24.0;

@onready var origin_pos = $BallDir.position
@onready var audio_player = $Audio
var ball_kick_sound = preload("res://sounds/ball_kick.mp3")

func _ready():
	$Area3D.body_entered.connect(body_entered)

func _physics_process(delta):
	pass

func body_entered(body: Node):
	if not body is CharacterBody3D: return
	
	#linear_velocity = Vector3.ZERO
	$BallDir.position = origin_pos
	
	var b = body as CharacterBody3D
	
	if b.kick_charge != 1: return
	if b.kick_timer < b.KICK_DELAY: return

	b.kick_timer = 0
	
	var dir = Vector3(b.kick_direction.x, 0.0, b.kick_direction.z)
	$BallDir.position = $BallDir.position + dir * 2
	
	audio_player.stream = ball_kick_sound
	audio_player.play()
	
	var v = 1.5 if b is NpcPlayer else (b.velocity.length() / 5)
	apply_impulse(dir * DRIBBLE_FORCE * v)

func kicked(body: Node, force: float, height = false):
	if body.kick_timer < body.KICK_DELAY: return
	var dir = Vector3(body.kick_direction.x * force, force / 4 if height else force / 30, body.kick_direction.z * force)
	audio_player.stream = ball_kick_sound
	audio_player.play()
	body.kick_timer = 0
	var bv = (body.velocity.length() / 10)
	var v = max(bv, 0.6)
	apply_impulse(dir * v * 15)
