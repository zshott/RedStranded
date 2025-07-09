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
## Braking torque from engine when throttle = 0
@export var ENGINE_BRAKE_COEFF : float = 15.0
## Resistance from rolling
@export var ROLLING_RESIST_COEFF : float = 0.3

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

var _vel : float = 0.0
@export var max_speed : float = 12.0
@export var accel : float = 2.0
@export var decel : float = .3
@export var a_curve : Curve
@export var max_torque : float = 800
@export var brake_torque : float = 300
@export var rolling_resist_coeff : float = 0.015   # ~1.5% of weight force
@export var drag_coeff : float =  0.35              # Higher for boxy cars, lower for sports cars
@export var engine_brake_coeff : float = 5.0       # Tweak this to increase/decrease engine braking effect



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



	

	

func _do_wheel_accel(w: JoltGeneric6DOFJoint3D, delta: float)->void:
	pass
	#w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, -throttle * ACCEL)
	#w.rb.apply_torque(Vector3.LEFT.cross(w.rb.global_basis.x) * motor_input * ACCEL * 5)
	#DebugDraw3D.draw_arrow(w.rb.global_position, w.rb.global_position + (w.rb.global_basis) * Vector3.LEFT * motor_input * ACCEL, Color.BLUE, .01)
	#DebugDraw3D.draw_arrow(w.rb.global_position, w.rb.global_position + (-Vector3.UP.cross(w.rb.global_basis.y)) * motor_input *ACCEL/ 4, Color.RED, .01)

func _get_torque_at_rpm(cur_rpm : float)->float:
	var rpm_factor : float = clamp(cur_rpm / MAX_RPM, 0.0, 1.0)
	var torque_factor := TORQUE_CURVE.sample_baked(rpm_factor)
	return torque_factor * MAX_TORQUE

func _calc_vel(delta:float)->void:

	

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

	var _slip : float = _wheel_angular_vel * WHEEL_RADIUS - _longitudinal_vel / absf(_longitudinal_vel)#(-wheels[0].rb.angular_velocity.dot(wheels[0].rb.global_basis.x)) * WHEEL_RADIUS * _longitudinal_vel / absf(_longitudinal_vel)
	print(_slip)

	var _torque_sign : float = signf(_wheel_torque)
	_wish_wheel_torque  = _wheel_torque #+ -_torque_sign * 50 # (-_torque_sign * (_slip + brake * BRAKE_TORQUE))#+ traction_torque + brake_torque
	var _inertia : float = WHEEL_MASS * (WHEEL_RADIUS * WHEEL_RADIUS) / 2 # inertia of a cylinder formula 

	var _angular_accel : float = _wish_wheel_torque / _inertia

	_wheel_angular_vel += _angular_accel * delta 
	_rpm = _wheel_angular_vel / 6 * _gear_factor  # convert deg/s back to rpm
	# don't let rpm fall below idle or go above max rpm
	
func calcvel2(delta:float)->void:
	var gear_factor : float = GEAR_RATIOS[cur_gear] * DIFF_RATIO

	# Get engine torque at current RPM
	var cur_torque: float = _get_torque_at_rpm(_rpm)
	var engine_torque: float = throttle * cur_torque


	# Convert RPM to wheel angular velocity in radians/sec
	var wheel_rpm: float = _rpm / gear_factor
	_wheel_angular_vel = wheel_rpm * TAU / 60.0  # TAU = 2*PI

	# Effective torque to the wheel
	var wheel_torque: float = engine_torque * gear_factor * TRANS_EFF
	print(wheel_torque)

	# Vehicle longitudinal velocity
	var longitudinal_vel : float = -global_basis.z.dot(linear_velocity)
	if is_zero_approx(absf(longitudinal_vel)):
		longitudinal_vel = 0.01

	# Calculate wheel surface speed
	var wheel_surface_speed : float = _wheel_angular_vel * WHEEL_RADIUS

	# Calculate slip (wheel speed - vehicle speed)
	var slip : float = wheel_surface_speed - longitudinal_vel
	#print("Slip:", slip)

	# Resistance (engine brake + rolling resistance)
	var engine_brake : float = (1.0 - throttle) * ENGINE_BRAKE_COEFF
	var rolling_resistance : float = _wheel_angular_vel * ROLLING_RESIST_COEFF
	var total_resistance : float = engine_brake + rolling_resistance

	var torque_sign : float = signf(wheel_torque)
	var wish_wheel_torque : float = wheel_torque - torque_sign * total_resistance

	# Moment of inertia for a solid cylinder
	var _inertia : float = 0.5 * WHEEL_MASS * WHEEL_RADIUS * WHEEL_RADIUS

	# Apply angular acceleration
	var angular_accel : float = wish_wheel_torque / _inertia
	_wheel_angular_vel += angular_accel * delta

	# Convert back to engine RPM
	_rpm = _wheel_angular_vel * 60.0 / TAU * gear_factor

	# Clamp RPM to realistic bounds at the END
	_rpm = clampf(_rpm, IDLE_RPM, MAX_RPM)
	

	for w in wheels:
		w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, -_wheel_angular_vel)
		w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_MAX_TORQUE, wish_wheel_torque)
