extends CharacterBody2D

enum State { PATROL, ALERT, CHASE }
var state = State.PATROL

@export var patrol_speed: float = 80.0
@export var alert_speed: float = 130.0
@export var chase_speed: float = 220.0
@export var gravity: float = 1800.0
@export var hearing_radius: float = 350.0
@export var noise_threshold: float = 0.55

var player: CharacterBody2D = null
var alert_timer: float = 0.0
var patrol_dir: float = 1.0
var patrol_timer: float = 0.0

func _ready() -> void:
	add_to_group("Hansen")
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta: float) -> void:
	if not player:
		return

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	var dist = global_position.distance_to(player.global_position)
	var p_noise = player.noise_level

	match state:
		State.PATROL:
			_patrol(delta)
			if p_noise > noise_threshold and dist < hearing_radius:
				state = State.ALERT
				alert_timer = 8.0

		State.ALERT:
			_move_toward_player(alert_speed)
			alert_timer -= delta
			if dist < 60:
				state = State.CHASE
			elif alert_timer <= 0 or dist > hearing_radius * 1.5:
				state = State.PATROL

		State.CHASE:
			_move_toward_player(chase_speed)
			if dist < 30:
				GameManager.trigger_ending("caught")
			elif dist > hearing_radius * 2:
				state = State.PATROL

	move_and_slide()

func _patrol(delta: float) -> void:
	patrol_timer -= delta
	if patrol_timer <= 0:
		patrol_dir *= -1
		patrol_timer = randf_range(2.0, 5.0)
	if is_on_wall():
		patrol_dir *= -1
		patrol_timer = randf_range(2.0, 5.0)
	velocity.x = patrol_dir * patrol_speed

func _move_toward_player(speed: float) -> void:
	var dir = sign(player.global_position.x - global_position.x)
	velocity.x = dir * speed
