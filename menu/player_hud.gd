extends CanvasLayer

# Timer variables
var seconds: int = 0  # Will be set from player's starting_time
var timer: Timer
var timer_paused: bool = false
var pause_time_remaining: float = 0.0
@onready var restart_timer_label: Label = $Control/BoxContainer/restart_timer

# HP system variables
@onready var hp_container: HBoxContainer = $Control/HPContainer
@onready var hp_segment_1: ColorRect = $Control/HPContainer/HP1
@onready var hp_segment_2: ColorRect = $Control/HPContainer/HP2

# Music
@onready var level_music: AudioStreamPlayer = $LevelMusic

func _ready():
	# Initialize values from player
	initialize_from_player()
	
	# Setup timer intro animation
	setup_timer_intro()
	
	# Create and configure the timer
	timer = Timer.new()
	timer.wait_time = 1.0  # 1 second interval
	timer.timeout.connect(_on_timer_timeout)
	timer.autostart = true
	add_child(timer)
	
	# Display initial time on label
	update_timer_display()
	
	# Initialize HP display from player
	call_deferred("initialize_hp_from_player")



func initialize_from_player():
	# Get reference to the player node (direct sibling reference)
	var player = get_node("../Player")
	
	if player:
		# Pull values from player
		seconds = player.starting_time
		print("Initialized HUD from player - Time: ", seconds, "s")
		var current_hp = player.current_hp
		print("Getting HP from player: ", current_hp)
		update_segments(current_hp)
	else:
		# Fallback values if player not found
		seconds = 45
		print("Player not found, using fallback time: ", seconds, "s")
		update_segments(1)
		print("Player not found, using fallback of 1 hp")



func setup_timer_intro():
	# Get the timer container (BoxContainer)
	var timer_container = $Control/BoxContainer
	var timer_label = restart_timer_label
	
	# Store the final position
	var final_position = timer_container.position
	
	# Start the timer in the center of the screen
	var screen_center_x = 640 / 2  # Half of screen width
	var screen_center_y = 360 / 2  # Half of screen height
	
	# Position timer container at center (accounting for its size)
	timer_container.position = Vector2(screen_center_x - 20, screen_center_y - 20)
	
	# Start flashing animation
	var flash_tween = create_tween()
	flash_tween.set_loops()  # Loop indefinitely
	flash_tween.tween_property(timer_label, "modulate", Color.WHITE, 0.4)
	flash_tween.tween_property(timer_label, "modulate", Color.YELLOW, 0.4)
	
	# Wait 1.5 seconds before moving
	await get_tree().create_timer(2.0).timeout
	
	# Stop the flashing
	flash_tween.kill()
	
	# Animate timer floating up with smooth bounce effect
	var intro_tween = create_tween()
	intro_tween.set_parallel(true)  # Allow parallel animations
	
	# Use back easing for a smooth overshoot and settle effect
	intro_tween.set_ease(Tween.EASE_OUT)
	intro_tween.set_trans(Tween.TRANS_BACK)
	
	# Single smooth movement to final position with bounce
	intro_tween.tween_property(timer_container, "position", final_position, 1.0)
	
	# Fade flash effect as it moves up
	intro_tween.tween_property(timer_label, "modulate", Color.WHITE, 1.0)



func update_segments(current_hp: int):
	print("update_segments called with HP: ", current_hp)
	
	# Check if HP segments are ready
	if not hp_segment_1 or not hp_segment_2:
		print("HP segments not ready yet, trying to get them manually...")
		hp_segment_1 = $Control/HPContainer/HP1
		hp_segment_2 = $Control/HPContainer/HP2
		
		if not hp_segment_1 or not hp_segment_2:
			print("Error: HP segments still not found!")
			return
	
	# Update HP segments based on current HP (0, 1, or 2)
	match current_hp:
		0:
			hp_segment_1.visible = false
			hp_segment_2.visible = false
			print("Both segments HIDDEN")
		1:
			hp_segment_1.visible = true
			hp_segment_2.visible = false
			print("Segment 1 VISIBLE, Segment 2 HIDDEN")
		2:
			hp_segment_1.visible = true
			hp_segment_2.visible = true
			print("Both segments VISIBLE")
		_:
			print("Invalid HP value: ", current_hp)



func _on_timer_timeout():
	# If timer is paused, count down pause time instead
	if timer_paused:
		pause_time_remaining -= 1.0
		if pause_time_remaining <= 0:
			timer_paused = false
			print("Timer unpaused!")
		return
	
	# Normal timer countdown
	if seconds > 0:
		seconds -= 1
	update_timer_display()

func pause_timer(pause_duration: float):
	# Pause the timer for a specific duration
	timer_paused = true
	pause_time_remaining = pause_duration
	print("Timer paused for ", pause_duration, " seconds")

func unpause_timer():
	# Manually unpause the timer
	timer_paused = false
	pause_time_remaining = 0.0
	print("Timer manually unpaused!")



func update_timer_display():
	# Convert seconds to minutes:seconds format and update label
	var minutes: int = int(seconds / 60)  # Convert to int after division
	var remaining_seconds: int = seconds % 60
	var time_string = "%d:%02d" % [minutes, remaining_seconds]
	
	# Check if the label exists before trying to update it
	if restart_timer_label:
		restart_timer_label.text = time_string
	else:
		print("Warning: restart_timer label not found!")
	
	print("Current time: " + time_string)  # Keep debug print for now



func _on_take_damage_btn_pressed() -> void:
	var player = get_node("../Player")
	player.player_take_damage()




func _on_heal_btn_pressed() -> void:
	var player = get_node("../Player")
	player.player_heal()


func _play_music() -> void:
	# Start level music when the player is ready
	if level_music and not level_music.playing:
		level_music.volume_db = -12.0  # Reset volume to normal level
		level_music.play()
		
func _stop_music() -> void:
	if level_music and level_music.playing:
		# Create a tween to fade out the music
		var tween = create_tween()
		tween.tween_property(level_music, "volume_db", -80.0, 1.5)  # Fade to silence over 1.5 seconds
		tween.tween_callback(level_music.stop)  # Stop the music after fade completes
