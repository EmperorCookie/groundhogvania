extends CanvasLayer

# Timer variables
var seconds: int = 60  # 1 minute in seconds
var timer: Timer
@onready var restart_timer_label: Label = $Control/BoxContainer/restart_timer

# HP system variables
var hp: int = 2  # Hard coded current HP value
var max_hp: int = 2  # Maximum HP segments
@onready var hp_container: HBoxContainer = $Control/HPContainer
var hp_segments: Array[ColorRect] = []
var hp_shadows: Array[ColorRect] = []  # Shadow/silhouette segments

# Animation variables
# Note: Tweens are created with create_tween() in Godot 4, not stored as variables

# Developer buttons
@onready var dev_buttons: VBoxContainer = $Control/DevButtons
@onready var take_damage_btn: Button = $Control/DevButtons/TakeDamageBtn
@onready var heal_btn: Button = $Control/DevButtons/HealBtn
@onready var add_segment_btn: Button = $Control/DevButtons/AddSegmentBtn
@onready var remove_segment_btn: Button = $Control/DevButtons/RemoveSegmentBtn

func _ready():
	# Initialize HP system
	setup_hp_system()
	
	# Setup developer buttons (only visible in debug builds)
	setup_dev_buttons()
	
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

func setup_dev_buttons():
	# Only show developer buttons in debug builds (editor/development)
	if OS.is_debug_build():
		dev_buttons.visible = true
		# Connect button signals
		take_damage_btn.pressed.connect(_on_take_damage_pressed)
		heal_btn.pressed.connect(_on_heal_pressed)
		add_segment_btn.pressed.connect(_on_add_segment_pressed)
		remove_segment_btn.pressed.connect(_on_remove_segment_pressed)
	else:
		dev_buttons.visible = false

func setup_hp_system():
	# Clear any existing segments first
	for child in hp_container.get_children():
		child.free()  # Use free() instead of queue_free() for immediate removal
	
	hp_segments.clear()
	hp_shadows.clear()
	
	print("Setting up HP system with max_hp: ", max_hp, " current hp: ", hp)
	
	# Create paired shadow and active segments
	for i in range(max_hp):
		# Create a container for each HP segment pair
		var segment_container = Control.new()
		segment_container.layout_mode = 2
		segment_container.custom_minimum_size = Vector2(75, 20)
		segment_container.name = "HPSegment" + str(i)
		hp_container.add_child(segment_container)
		
		# Create shadow segment (background)
		var shadow_segment = ColorRect.new()
		shadow_segment.layout_mode = 1
		shadow_segment.anchors_preset = 15  # Full rect
		shadow_segment.color = Color(0, 0, 0, 0.6)  # Black with 60% opacity
		shadow_segment.name = "Shadow" + str(i)
		segment_container.add_child(shadow_segment)
		hp_shadows.append(shadow_segment)
		
		# Create active segment (foreground)
		var active_segment = ColorRect.new()
		active_segment.layout_mode = 1
		active_segment.anchors_preset = 15  # Full rect
		active_segment.color = Color.RED
		active_segment.name = "Active" + str(i)
		segment_container.add_child(active_segment)
		hp_segments.append(active_segment)
		
		print("Created segment ", i, " - Shadow: ", shadow_segment.color, " Active: ", active_segment.color)
	
	# Update HP display
	update_hp_display()

func update_hp_display():
	print("Updating HP display - Current HP: ", hp, " Max HP: ", max_hp)
	print("HP segments count: ", hp_segments.size(), " Shadow segments count: ", hp_shadows.size())
	
	# Update visibility of active HP segments based on current HP
	for i in range(hp_segments.size()):
		if i < hp:
			# Show this HP segment (full health)
			hp_segments[i].visible = true
			print("Segment ", i, " - VISIBLE (red)")
		else:
			# Hide this HP segment (lost health) - shadow will still show
			hp_segments[i].visible = false
			print("Segment ", i, " - HIDDEN (shadow should show)")
	
	# Ensure shadows are always visible
	for i in range(hp_shadows.size()):
		hp_shadows[i].visible = true
		print("Shadow ", i, " - VISIBLE (gray)")

