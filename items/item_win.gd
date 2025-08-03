extends Area2D
@onready var collect_sound: AudioStreamPlayer = $CollectSound
@onready var player_hud = get_node("../PlayerHud")

func _on_body_entered(body: Node2D) -> void:
	# Check if the body that entered is the player
	if body.name == "Player" or body.has_method("is_player"):
		if body.current_hp > 0:
			print("You Win!")
			collect_sound.play()
			player_hud.level_complete()
						# Hide the visual but keep the node alive for sound
			visible = false
			set_collision_mask_value(1, false)
			set_collision_layer_value(1, false)
			
			# Wait for sound to finish, then remove
			await collect_sound.finished
			queue_free()
