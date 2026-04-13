extends Button

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	SceneTransition.load_scene(
		load("res://Scenes/Levels/Level_01.tscn")
	)
