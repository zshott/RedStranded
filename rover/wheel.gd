extends RayCast3D
class_name Wheel

@export var rover : Rover
@export var wheel_mesh : MeshInstance3D

@export var is_motor : bool = true

@export var spring_strength : float = 100
@export var spring_damping : float = 2
@export var wheel_radius : float = .2
@onready var rest_length : float 
@export var over_extend : float = 0.0 # pulls the car to the floor

func _ready() -> void:
	# length of the raycast
	rest_length = absf((position.y - target_position.y)) / 2