class_name Bee

extends CharacterBody2D

# References
@export var player: Player = null
@export var animation_player: AnimationPlayer = null
@export var horizontal_flipper: Node2D = null

# Stats
@export var aggro_distance = 16 * Player.GRID
@export var deaggro_distance = 24 * Player.GRID
@export var speed = 8 * Player.GRID
@export var acceleration = 4
@export var bounce_speed = 12 * Player.GRID

# Sounds
@onready var death_sound: AudioStreamPlayer = $DeathSound

# Animations
var animations: Dictionary[String, String] = {
	fly = "bee/fly",
	death = "bee/death",
}

# State
var target: Player = null
var bounce: Vector2 = Vector2.ZERO
var neutralized: bool = false

func _ready():
	animation_player.play(animations["fly"])

func _physics_process(delta: float):
	var _player_distance: float = (position - player.position).length() / Player.METER_PX
	if _player_distance <= aggro_distance and target == null:
		target = player
	if _player_distance > deaggro_distance:
		target = null
	var _direction: Vector2 = Vector2.ZERO
	if target != null and not neutralized:
		_direction = (player.position - position).normalized()
	var _velocity: Vector2 = Player.velocity_meter(self)
	var _acceleration: float = speed * acceleration * delta
	if bounce != Vector2.ZERO:
		_velocity = bounce
		bounce = Vector2.ZERO
	if _direction != Vector2.ZERO:
		_velocity += _direction * _acceleration
	else:
		_velocity = _velocity.normalized() * max(_velocity.length() - _acceleration, 0)
	if _velocity.length() > speed:
		_velocity = _velocity.normalized() * speed
	velocity = _velocity * Player.METER_PX
	horizontal_flipper.scale.x = 1 if velocity.x >= 0 else -1
	move_and_slide()
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if bounce == Vector2.ZERO:
			bounce = collision.get_normal() * bounce_speed
		if collider is Player:
			var _player_velocity: Vector2 = Player.velocity_meter(collider)
			print_debug(collider.position, ", ", position, ", ", _player_velocity)
			if collider.position.y < position.y and _player_velocity.y >= 0:
				collider.impulse.y = -bounce_speed
				collider.impulse.x = _player_velocity.x
				neutralized = true
				death_sound.play()
				animation_player.play(animations["death"])
			elif not neutralized:
				collider.facing = 1 if position.x - collider.position.x >= 0 else -1
				collider.player_take_damage()
	if neutralized and animation_player.current_animation != animations["death"]:
		queue_free()
