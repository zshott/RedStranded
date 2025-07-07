extends RigidBody3D
class_name RockCrawler

@export var wheels: Array[JoltGeneric6DOFJoint3D]
@export var steer_wheels: Array[JoltGeneric6DOFJoint3D]
@export var axles: Array[JoltGeneric6DOFJoint3D]
@export var wheel_body : Array[RigidBody3D]
@export var test : RigidBody3D
@export var debug : Label

## Engine RPM to torque
@export var TORQUE_CURVE : Curve
## Max Engine RPM
@export var MAX_RPM : float = 6800
## Engine RPM at idle
@export var IDLE_RPM : float = 1000
## Max torque in newton-meters
@export var MAX_TORQUE : float = 300
## Torque applied by the brakes, it is a contstant torque
@export var BRAKE_TORQUE : float = 30
## Gear ratios, from Reverse->First->Second, etc.
@export var GEAR_RATIOS : Array[float] = [2.0, 2.66, 2.1]
## Differential ratio
@export var DIFF_RATIO : float = 3.4 
## Transmission efficiency, must be between 0.0 and 1.0
@export var TRANS_EFF : float = 0.7
## Radius of wheel
@export var WHEEL_RADIUS : float = .45
## Mass of wheel
@export var WHEEL_MASS : float = 12

@export var MAX_SPEED : float = 40
@export_range(0.0, 90.0, 0.1) var MAX_STEER_ANGLE : float = 180
@export var WHEEL_FORCE_LIMIT : float = 5000

@export var ACCEL_CURVE : Curve 

## player throttle input
var throttle : float = 0
var brake : float = 0
var steer_input : float = 0
var _rpm : float = 0.0
var last_rotation : float = 0
var _wish_wheel_torque : float
var _wheel_angular_vel : float

## Gears
enum GEARS {REVERSE, FIRST, SECOND}
var cur_gear : int = GEARS.FIRST

enum INPUT_SCEMES {KBM, GAMEPAD}
static var INPUT_SCHEME := INPUT_SCEMES.KBM

#func _ready() -> void:

# func _unhandled_input(event: InputEvent) -> void:
# 	if event.is_action_pressed("accelerate"):
# 		throttle = 1
# 		print("blah")
# 	elif event.is_action_released("accelerate"):
# 		throttle = 0

# 	if event.is_action_pressed("brake"):
# 		throttle = -1
# 	elif event.is_action_released("brake"):
# 		throttle = 0

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


	

	debug.text = str(-test.angular_velocity.dot(test.global_basis.x), '\n', test.rotation_degrees.y)

func _do_wheel_accel(w: JoltGeneric6DOFJoint3D, delta: float)->void:
	w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, -throttle * ACCEL)
	#w.rb.apply_torque(Vector3.LEFT.cross(w.rb.global_basis.x) * motor_input * ACCEL * 5)
	#DebugDraw3D.draw_arrow(w.rb.global_position, w.rb.global_position + (w.rb.global_basis) * Vector3.LEFT * motor_input * ACCEL, Color.BLUE, .01)
	#DebugDraw3D.draw_arrow(w.rb.global_position, w.rb.global_position + (-Vector3.UP.cross(w.rb.global_basis.y)) * motor_input *ACCEL/ 4, Color.RED, .01)

func _get_torque_at_rpm(cur_rpm : float)->float:
	var rpm_factor : float = clamp(cur_rpm / MAX_RPM, 0.0, 1.0)
	var torque_factor := TORQUE_CURVE.sample_baked(rpm_factor)
	return torque_factor * MAX_TORQUE

func _calc_vel(delta:float)->void:
	# don't let rpm fall below idle or go above max rpm
	_rpm = clampf(_rpm, IDLE_RPM, MAX_RPM)

	var _cur_torque : float = _get_torque_at_rpm(_rpm) 
	var _engine_torque : float = throttle * _cur_torque
	var _gear_factor : float = GEAR_RATIOS[cur_gear] * DIFF_RATIO
	var _wheel_rpm : float = _rpm / _gear_factor

	_wheel_angular_vel = _wheel_rpm * 6 # multiply by 6 to convert to degrees/second
	var _wheel_torque : float = _engine_torque * _gear_factor * TRANS_EFF

	var _longitudinal_vel : float = -global_basis.z.dot(linear_velocity)

	if is_zero_approx(absf(_longitudinal_vel)):
		_longitudinal_vel = .01

	var _slip : float = _wheel_angular_vel * WHEEL_RADIUS * _longitudinal_vel / absf(_longitudinal_vel)#(-wheels[0].rb.angular_velocity.dot(wheels[0].rb.global_basis.x)) * WHEEL_RADIUS * _longitudinal_vel / absf(_longitudinal_vel)
	print(_slip)

	var _torque_sign : float = signf(_wheel_torque)
	_wish_wheel_torque  = _wheel_torque + -_torque_sign * 50 # (-_torque_sign * (_slip + brake * BRAKE_TORQUE))#+ traction_torque + brake_torque
	var _inertia : float = WHEEL_MASS * (WHEEL_RADIUS * WHEEL_RADIUS) / 2 # inertia of a cylinder formula 

	var _angular_accel : float = _wish_wheel_torque / _inertia
	if signf(_angular_accel) == -1.0 :
		breakpoint
	_wheel_angular_vel += _angular_accel * delta 
	_rpm = _wheel_angular_vel / 6 * _gear_factor  # convert deg/s back to rpm

	for w in wheels:
		w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, deg_to_rad(-_wheel_angular_vel))
		w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_MAX_TORQUE, _wish_wheel_torque)