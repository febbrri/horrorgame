extends Node

# ─────────────────────────────────────────────────────────────────────────────
# AudioManager.gd — Cold Ground
# Autoload. Mengelola seluruh audio game: wind, footstep, heartbeat, dll.
# ─────────────────────────────────────────────────────────────────────────────

# ─── EXISTING SFX (dari starter kit, tetap dipakai) ──────────────────────────
@onready var jump_sfx: AudioStreamPlayer        = $JumpSfx
@onready var death_sfx: AudioStreamPlayer       = $DeathSfx
@onready var respawn_sfx: AudioStreamPlayer     = $RespawnSfx
@onready var level_complete_sfx: AudioStreamPlayer = $LevelCompleteSfx

# ─── COLD GROUND AUDIO STREAMS ───────────────────────────────────────────────
# Assign file audio di sini setelah download. Drag & drop dari FileSystem ke Inspector.
@export_group("Cold Ground SFX")
@export var wind_stream: AudioStream            ## Loop angin Alaska. Cari: "arctic wind loop"
@export var footstep_snow_stream: AudioStream   ## Langkah di salju. Cari: "footstep snow crunch"
@export var footstep_dirt_stream: AudioStream   ## Langkah di tanah. Cari: "footstep dirt gravel"
@export var hansen_step_stream: AudioStream     ## Langkah Hansen. Cari: "heavy boot footstep"
@export var heartbeat_stream: AudioStream       ## Heartbeat. Cari: "heartbeat loop"
@export var breathing_stream: AudioStream       ## Napas. Cari: "heavy breathing loop horror"

# ─── AUDIO PLAYERS (dibuat otomatis, tidak perlu edit .tscn) ─────────────────
var wind_player: AudioStreamPlayer
var footstep_snow_player: AudioStreamPlayer
var footstep_dirt_player: AudioStreamPlayer
var hansen_footstep_player: AudioStreamPlayer
var heartbeat_player: AudioStreamPlayer
var breathing_player: AudioStreamPlayer

# ─── KONSTANTA VOLUME ────────────────────────────────────────────────────────
const WIND_NORMAL_DB  := -8.0   # Volume angin saat Hansen jauh
const WIND_SILENT_DB  := -80.0  # Volume angin saat Hansen sangat dekat (near-silent)
const WIND_LERP_SPEED := 0.04   # Kecepatan fade wind (0.04 = smooth, tidak mendadak)

# ─── REFERENSI NODE ──────────────────────────────────────────────────────────
var _hansen: CharacterBody2D = null
var _player: CharacterBody2D = null
var _prev_chase_state: bool = false

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_create_cold_ground_players()
	# Pakai call_deferred supaya scene sudah fully loaded sebelum cari node
	call_deferred("_init_scene_refs")

func _create_cold_ground_players() -> void:
	wind_player            = _new_player("WindAmbient")
	footstep_snow_player   = _new_player("FootstepSnow")
	footstep_dirt_player   = _new_player("FootstepDirt")
	hansen_footstep_player = _new_player("HansenFootstep")
	heartbeat_player       = _new_player("Heartbeat")
	breathing_player       = _new_player("Breathing")

