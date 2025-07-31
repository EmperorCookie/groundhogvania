extends Node2D

# References
@export var target: Node2D = null

# Params
@export var spring: float = 10
@export var lead: float = 2
@export var maximum_distance: float = 116
@export var offset: Vector2 = Vector2.ZERO

# State
var target_position: Vector2 = Vector2.ZERO
var target_position_last: Vector2 = Vector2.ZERO
var target_velocity: Vector2 = Vector2.ZERO
var current_lead: Vector2 = Vector2.ZERO
var target_reached: bool = false

func _ready():
	if target != null:
		global_position = target.global_position
		set_target(target)

func clear_target():
	target = null

func set_target(_target: Node2D):
	target = _target
	target_reached = false
	target_position = target.global_position
	target_position_last = target_position
	target_velocity = Vector2.ZERO

func apply_spring(value: float, delta: float) -> float:
	return clamp(1 - pow(0.5, delta * value), 0, 1)

func _physics_process(delta: float):
	if target != null:
		target_position_last = target_position
		target_position = target.global_position
		target_velocity = (target_position - target_position_last) / delta
		current_lead = lerp(
			current_lead, target_velocity * lead * delta * 10, apply_spring(spring, delta)
		)

func _process(delta: float):
	if target != null:
		var final_position = lerp(
			global_position, target_position + current_lead, apply_spring(spring, delta)
		)
		var position_delta: Vector2 = final_position - target_position
		if position_delta.length_squared() > maximum_distance * maximum_distance:
			if target_reached:
				final_position = target_position + position_delta.normalized() * maximum_distance
		else:
			target_reached = true
		global_position = final_position
