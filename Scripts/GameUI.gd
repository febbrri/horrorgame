extends Control

@onready var noise_meter = $NoiseMeter

var player: CharacterBody2D = null

func _ready():
	player = get_tree().get_first_node_in_group("Player")

func _process(_delta):
	if not player:
		return
	noise_meter.value = player.noise_level
	
	# Warna berubah sesuai bahaya
	if player.noise_level > 0.7:
		noise_meter.modulate = Color.RED
	elif player.noise_level > 0.4:
		noise_meter.modulate = Color.YELLOW
	else:
		noise_meter.modulate = Color.WHITE
