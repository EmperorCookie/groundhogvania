extends Area2D

var original_position: Vector2
var float_height: float = 4.0  # How many pixels to float up/down
var float_speed: float = 2.0    # How fast the floating animation is

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
			print("Picked up a heart!")
			
			# Give the player +1 HP
			body.player_heal()
			
			# Remove the item from the world
			body.player_reset()
			queue_free()
