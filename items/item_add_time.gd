extends Area2D

var original_position: Vector2
var float_height: float = 4.0  # How many pixels to float up/down
var float_speed: float = 2.0    # How fast the floating animation is
@onready var collect_sound: AudioStreamPlayer = $CollectSound

func _ready():
	# Store the original position
	original_position = position
	
	# Create floating animation
	create_float_animation()

func create_float_animation():
	var tween = create_tween()
	tween.set_loops()  # Loop forever
	
	# Float up
	tween.tween_property(self, "position:y", original_position.y - float_height, float_speed)
	# Float down  
	tween.tween_property(self, "position:y", original_position.y + float_height, float_speed)

func _on_body_entered(body: Node2D) -> void:
	# Check if the body that entered is the player
	if body.name == "Player" or body.has_method("is_player"):
		if body.current_hp > 0:
			print("Added permanent time to the clock!")
			collect_sound.play()
			
			# Add permanent time to the players clock
			body.starting_time += 30
			body.player_reset()
			# Hide the visual but keep the node alive for sound
			visible = false
			set_collision_mask_value(1, false)
			set_collision_layer_value(1, false)
			
			# Wait for sound to finish, then remove
			await collect_sound.finished
			queue_free()
