extends Node2D

# Timer variables
var seconds: int = 360  # 6 minutes in seconds
var timer: Timer
@onready var restart_timer_label: Label = $Control/BoxContainer/restart_timer

func _ready():
	# Create and configure the timer
	timer = Timer.new()
	timer.wait_time = 1.0  # 1 second interval
	timer.timeout.connect(_on_timer_timeout)
	timer.autostart = true
	add_child(timer)
	
	# Display initial time on label
	update_timer_display()

func _on_timer_timeout():
	# Decrease seconds and update display
	if seconds > 0:
		seconds -= 1
	update_timer_display()

func update_timer_display():
	# Convert seconds to minutes:seconds format and update label
	var minutes: int = seconds / 60
	var remaining_seconds: int = seconds % 60
	var time_string = "%d:%02d" % [minutes, remaining_seconds]
	
	# Check if the label exists before trying to update it
	if restart_timer_label:
		restart_timer_label.text = time_string
	else:
		print("Warning: restart_timer label not found!")
	
	print("Current time: " + time_string)  # Keep debug print for now