func _new_player(node_name: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = node_name
	add_child(p)
	return p

func _init_scene_refs() -> void:
	_find_refs()
	_start_wind()

func _find_refs() -> void:
	_hansen = get_tree().get_first_node_in_group("Hansen") as CharacterBody2D
	_player = get_tree().get_first_node_in_group("Player") as CharacterBody2D

func _start_wind() -> void:
	if not wind_stream:
		return
	wind_player.stream = wind_stream
	wind_player.volume_db = WIND_NORMAL_DB
	wind_player.play()
	# Loop: sambung ulang otomatis saat selesai
	if not wind_player.finished.is_connected(wind_player.play):
		wind_player.finished.connect(wind_player.play)

# ─────────────────────────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	# Re-find refs saat scene berganti (Hansen/Player baru di-spawn)
	if not is_instance_valid(_hansen):
		_find_refs()
		_start_wind()
		return
	if not is_instance_valid(_player):
		_find_refs()
		return

	_update_wind_volume()
	_update_chase_audio()

# ─── WIND VOLUME ─────────────────────────────────────────────────────────────
func _update_wind_volume() -> void:
	if not wind_player.playing:
		return

	var dist: float = _hansen.global_position.distance_to(_player.global_position)
	var hearing_r: float = _hansen.hearing_radius

	# Wind mulai fade saat Hansen < hearing_radius
	# Wind near-silent saat Hansen < hearing_radius * 0.25
	var ratio: float = clamp(
		(dist - hearing_r * 0.25) / (hearing_r * 0.75),
		0.0, 1.0
	)
	var target_db: float = lerp(WIND_SILENT_DB, WIND_NORMAL_DB, ratio)
	wind_player.volume_db = lerp(wind_player.volume_db, target_db, WIND_LERP_SPEED)

# ─── HEARTBEAT & BREATHING SAAT CHASE ────────────────────────────────────────
func _update_chase_audio() -> void:
	var in_chase: bool = (_hansen.state == _hansen.State.CHASE)

	if in_chase:
		_ensure_looping(heartbeat_player, heartbeat_stream, -20.0)
		_ensure_looping(breathing_player, breathing_stream, -10.0)

		# Heartbeat makin keras saat makin dekat
		var dist: float = _hansen.global_position.distance_to(_player.global_position)
		var t: float = clamp(1.0 - (dist / 200.0), 0.0, 1.0)
		heartbeat_player.volume_db = lerp(-20.0, -3.0, t)

	elif _prev_chase_state:
		# Baru keluar dari Chase — fade out
		_fade_out_and_stop(heartbeat_player, 1.5)
		_fade_out_and_stop(breathing_player, 1.0)

	_prev_chase_state = in_chase

func _ensure_looping(p: AudioStreamPlayer, stream: AudioStream, start_db: float) -> void:
	if p.playing or not stream:
		return
	p.stream = stream
	p.volume_db = start_db
	p.play()
	if not p.finished.is_connected(p.play):
		p.finished.connect(p.play)

func _fade_out_and_stop(p: AudioStreamPlayer, duration: float) -> void:
	# Guard: jangan fade ganda
	if p.get_meta("fading", false) or not p.playing:
		return
	p.set_meta("fading", true)

	var tw := create_tween()
	tw.tween_property(p, "volume_db", WIND_SILENT_DB, duration)
	tw.tween_callback(func():
		p.stop()
		p.remove_meta("fading")
		if p.finished.is_connected(p.play):
			p.finished.disconnect(p.play)
	)

# ─────────────────────────────────────────────────────────────────────────────
# PUBLIC API — dipanggil dari script lain
# ─────────────────────────────────────────────────────────────────────────────

## Dipanggil dari player.gd setiap kali satu langkah diambil.
## is_snow = true → suara salju. is_running = true → volume lebih keras.
func play_footstep(is_snow: bool, is_running: bool) -> void:
	var target_player := footstep_snow_player if is_snow else footstep_dirt_player
	var stream       := footstep_snow_stream   if is_snow else footstep_dirt_stream

	if not stream or target_player.playing:
		return

	target_player.stream      = stream
	target_player.volume_db   = 0.0 if is_running else -7.0
	target_player.pitch_scale = randf_range(0.92, 1.08)  # variasi supaya tidak monoton
	target_player.play()

## Dipanggil dari Hansen.gd setiap langkah Hansen (saat Patrol/Alert).
func play_hansen_step(volume_db: float = -4.0) -> void:
	if not hansen_step_stream or hansen_footstep_player.playing:
		return
	hansen_footstep_player.stream      = hansen_step_stream
	hansen_footstep_player.volume_db   = volume_db
	hansen_footstep_player.pitch_scale = randf_range(0.88, 1.05)
	hansen_footstep_player.play()

## Dipanggil dari Hansen.gd saat masuk Chase state.
func stop_hansen_step() -> void:
	hansen_footstep_player.stop()

## Stop semua audio Cold Ground (misal saat masuk Ending scene).
func stop_all_ambient() -> void:
	wind_player.stop()
	heartbeat_player.stop()
	breathing_player.stop()
	hansen_footstep_player.stop()
