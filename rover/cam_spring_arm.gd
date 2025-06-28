extends Node3D
class_name SpringArmPivot

@export var mouse_sensitivity : float = .01
@export_range(-90.0, 0.0, 0.1, "radians_as_degrees") var min_vertical_angle : float = -PI/2
@export_range(0.0, 90.0, 0.1, "radians_as_degrees") var max_vertical_angle : float = PI/4
@export var zoom_dist : float = 0.5

@export var spring_arm : SpringArm3D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	#zooming
	if event.is_action_pressed("mouse_wheel_up"): spring_arm.spring_length -= zoom_dist
	if event.is_action_pressed("mouse_wheel_down"): spring_arm.spring_length += zoom_dist

	#moving cam
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensitivity
		rotation.y = wrapf(rotation.y, 0.0, TAU)

		rotation.x -= event.relative.y * mouse_sensitivity
		rotation.x = clampf(rotation.x, min_vertical_angle, max_vertical_angle)
