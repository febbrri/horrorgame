extends CharacterBody2D

# ─────────────────────────────────────────────────────────────────────────────
# Hansen.gd — Cold Ground
# AI 3 state: PATROL → ALERT → CHASE
# Hansen tidak pernah terlihat. Audio-only presence.
# ─────────────────────────────────────────────────────────────────────────────

enum State { PATROL, ALERT, CHASE }
var state = State.PATROL

@export var patrol_speed: float = 80.0
@export var alert_speed: float  = 130.0
@export var chase_speed: float  = 220.0
@export var gravity: float      = 1800.0
@export var hearing_radius: float = 350.0
@export var noise_threshold: float = 0.55

var player: CharacterBody2D = null
var alert_timer: float = 0.0
var patrol_dir: float = 1.0
var patrol_timer: float = 0.0

# ─── FOOTSTEP TIMER ──────────────────────────────────────────────────────────
var _step_timer: float = 0.0
const PATROL_STEP_INTERVAL := 0.70  # Langkah lambat, teratur
const ALERT_STEP_INTERVAL  := 0.42  # Langkah lebih cepat

var _prev_state = State.PATROL

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("Hansen")
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta: float) -> void:
	if not player:
		return

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	var dist: float    = global_position.distance_to(player.global_position)
	var p_noise: float = player.noise_level

	# ─── Handle state transition audio ─────────────────────────────
	if state != _prev_state:
		_on_state_changed(state)
		_prev_state = state

	# ─── State machine ─────────────────────────────────────────────
	match state:
		State.PATROL:
			_patrol(delta)
			if p_noise > noise_threshold and dist < hearing_radius:
				state = State.ALERT
				alert_timer = 8.0
				_step_timer = 0.0

		State.ALERT:
			_move_toward_player(alert_speed)
			alert_timer -= delta
			_step_timer -= delta
			if _step_timer <= 0.0:
				_step_timer = ALERT_STEP_INTERVAL
				AudioManager.play_hansen_step(-2.0)  # Lebih keras saat alert

			if dist < 60:
				state = State.CHASE
				_step_timer = 0.0
			elif alert_timer <= 0 or dist > hearing_radius * 1.5:
				state = State.PATROL
				_step_timer = 0.0

		State.CHASE:
			_move_toward_player(chase_speed)
			if dist < 30:
				GameManager.trigger_ending("caught")
			elif dist > hearing_radius * 2:
				state = State.PATROL
				_step_timer = 0.0

	move_and_slide()

func _on_state_changed(new_state: int) -> void:
	match new_state:
		State.CHASE:
			# Saat Chase: langkah Hansen hilang (GDD rule)
			AudioManager.stop_hansen_step()
		State.PATROL, State.ALERT:
			# Reset step timer supaya langkah pertama muncul segera
			_step_timer = 0.0

func _patrol(delta: float) -> void:
	patrol_timer -= delta
	_step_timer  -= delta

	if patrol_timer <= 0:
		patrol_dir   *= -1
		patrol_timer  = randf_range(2.0, 5.0)
	if is_on_wall():
		patrol_dir   *= -1
		patrol_timer  = randf_range(2.0, 5.0)

	velocity.x = patrol_dir * patrol_speed

	# Footstep Hansen saat patrol
	if _step_timer <= 0.0:
		_step_timer = PATROL_STEP_INTERVAL
		AudioManager.play_hansen_step(-4.0)  # Lebih pelan saat patrol

func _move_toward_player(speed: float) -> void:
	var dir: float = sign(player.global_position.x - global_position.x)
	velocity.x = dir * speed
