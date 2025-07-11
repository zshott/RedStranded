extends RigidBody3D
class_name RockCrawler

@export_group("Components")
@export var SETTINGS : SettingsResource 
@export var wheels: Array[WheelJoint]
@export var steer_wheels: Array[WheelJoint]
@export var axles: Array[JoltGeneric6DOFJoint3D]
@export var wheel_body : Array[RigidBody3D]
@export var test : RigidBody3D
@export var debug : Control

@export_group("Drivetrain")
## max speed of wheel
@export var max_speed : float = 12.0
## how fast wheels accelerate
@export var accel : float = 2.0
@export var decel : float = .3
## accelration curve of car
@export var accel_curve : Curve
@export var brake_curve : Curve
@export var max_drive_torque : float = 800
@export var max_brake_torque : float = 300
@export var rolling_resist_coeff : float = 0.015   # ~1.5% of weight force
@export var drag_coeff : float =  0.35              # Higher for boxy cars, lower for sports cars
@export var engine_brake_coeff : float = 5.0       # Tweak this to increase/decrease engine braking effect
## how much torque to apply when throttle = 0, and car is rolling forward
@export var foward_roll_torque : float = 30.0
## how much torque to apply when throttle = 0, and car is rolling backward
@export var back_roll_torque : float = 10.0

@export_group("Steering")
@export_range(0.0, 90.0, 0.1) var MAX_STEER_ANGLE : float = 180
@export var inner_wheel_steering_angle_factor : float = 1.33


## player throttle input
var throttle : float = 0
var brake_input : float = 0
var steer_input : float = 0

var _vel : float = 0.0 # working var for wheel angular velocity, based off throttle

## Gears
enum GEARS {REVERSE, FIRST, SECOND}
var cur_gear : int = GEARS.FIRST

enum INPUT_SCHEMES {KBM, GAMEPAD}
static var INPUT_SCHEME := INPUT_SCHEMES.KBM


func _physics_process(delta: float) -> void:
	
	_gather_input()
	

	var base_steer_angle : float = deg_to_rad(steer_input * MAX_STEER_ANGLE)
	for i in range(steer_wheels.size()):
		var w : JoltGeneric6DOFJoint3D = steer_wheels[i]
		var turn_factor : float = 1.0
		if i == 0 and base_steer_angle > 0.0: # makes inside wheel turn more (poor man's ackerman priniciple)
			turn_factor = inner_wheel_steering_angle_factor
			DebugDraw3D.draw_sphere(w.global_position, .4, Color.RED)
		elif i == 1 and base_steer_angle < 0.0:
			turn_factor = inner_wheel_steering_angle_factor
			DebugDraw3D.draw_sphere(w.global_position, .4, Color.RED)

		w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_LOWER, base_steer_angle * turn_factor)
		w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_UPPER, base_steer_angle * turn_factor)


	var factor : float = _vel / max_speed # variable to used when sampling accelration curve
	factor = clampf(factor, 0.0, 1.0)	# if factor is not clamped, you could get errors when sampling the curve bc it goes from 0-1
	_vel +=  accel_curve.sample_baked(factor) * accel * delta * throttle # we sample a curve for accleration so the car does not accelerate linearly
	
	# these allow for more realistic deceleration
	var rolling_resist : float = rolling_resist_coeff * _vel 
	var air_drag : float = drag_coeff * _vel * _vel
	var engine_brake: float  = (1.0 - throttle) * engine_brake_coeff

	var total_decel : float = rolling_resist + air_drag + engine_brake
	debug.total_decel = total_decel # update value in debug ui

	_vel -= total_decel * delta	
	_vel = clampf(_vel, 0, max_speed) # don't let velocity go below 0, or we will begin to move backwards when not accelerating

	var drive_torque : float = throttle * max_drive_torque
	var brake_factor : float = brake_curve.sample_baked(brake_input)
	var brake_torque : float = brake_factor * max_brake_torque

	var target_vel : float = -_vel
	if brake_input > 0.0:
		target_vel = 0.0

	for w in wheels:
		if throttle > 0.0:
			# apply forces as normal
			w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_MAX_TORQUE, drive_torque + brake_torque)
			w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, target_vel)
		else:
			# no throttle, so let wheels carry momentum and roll freely
			w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, 0.0)

			var angular_vel : float = w.rb.angular_velocity.dot(w.rb.global_basis.x)

			# torque values need to be swapped when in reverse 
			if angular_vel < 0.0:
				w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_MAX_TORQUE, back_roll_torque) # rolling bacwards, so increase rolling resistance b/c we have to turn the whole drivetrain/wheels
			else:
				w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_MAX_TORQUE, foward_roll_torque) # rolling fowards



func _gather_input()->void:
	throttle = Input.get_action_strength("throttle")
	brake_input = Input.get_action_strength("brake")
	steer_input = Input.get_axis("steer_left", "steer_right")

	
func _input(event: InputEvent) -> void:
	#keyboard
	if event is InputEventKey or event is InputEventMouse:
		if INPUT_SCHEME != INPUT_SCHEMES.KBM:
			_set_input_scheme(INPUT_SCHEMES.KBM)
	#gamepad
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if INPUT_SCHEME != INPUT_SCHEMES.GAMEPAD:
			_set_input_scheme(INPUT_SCHEMES.GAMEPAD)

func _set_input_scheme(scheme: INPUT_SCHEMES)->void:
	INPUT_SCHEME = scheme 

	if INPUT_SCHEME == INPUT_SCHEMES.KBM:
		print("kbm")
	elif INPUT_SCHEME == INPUT_SCHEMES.GAMEPAD:
		print("gaempad")
