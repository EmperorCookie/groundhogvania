extends Node

# Dictionary to store original enemy data for respawning
var original_enemies: Array[Dictionary] = []

func _ready():
	# Store original enemy data
	store_original_enemies()

func store_original_enemies():
	# Loop through all children and store their data for respawning
	for child in get_children():
		if child.has_method("_physics_process"):  # Basic check if it's an enemy
			var enemy_data = {
				"scene_path": child.scene_file_path,
				"name": child.name,
				"position": child.global_position,
				"player_reference": child.player if child.has_method("get") else null
			}
			original_enemies.append(enemy_data)
			print("Stored enemy data for: ", child.name, " at position: ", child.global_position)

func reset_all_enemies():
	# Reset all enemies to their original positions and respawn any missing ones
	print("Resetting all enemies...")
	
	for enemy_data in original_enemies:
		var enemy_exists = false
		var existing_enemy = null
		
		# Check if this enemy still exists
		for child in get_children():
			if child.name == enemy_data["name"]:
				enemy_exists = true
				existing_enemy = child
				break
		
		# If enemy exists, reset its position and state
		if enemy_exists and existing_enemy:
			print("Resetting existing enemy: ", existing_enemy.name)
			existing_enemy.global_position = enemy_data["position"]
			# Reset enemy state variables
			existing_enemy.neutralized = false
			existing_enemy.target = null
			existing_enemy.bounce = Vector2.ZERO
			existing_enemy.velocity = Vector2.ZERO
		# If enemy doesn't exist, respawn it
		else:
			respawn_enemy(enemy_data)

func respawn_enemy(enemy_data: Dictionary):
	print("Respawning enemy: ", enemy_data["name"])
	
	# Load the bee scene (you might need to adjust this path)
	var bee_scene = preload("res://enemies/bee/bee.tscn")
	var new_bee = bee_scene.instantiate()
	
	# Set up the new bee
	new_bee.name = enemy_data["name"]
	new_bee.global_position = enemy_data["position"]
	
	# Set player reference if it exists
	if enemy_data["player_reference"]:
		new_bee.player = enemy_data["player_reference"]
	
	# Add to the scene
	add_child(new_bee)
	
	print("Respawned enemy: ", enemy_data["name"], " at position: ", enemy_data["position"])
