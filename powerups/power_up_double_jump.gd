extends Area2D


func _on_body_entered(body: Node2D) -> void:
	# Check if the body that entered is the player
	if body.name == "Player" or body.has_method("is_player"):
		print("success")
		
		# Increase the player's jump count by 1
		if body.has_method("increase_jump_count"):
			body.increase_jump_count(1)
		elif "jump_count" in body:
			body.jump_count += 1
		else:
			print("Warning: Could not find jump_count property on player")
		
		# Remove the power-up from the world
		queue_free()
