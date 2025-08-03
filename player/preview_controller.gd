extends Node2D

# Node control
@export var level_nodes: Array[Node]
@export var preview_nodes: Array[Node]

# Stats
@export var speed: float = 1000

# HUD
@onready var player_hud = get_node("../PlayerHud")

func _ready():
	start_preview()

func _physics_process(delta: float):
	var up_action = "player_up"
	var down_action = "player_down"
	var left_action = "player_left"
	var right_action = "player_right"
	var jump_action = "player_jump"
	handle_input(
		Input.get_vector(left_action, right_action, down_action, up_action),
		input_state(jump_action),
		delta,
	)

func handle_input(direction: Vector2, jump_action: int, delta: float):
	global_position += direction * Vector2(1, -1) * speed * delta
	if jump_action >= 1:
		start_level()

func input_state(action: String) -> int:
	return (
		2 if Input.is_action_just_pressed(action)
		else 1 if Input.is_action_pressed(action)
		else -1 if Input.is_action_just_released(action)
		else 0
	)

func start_preview():
	for node in level_nodes:
		set_node_status(node, Node.PROCESS_MODE_DISABLED, false)
	for node in preview_nodes:
		set_node_status(node, Node.PROCESS_MODE_INHERIT, true)

func start_level():
	for node in preview_nodes:
		set_node_status(node, Node.PROCESS_MODE_DISABLED, false)
	for node in level_nodes:
		set_node_status(node, Node.PROCESS_MODE_INHERIT, true)
	player_hud._play_music()

func set_node_status(node: Node, process_mode: ProcessMode, _visible: bool):
	for child in node.get_children():
		set_node_status(child, process_mode, _visible)
	node.process_mode = process_mode
	
	# Only set visibility for CanvasItem/CanvasLayer nodes, but preserve certain UI elements
	if node is CanvasItem or node is CanvasLayer:
		# Don't override visibility for the LevelCompleteLabel - it should stay invisible
		if node.name == "LevelCompleteLabel":
			# Keep it invisible regardless of the _visible parameter
			node.visible = false
		else:
			node.visible = _visible
			
	if _visible and node is Camera2D:
		node.make_current()
