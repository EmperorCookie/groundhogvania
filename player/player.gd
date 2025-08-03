class_name Player

extends CharacterBody2D

# References
@export var horizontal_flipper: Node2D = null
@export var animation_player: AnimationPlayer = null
@export var camera: TargetCamera = null
@export var color_rect: ColorRect = null
@onready var player_hud = get_node("../PlayerHud")
@onready var enemy_manager = get_node("../EnemyManager")

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
var days: int = 1
@export var max_hp: int = 2
@export var current_hp: int = 1
@export var current_time: int = 45 # In seconds
@export var starting_time: int = 45 # In seconds
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
@export var hurt_time: float = 0.2
@export var hurt_speed: Vector2 = Vector2(-6 * GRID, -6 * GRID)

# State
var facing: float = 1
var dashing: float = 0
var last_animation: String = "idle"
var jumps_done: int = 1
var koyote_timer: float = 0
var hurt_timer: float = 0
var impulse: Vector2 = Vector2.ZERO
var impulse_reset: bool = false
var was_on_floor: bool = false
var spawn_position: Vector2

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
	hurt = "hurt",
	death = "death",
}

# Sounds
@onready var damage_sound: AudioStreamPlayer = $DamageSound 
@onready var jump_sound: AudioStreamPlayer = $JumpSound
@onready var dash_sound: AudioStreamPlayer = $DashSound
@onready var death_sound: AudioStreamPlayer = $DeathSound
@onready var landing_sound: AudioStreamPlayer = $LandingSound
@onready var double_jump_sound: AudioStreamPlayer = $DoubleJumpSound
@onready var step_sound: AudioStreamPlayer = $StepSound
@onready var slide_sound: AudioStreamPlayer = $SlideSound
@onready var heal_sound: AudioStreamPlayer = $HealSound

func _ready():
	# Store the initial spawn position
	spawn_position = global_position

func get_animation(sprite_name: String, animation: String):
	return sprite_name + "/" + animation

static func jump_velocity(gravity: float, height: float) -> float:
	return sqrt(2) * sqrt(gravity) * sqrt(height)

static func velocity_meter(character: CharacterBody2D) -> Vector2:
	return (character.velocity if character.is_on_floor() else character.get_real_velocity()) / METER_PX

static func input_state(action: String) -> int:
	return (
		2 if Input.is_action_just_pressed(action)
		else 1 if Input.is_action_pressed(action)
		else -1 if Input.is_action_just_released(action)
		else 0
	)

func _physics_process(delta: float):
	dashing -= delta
	hurt_timer -= delta
	var turning: bool = false
	if hurt_timer > 0 or current_hp <= 0:
		turning = handle_input(Vector2.ZERO, 0, 0, delta)
	else:
		turning = handle_player_input(delta)
	was_on_floor = is_on_floor()
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
	var _velocity: Vector2 = velocity_meter(self)
	var turning: bool = false
	# Impulse
	if impulse_reset:
		_velocity = impulse
	else:
		_velocity += impulse
	impulse = Vector2.ZERO
	impulse_reset = false
	# Ground controls
	if is_on_floor():
		if not was_on_floor:
			landing_sound.play()
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
			dash_sound.play()
			_velocity.x = sign(facing if direction.x == 0 else direction.x) * dash_speed
			dashing = dash_duration
		# Jump
		if jump_action == 2:
			jump_sound.play()
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
			if jumps_done == 0:
				jump_sound.play()
			else:
				double_jump_sound.play()
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

func update_animation(turning: bool, _delta: float):
	var _velocity: Vector2 = velocity_meter(self)
	horizontal_flipper.scale.x = facing
	if hurt_timer > 0:
		play_animation("hurt")
		return
	if current_hp <= 0:
		play_animation("death", false)
		return
	if is_on_floor():
		if velocity.x == 0:
			play_animation("idle")
			# Stop step sound when not moving
			if step_sound.playing:
				step_sound.stop()
		else:
			if dashing > 0:
				play_animation("dash_start", false)
				# Stop step sound during dash
				if step_sound.playing:
					step_sound.stop()
			elif last_animation == "dash_start":
				play_animation("dash_end", false)
				# Stop step sound during dash end
				if step_sound.playing:
					step_sound.stop()
			elif animation_player.current_animation != "dash_end":
				if turning:
					play_animation("turn")
					# Stop step sound during turn and play slide sound
					if step_sound.playing:
						step_sound.stop()
					# Play slide sound when turning
					if not slide_sound.playing:
						slide_sound.play()
				else:
					play_animation("walk")
					# Start looping step sound when walking
					if not step_sound.playing:
						step_sound.play()
	else:
		# Stop step sound when in air
		if step_sound.playing:
			step_sound.stop()
		if _velocity.y < 0:
			if jumps_done > 1:
				play_animation("double_jump")
			else:
				play_animation("jump_start", false)
		if _velocity.y >= 0:
			play_animation("jump_end", false)

# Removes HP from the player and calls the player_hud.gd to update the display
func player_take_damage():
	if current_hp <= 0 or hurt_timer > 0:
		return
	current_hp = clamp(current_hp - 1, 0, max_hp)
	player_hud.update_segments(current_hp)
	damage_sound.play()
	hurt_timer = hurt_time
	impulse.x = facing * hurt_speed.x
	impulse.y = hurt_speed.y
	impulse_reset = true
	if current_hp == 0:
		player_death()

func player_death():
	# Respawn the player at their starting position
	await get_tree().create_timer(1.5).timeout  # Wait 1.5 seconds before playing death sound
	death_sound.play()
	player_hud._fade_music()
	await get_tree().create_timer(1.5).timeout  # Wait 1.5 seconds before respawning
	player_reset()

func player_reset():
	# Reset player state
	global_position = spawn_position
	velocity = Vector2.ZERO
	current_hp = 1
	hurt_timer = 0
	dashing = 0
	impulse = Vector2.ZERO
	impulse_reset = false
	jumps_done = 0
	days += 1
	player_hud._stop_music()
	
	# Reset death fade effect
	if color_rect:
		color_rect.color.a = 0.0  # Make it fully transparent
	
	# Update HUD to reflect restored health
	player_hud.update_segments(current_hp)
	# Reset timer to starting time
	player_hud.seconds = starting_time
	player_hud.update_timer_display()
	player_hud._play_music()
	enemy_manager.reset_all_enemies()  # Reset all enemies to their original state

# Adds HP to the player and calls the player_hud.gd to update the display
func player_heal():
	current_hp = clamp(current_hp + 1, 0, max_hp)
	heal_sound.play()
	player_hud.update_segments(current_hp)
