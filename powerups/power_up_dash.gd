extends Area2D
@onready var collect_sound: AudioStreamPlayer = $CollectSound

func _on_body_entered(body: Node2D) -> void:
	# Check if the body that entered is the player
	if body.name == "Player" or body.has_method("is_player"):
		if body.current_hp > 0:
			print("success")
			collect_sound.play()
			
			# Give the player the ability to dash
			if "can_dash" in body:
				body.can_dash = true
				body.player_reset()
			else:
				print("Warning: Could not find can_dash property on player")
			
			# Hide the visual but keep the node alive for sound
			visible = false
			set_collision_mask_value(1, false)
			set_collision_layer_value(1, false)
			
			# Wait for sound to finish, then remove
			await collect_sound.finished
			queue_free()
