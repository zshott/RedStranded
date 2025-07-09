extends RigidBody3D
class_name RockCrawler

@export var wheels: Array[JoltGeneric6DOFJoint3D]
@export var steer_wheels: Array[JoltGeneric6DOFJoint3D]
@export var axles: Array[JoltGeneric6DOFJoint3D]
@export var wheel_body : Array[RigidBody3D]
@export var test : RigidBody3D
@export var debug : Label

@export_range(0.0, 90.0, 0.1) var MAX_STEER_ANGLE : float = 180
## max speed of wheel
@export var max_speed : float = 12.0
## how fast wheels accelerate
@export var accel : float = 2.0
@export var decel : float = .3
## accelration curve of cas
@export var a_curve : Curve
@export var max_torque : float = 800
@export var brake_torque : float = 300
@export var rolling_resist_coeff : float = 0.015   # ~1.5% of weight force
@export var drag_coeff : float =  0.35              # Higher for boxy cars, lower for sports cars
@export var engine_brake_coeff : float = 5.0       # Tweak this to increase/decrease engine braking effect

## player throttle input
var throttle : float = 0
var brake : float = 0
var steer_input : float = 0

var _vel : float = 0.0

## Gears
enum GEARS {REVERSE, FIRST, SECOND}
var cur_gear : int = GEARS.FIRST

enum INPUT_SCEMES {KBM, GAMEPAD}
static var INPUT_SCHEME := INPUT_SCEMES.KBM


func _physics_process(delta: float) -> void:
	throttle = Input.get_action_strength("accelerate")
	brake = Input.get_action_strength("brake")

	steer_input = Input.get_axis("steer_left", "steer_right")
	
	var inner_wheel_steering_angle_factor : float = 1.33

	var base_steer_angle : float = deg_to_rad(steer_input * MAX_STEER_ANGLE)
	for i in range(steer_wheels.size()):
		var w : JoltGeneric6DOFJoint3D = steer_wheels[i]
		var this_factor : float = 1.0
		if i == 0 and base_steer_angle < 0.0:
			this_factor = inner_wheel_steering_angle_factor
		elif i == 1 and base_steer_angle > 0.0:
			this_factor = inner_wheel_steering_angle_factor

		w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_LOWER, base_steer_angle * this_factor)
		w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_UPPER, base_steer_angle * this_factor)


	var factor : float = _vel / max_speed
	factor = clampf(factor, 0.0, 1.0)			# if factor is not clamped, you could get errors when sampling the curve bc it goes from 0-1
	_vel +=  a_curve.sample_baked(factor) * accel * delta * throttle # we sample a curve for accleration so the car does not accelerate linearly
	

	var rolling_resist : float = rolling_resist_coeff * _vel
	var air_drag : float = drag_coeff * _vel * _vel
	var engine_brake: float  = (1.0 - throttle) * engine_brake_coeff

	var total_decel : float = rolling_resist + air_drag + engine_brake
	_vel -= total_decel * delta		# add a flat deceleration to velocity so the car does not keep going forever

	var cur_torque := max_torque

	_vel = clampf(_vel, 0, max_speed)		# don't let velocity go below 0, or we will begin to move backwards when not accelearting

	for w in wheels:
		w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_MAX_TORQUE, cur_torque)
		w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, -_vel)



	

	

