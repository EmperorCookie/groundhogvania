class_name Player

extends CharacterBody2D

# References
@export var horizontal_flipper: Node2D = null
@export var animation_player: AnimationPlayer = null

# Scale
const CHARACTER_HEIGHT_PX: int = 12
const CHARACTER_HEIGHT: float = 0.33
const GRID_PX: int = 16
const METER_PX: float = floor(CHARACTER_HEIGHT_PX / CHARACTER_HEIGHT)
const GRID: float = GRID_PX / METER_PX
const TERMINAL_VELOCITY: float = 10 * GRID

# External values
@onready var default_gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# Capabilities
@export var jump_count: int = 2
@export var double_jump_and_turn: bool = true
@export var can_dash: bool = true

# Stats
@export var weight: float = 1.5
@export var jump_height: float = 3.2 * GRID
@export var jump_height_double: float = 2.2 * GRID
@export var jump_height_abort: float = 0.5 * GRID
@export var koyote_time: float = 0.1
@export var speed: float = 6 * GRID
@export var acceleration: float = 4
@export var acceleration_air: float = 2
@export var dash_speed: float = 14 * GRID
@export var dash_duration: float = 0.3

# State
var facing: float = 1
var dashing: float = 0
var last_animation: String = "idle"
var jumps_done: int = 1
var koyote_timer: float = 0

# Animations
var sprite: String = "cat"
var animations: Dictionary[String, String] = {
	reset = "RESET",
	idle = "idle",
	walk = "walk",
	turn = "turn",
	jump_start = "jump_start",
	jump_end = "jump_end",
	dash_start = "dash_start",
	dash_end = "dash_end",
	double_jump = "double_jump",
}

func get_animation(sprite_name: String, animation: String):
	return sprite_name + "/" + animation

func jump_velocity(gravity: float, height: float) -> float:
	return sqrt(2) * sqrt(gravity) * sqrt(height)

func velocity_meter() -> Vector2:
	return (velocity if is_on_floor() else get_real_velocity()) / METER_PX

func input_state(action: String) -> int:
	return (
		2 if Input.is_action_just_pressed(action)
		else 1 if Input.is_action_pressed(action)
		else -1 if Input.is_action_just_released(action)
		else 0
	)

func _physics_process(delta: float):
	dashing -= delta
	var turning = handle_player_input(delta)
	move_and_slide()
	update_animation(turning, delta)

func handle_player_input(delta: float) -> bool:
	var up_action = "player_up"
	var down_action = "player_down"
	var left_action = "player_left"
	var right_action = "player_right"
	var jump_action = "player_jump"
	var dash_action = "player_dash"
	return handle_input(
		Input.get_vector(left_action, right_action, down_action, up_action),
		input_state(jump_action),
		input_state(dash_action),
		delta,
	)

func handle_input(
	direction: Vector2,
	jump_action: int,
	dash_action: int,
	delta: float,
) -> bool:
	var _velocity: Vector2 = velocity_meter()
	var turning: bool = false
	# Ground controls
	if is_on_floor():
		var _acceleration: float = speed * acceleration * delta
		# Decelerate
		if direction.x == 0:
			if abs(_velocity.x) > _acceleration:
				_velocity.x -= sign(_velocity.x) * _acceleration
			else:
				_velocity.x = 0
		# Accelerate
		else:
			_velocity.x += direction.x * _acceleration
			if sign(_velocity.x) == sign(direction.x):
				facing = 1 if direction.x > 0 else -1
			else:
				dashing = 0
			turning = true if sign(direction.x) != sign(_velocity.x) else false
			# Speed limit
			if abs(_velocity.x) > speed:
				_velocity.x -= sign(velocity.x) * _acceleration * (1 if dashing > 0 else 2)
				if abs(_velocity.x) < speed:
					_velocity.x = sign(_velocity.x) * speed
		# Dash before jump so it works even if pressed on the same frame
		if dash_action == 2 and can_dash and dashing <= 0:
			_velocity.x = sign(facing if direction.x == 0 else direction.x) * dash_speed
			dashing = dash_duration
		# Jump
		if jump_action == 2:
			_velocity.y = -jump_velocity(default_gravity * weight, jump_height)
			jumps_done = 1
		else:
			jumps_done = 0
		koyote_timer = 0
	# Air controls
	else:
		koyote_timer += delta
		if koyote_timer >= koyote_time:
			jumps_done = max(jumps_done, 1)
		# Gravity
		var g = default_gravity * weight * delta
		_velocity.y += g
		# Terminal velocity
		if _velocity.y > TERMINAL_VELOCITY:
			velocity.y = max(velocity.y - g * 2, TERMINAL_VELOCITY)
		# Double jump
		if jump_action == 2 and jumps_done < jump_count:
			_velocity.y = -jump_velocity(default_gravity * weight, jump_height_double)
			jumps_done += 1
			if double_jump_and_turn and sign(_velocity.x) != sign(direction.x):
				_velocity.x = sign(direction.x) * speed
		# Abort jump
		if jump_action == -1:
			var jump_velocity_abort = jump_velocity(default_gravity * weight, jump_height_abort)
			if _velocity.y < -jump_velocity_abort:
				_velocity.y = -jump_velocity_abort
		# Air control
		var _acceleration_air = speed * acceleration_air * delta
		if direction.x == 0:
			if abs(_velocity.x) > _acceleration_air:
				_velocity.x -= sign(_velocity.x) * _acceleration_air
			else:
				_velocity.x = 0
		else:
			var same_direction: bool = (sign(_velocity.x) == sign(direction.x))
			if abs(_velocity.x) < speed or not same_direction:
				_velocity.x += direction.x * _acceleration_air
				if same_direction and abs(_velocity.x) > speed:
					_velocity.x = sign(_velocity.x) * speed
			if same_direction:
				facing = 1 if direction.x > 0 else -1
	velocity = _velocity * METER_PX
	return turning

func play_animation(animation_name: String, loop: bool = true, restart: bool = false):
	var animation: String = get_animation(sprite, animations[animation_name])
	if last_animation != animation or restart:
		animation_player.get_animation(animation).loop_mode = (
			Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
		)
		animation_player.play(animation)
		last_animation = animation

func update_animation(turning: bool, delta: float):
	var _velocity: Vector2 = velocity_meter()
	horizontal_flipper.scale.x = facing
	if is_on_floor():
		if velocity.x == 0:
			play_animation("idle")
		else:
			if dashing > 0:
				play_animation("dash_start", false)
			elif last_animation == "dash_start":
				play_animation("dash_end", false)
			elif animation_player.current_animation != "dash_end":
				if turning:
					play_animation("turn")
				else:
					play_animation("walk")
	else:
		if _velocity.y < 0:
			if jumps_done > 1:
				play_animation("double_jump")
			else:
				play_animation("jump_start", false)
		if _velocity.y >= 0:
			play_animation("jump_end", false)
