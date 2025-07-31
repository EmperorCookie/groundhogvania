extends Node2D

# Timer variables
var seconds: int = 60  # 1 minute in seconds
var timer: Timer
@onready var restart_timer_label: Label = $Control/BoxContainer/restart_timer

# HP system variables
var hp: int = 2  # Hard coded HP value
var max_hp: int = 3  # Maximum HP segments
@onready var hp_container: HBoxContainer = $Control/HPContainer
var hp_segments: Array[ColorRect] = []
var hp_shadows: Array[ColorRect] = []  # Shadow/silhouette segments

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
	
	# Create and configure the timer
	timer = Timer.new()
	timer.wait_time = 1.0  # 1 second interval
	timer.timeout.connect(_on_timer_timeout)
	timer.autostart = true
	add_child(timer)
	
	# Display initial time on label
	update_timer_display()

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
	hp = max(0, hp - damage)
	update_hp_display()
	
	if hp <= 0:
		print("Player died!")

func heal(amount: int = 1):
	# Function to handle healing
	hp = min(max_hp, hp + amount)  # Cap at max HP
	update_hp_display()

func add_hp_segment():
	# Add a new HP segment (increase max HP)
	max_hp += 1
	hp = max_hp  # Full heal when adding segment
	
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
	
	update_hp_display()

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
