class_name Player

extends CharacterBody2D

# Scale
const TERMINAL_VELOCITY: float = 55
const CHARACTER_HEIGHT_PX: int = 12
const CHARACTER_HEIGHT: float = 0.33
const GRID_PX: int = 16
const METER_PX: float = floor(CHARACTER_HEIGHT_PX / CHARACTER_HEIGHT)
const GRID: float = GRID_PX / METER_PX

# Capabilities
@export var jump_count: int = 1
@export var can_dash: bool = false

# Stats
@export var jump_height: float = 3.2 * GRID
@export var jump_height_double: float = 3.2 * GRID
@export var jump_height_abort: float = 0.5 * GRID
@export var speed: float = 6 * GRID
@export var acceleration: float = 10
@export var acceleration_air: float = 4
@export var dash_speed: float = 10 * GRID
@export var dash_duration: float = 0.8

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

func get_animation(sprite: String, animation: String):
	return sprite + "/" + animation

func jump_velocity(gravity: float, height: float) -> float:
	return sqrt(2) * sqrt(gravity) * sqrt(height)
