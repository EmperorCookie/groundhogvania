extends Node2D

# Node control
@export var enable_nodes: Array[Node]
@export var disable_nodes: Array[Node]

# Stats
@export var speed: float = 1000

func _ready():
	for node in enable_nodes:
		node.process_mode = Node.PROCESS_MODE_DISABLED
		if node is CanvasItem or node is CanvasLayer:
			node.visible = false

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

func start_level():
	for node in disable_nodes:
		for child in node.get_children():
			child.queue_free()
		node.queue_free()
	for node in enable_nodes:
		node.process_mode = Node.PROCESS_MODE_INHERIT
		if node is CanvasItem or node is CanvasLayer:
			node.visible = true
	queue_free()
