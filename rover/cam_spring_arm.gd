extends Node3D
class_name SpringArmPivot

@export var settings : SettingsResource
@export var mouse_sensitivity : float = .01
@export_range(-90.0, 0.0, 0.1, "radians_as_degrees") var min_vertical_angle : float = -PI/2
@export_range(0.0, 90.0, 0.1, "radians_as_degrees") var max_vertical_angle : float = PI/4
@export var zoom_dist : float = 0.5

@export var spring_arm : SpringArm3D

# const settings.joystick_deadzone = 0.2
# const settings.joy_axis_rescale = 1.0/(1.0-settings.joystick_deadzone)
# const settings.joy_rotation_multiplier = 200.0 * PI / 180.0

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
		@warning_ignore_start("unsafe_property_access")
		rotation.y -= event.relative.x * mouse_sensitivity
		rotation.y = wrapf(rotation.y, 0.0, TAU)

		rotation.x -= event.relative.y * mouse_sensitivity
		rotation.x = clampf(rotation.x, min_vertical_angle, max_vertical_angle)
		@warning_ignore_restore("unsafe_property_access")


func _process(delta: float) -> void:
	if Input.get_connected_joypads().size() == 0:
		return		
		
	var xAxis := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	if abs(xAxis) > settings.joystick_deadzone:
		if xAxis >0:
			xAxis = (xAxis-settings.joystick_deadzone) * settings.joy_axis_rescale
		else:
			xAxis = (xAxis+settings.joystick_deadzone) * settings.joy_axis_rescale
		rotation.y -= xAxis * delta * settings.joy_rotation_multiplier
		rotation.y = wrapf(rotation.y, 0.0, TAU)
		
	var yAxis := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if abs(yAxis) > settings.joystick_deadzone:
		if yAxis >0:
			yAxis = (yAxis-settings.joystick_deadzone) * settings.joy_axis_rescale
		else:
			yAxis = (yAxis+settings.joystick_deadzone) * settings.joy_axis_rescale
		
		rotation.x -= yAxis * delta * settings.joy_rotation_multiplier/2
		rotation.x = clampf(rotation.x, min_vertical_angle, max_vertical_angle)
