extends CharacterBody2D

@export_category("Player Properties")
@export var move_speed : float = 400
@export var jump_force : float = 650
@export var gravity : float = 1800.0  # dinaikkan karena sekarang pakai delta
@export var max_jump_count : int = 2
var jump_count : int = 2

@export_category("Toggle Functions")
@export var double_jump : = false

var is_grounded : bool = false
var movement_enabled : bool = true
var noise_level : float = 0.0

@onready var player_sprite = $AnimatedSprite2D
@onready var spawn_point = %SpawnPoint
@onready var particle_trails = $ParticleTrails
@onready var death_particles = $DeathParticles

func _ready():
	add_to_group("Player")

func _physics_process(delta):
	movement(delta)

func _process(_delta):
	player_animations()
	flip_player()

func movement(delta):
	if !is_on_floor():
		velocity.y += gravity * delta  # FIX: pakai delta
	elif is_on_floor():
		jump_count = max_jump_count

	handle_jumping()

	var inputAxis = 0.0
	if movement_enabled:
		inputAxis = Input.get_axis("Left", "Right")
	velocity.x = inputAxis * move_speed
	move_and_slide()

	# Noise system
	if abs(inputAxis) > 0:
		noise_level += 0.015
	else:
		noise_level -= 0.025
	noise_level = clamp(noise_level, 0.0, 1.0)

func handle_jumping():
	if Input.is_action_just_pressed("Jump") and movement_enabled:
		if is_on_floor() and !double_jump:
			jump()
		elif double_jump and jump_count > 0:
			jump()
			jump_count -= 1

func jump():
	jump_tween()
	AudioManager.jump_sfx.play()
	velocity.y = -jump_force

func player_animations():
	particle_trails.emitting = false
	if is_on_floor():
		if abs(velocity.x) > 0:
			particle_trails.emitting = true
			player_sprite.play("Walk", 1.5)
		else:
			player_sprite.play("Idle")
	else:
		player_sprite.play("Jump")

func flip_player():
	if velocity.x < 0:
		player_sprite.flip_h = true
	elif velocity.x > 0:
		player_sprite.flip_h = false

func death_tween():
	movement_enabled = false
	var tween = create_tween()
	tween.tween_property(player_sprite, "scale", Vector2.ZERO, 0.15)
	tween.parallel().tween_property(player_sprite, "position", Vector2.ZERO, 0.15)
	await tween.finished
	global_position = spawn_point.global_position
	await get_tree().create_timer(0.3).timeout
	movement_enabled = true
	AudioManager.respawn_sfx.play()
	respawn_tween()

func respawn_tween():
	var tween = create_tween()
	tween.stop(); tween.play()
	tween.tween_property(player_sprite, "scale", Vector2.ONE, 0.15)
	tween.parallel().tween_property(player_sprite, "position", Vector2(0,-48), 0.15)

func jump_tween():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.7, 1.4), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func _on_collision_body_entered(body):
	if body.is_in_group("Traps"):
		AudioManager.death_sfx.play()
		death_particles.emitting = true
		death_tween()
