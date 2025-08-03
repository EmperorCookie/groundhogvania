extends Area2D
@onready var collect_sound: AudioStreamPlayer = $CollectSound

func _on_body_entered(body: Node2D) -> void:
	# Check if the body that entered is the player
	if body.name == "Player" or body.has_method("is_player"):
		if body.current_hp > 0:
			print("success")
			collect_sound.play()
			
			# Increase the player's jump count by 1
			if body.has_method("increase_jump_count"):
				body.increase_jump_count(1)
			elif "jump_count" in body:
				body.jump_count += 1
				body.player_reset()
			else:
				print("Warning: Could not find jump_count property on player")
			
			# Hide the visual but keep the node alive for sound
			visible = false
			set_collision_mask_value(1, false)
			set_collision_layer_value(1, false)
			
			# Wait for sound to finish, then remove
			await collect_sound.finished
			queue_free()
