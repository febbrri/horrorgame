extends Area2D

func _on_body_entered(body):
	if body.is_in_group("Player"):
		AudioManager.level_complete_sfx.play()
		GameManager.trigger_ending("escape")
