extends Area2D


func _on_body_entered(body: Node2D) -> void:
	# Check if the body that entered is the player
	if body.name == "Player" or body.has_method("is_player"):
		print("success")
		
		# Give the player the ability to dash
		if "can_dash" in body:
			body.can_dash = true
		else:
			print("Warning: Could not find can_dash property on player")
		
		# Remove the power-up from the world
		queue_free()