func take_damage(damage: int = 1):
	# Function to handle taking damage
	var old_hp = hp
	hp = max(0, hp - damage)
	
	# Animate the lost HP segments
	for i in range(old_hp - 1, hp - 1, -1):  # From last HP to current HP
		if i < hp_segments.size():
			animate_damage(hp_segments[i])
	
	# Update display after a short delay to let animation start
	await get_tree().create_timer(0.1).timeout
	update_hp_display()
	
	if hp <= 0:
		print("Player died!")

func animate_damage(segment: ColorRect):
	# Simple flash animation for damage
	var original_color = segment.color
	
	# Create a new tween for this animation
	var damage_tween = create_tween()
	
	# Flash white briefly, then back to red
	damage_tween.tween_property(segment, "color", Color.WHITE, 0.1)
	damage_tween.tween_property(segment, "color", original_color, 0.1)

func heal(amount: int = 1):
	# Function to handle healing
	var old_hp = hp
	hp = min(max_hp, hp + amount)  # Cap at max HP
	
	# Animate the restored HP segments
	for i in range(old_hp, hp):
		if i < hp_segments.size():
			animate_heal(hp_segments[i])
	
	update_hp_display()

func animate_heal(segment: ColorRect):
	# Simple flash animation for healing
	var original_color = segment.color
	
	# Create a new tween for this animation
	var heal_tween = create_tween()
	
	# Flash green briefly, then back to red
	heal_tween.tween_property(segment, "color", Color.GREEN, 0.15)
	heal_tween.tween_property(segment, "color", original_color, 0.15)

func add_hp_segment():
	# Add a new HP segment (increase max HP)
	var lost_hp = max_hp - hp  # Calculate how much HP was lost
	max_hp += 1
	hp = max_hp - lost_hp  # Maintain the same amount of lost HP
	
	# Create a container for the new HP segment pair
	var segment_container = Control.new()
	segment_container.layout_mode = 2
	segment_container.custom_minimum_size = Vector2(75, 20)
	hp_container.add_child(segment_container)
	
	# Create shadow segment (background)
	var new_shadow = ColorRect.new()
	new_shadow.layout_mode = 1
	new_shadow.anchors_preset = 15  # Full rect
	new_shadow.color = Color(0, 0, 0, 0.6)  # Black with 60% opacity
	segment_container.add_child(new_shadow)
	hp_shadows.append(new_shadow)
	
	# Create active segment (foreground)
	var new_segment = ColorRect.new()
	new_segment.layout_mode = 1
	new_segment.anchors_preset = 15  # Full rect
	new_segment.color = Color.RED
	segment_container.add_child(new_segment)
	hp_segments.append(new_segment)
	
	# Animate the new segment with a flash
	animate_new_segment_flash(new_segment)
	
	update_hp_display()

func animate_new_segment_flash(segment: ColorRect):
	# Simple flash animation for new segment
	var original_color = segment.color
	
	# Create a new tween for this animation
	var new_segment_tween = create_tween()
	
	# Flash gold/yellow briefly, then back to red
	new_segment_tween.tween_property(segment, "color", Color.YELLOW, 0.2)
	new_segment_tween.tween_property(segment, "color", original_color, 0.2)

func remove_hp_segment():
	# Remove an HP segment (decrease max HP)
	if max_hp > 1:  # Don't go below 1 max HP
		max_hp -= 1
		hp = min(hp, max_hp)  # Adjust current HP if needed
		
		# Remove the last active segment
		if hp_segments.size() > 0:
			hp_segments.pop_back()
		
		# Remove the last shadow segment
		if hp_shadows.size() > 0:
			hp_shadows.pop_back()
		
		# Remove the last container (which contains both shadow and active)
		var children = hp_container.get_children()
		if children.size() > 0:
			children[-1].queue_free()
		
		update_hp_display()

# Developer button handlers
func _on_take_damage_pressed():
	take_damage(1)

func _on_heal_pressed():
	heal(1)

func _on_add_segment_pressed():
	add_hp_segment()

func _on_remove_segment_pressed():
	remove_hp_segment()

func _on_timer_timeout():
	# Decrease seconds and update display
	if seconds > 0:
		seconds -= 1
	update_timer_display()

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
