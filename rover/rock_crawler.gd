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
@export var max_speeds : Array[float] = [18.0, 20.0, 45.0]
## how fast wheels accelerate
@export var accelerations : Array[float] = [30, 30, 60]
@export var gear_ratios : Array[float] = [2.0, 3.42, 2.1]
@export var decel : float = .3
## accelration curve of car
@export var accel_curve : Curve
@export var brake_curve : Curve
@export var max_drive_torques : Array[float] = [800, 800, 425]
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
@export var do_wheel_straighten : bool = false
@export var grip_tire_mat : PhysicsMaterial
@export var slip_tire_mat : PhysicsMaterial

## Gears
enum GEAR {REVERSE, FIRST, SECOND, THIRD}
var cur_gear : int = GEAR.FIRST

var max_speed : float = max_speeds[cur_gear]
var max_drive_torque : float = max_drive_torques[cur_gear]
var accel : float = accelerations[cur_gear]
var gear_sign : int = -1
var gear_ratio : float = gear_ratios[cur_gear]
var torque_output : float = 0.0
var grounded : bool = false
var is_redline : bool = false
## player input
var throttle : float = 0
var brake_input : float = 0
var steer_input : float = 0

var _vel : float = 0.0 # working var for wheel angular velocity, based off throttle


enum INPUT_SCHEMES {KBM, GAMEPAD}
static var INPUT_SCHEME := INPUT_SCHEMES.KBM

func _ready() -> void:
	_change_gear(cur_gear)
	
func _physics_process(delta: float) -> void:
	
	_gather_input(delta)
	_check_ground()
	

	var base_steer_angle : float = deg_to_rad(steer_input * MAX_STEER_ANGLE)
	for i in range(steer_wheels.size()):
		var w : JoltGeneric6DOFJoint3D = steer_wheels[i]
		var turn_factor : float = 1.0
		if i == 0 and base_steer_angle > 0.0: # makes inside wheel turn more (poor man's ackerman priniciple)
			turn_factor = inner_wheel_steering_angle_factor
		elif i == 1 and base_steer_angle < 0.0:
			turn_factor = inner_wheel_steering_angle_factor
			

		w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_LOWER, base_steer_angle * turn_factor)
		w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_UPPER, base_steer_angle * turn_factor)

	_simple_accel(delta)
	#dashoe(delta)
	#grrrr(delta)


func _simple_accel(delta: float)->void:
	var factor : float = _vel / max_speed # variable to used when sampling accelration curve
	factor = clampf(factor, 0.0, 1.0)	# if factor is not clamped, you could get errors when sampling the curve bc it goes from 0-1
	_vel +=  accel_curve.sample_baked(factor) * accel * gear_ratio * delta * throttle # we sample a curve for accleration so the car does not accelerate linearly
	
	# these allow for more realistic deceleration
	var rolling_resist : float = rolling_resist_coeff * _vel *_vel
	#var air_drag : float = drag_coeff * _vel * _vel
	var engine_brake: float  = (1.0 - throttle) * engine_brake_coeff

	var total_decel : float = rolling_resist + engine_brake# + air_drag 
	debug.total_decel = total_decel # update value in debug ui

	_vel -= total_decel * delta	
	_vel = clampf(_vel, 0, max_speed) # don't let velocity go below 0, or we will begin to move backwards when not accelerating

	var drive_torque : float = max_drive_torque#throttle * max_drive_torque
	var brake_factor : float = brake_curve.sample_baked(brake_input)
	var brake_torque : float = brake_factor * max_brake_torque

	var target_vel : float = _vel * gear_sign 
	var target_torque : float = drive_torque# if throttle > 0.01 else brake_torque
	if brake_input > 0.0:
			target_vel = 0.0
			target_torque = brake_torque

	debug.torque = target_torque
	for w in wheels:
		if throttle > 0.0:
			# apply forces as normal
			w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_MAX_TORQUE, target_torque)
			w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, target_vel)
		else:
			# no throttle, so let wheels carry momentum and roll freely
			w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, 0.0)

			var angular_vel : float = w.rb.angular_velocity.dot(w.rb.global_basis.x)

			# torque values need to be swapped when in reverse 
			if angular_vel < 0.0:
				w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_MAX_TORQUE, back_roll_torque + brake_torque) # rolling bacwards, so increase rolling resistance b/c we have to turn the whole drivetrain/wheels
			else:
				w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_MAX_TORQUE, foward_roll_torque + brake_torque) # rolling fowards



func _change_gear(new_gear: GEAR)->void:
	cur_gear = new_gear
	max_speed = max_speeds[cur_gear]
	max_drive_torque = max_drive_torques[cur_gear]
	accel = accelerations[cur_gear]
	gear_ratio = gear_ratios[cur_gear]

	if _vel > max_speed:
		_vel = lerpf(_vel, max_speed, .5)

	if new_gear == 0:
		gear_sign = 1
	else:
		gear_sign = -1

	if new_gear <=1:
		for w in wheels:
			w.rb.physics_material_override = grip_tire_mat
	else:
		for w in wheels:
			w.rb.physics_material_override = slip_tire_mat

func _check_ground()->void:
	grounded = false
	var collisions :int = 0
	for w in wheels:
		if w.rb.get_contact_count() > 0:
			for i in w.rb.get_colliding_bodies():
				if i is Terrain3D:
					print(i)

				grounded = true
				break
			if grounded:
				break
					
	if grounded:
		center_of_mass = Vector3.ZERO

	else:
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = Vector3.DOWN * .5



# func _get_torque_at_rpm(cur_rpm : float)->float:
# 	var rpm_factor : float = clampf((cur_rpm - IDLE_RPM) / MAX_RPM, 0.0, 1.0)
# 	var torque_factor := TORQUE_CURVE.sample_baked(rpm_factor)
# 	return torque_factor * MAX_TORQUE

func _gather_input(delta: float)->void:
	
	### GAMEPAD STEERING ###
	if INPUT_SCHEME == INPUT_SCHEMES.GAMEPAD:
		### STEERING ###
		var raw_steer_input : float = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
		if absf(raw_steer_input) > SETTINGS.joystick_deadzone: 
			#we need to differentiate between pos/neg movement or else raw_steer_input will effectively be not be able to be pos/neg
			if raw_steer_input > 0:
				# rescale so joyaxis scale is from 0-1 again
				raw_steer_input = (raw_steer_input - SETTINGS.joystick_deadzone) * SETTINGS.joy_axis_rescale 
			elif raw_steer_input < 0:
				# rescale so joyaxis scale is from 0-1 again
				raw_steer_input = (raw_steer_input + SETTINGS.joystick_deadzone) * SETTINGS.joy_axis_rescale

			steer_input += raw_steer_input * SETTINGS.gamepad_steer_sensitivity
			steer_input = clampf(steer_input, -1.0, 1.0)
		### STEER STRAIGHTEN ###
		if do_wheel_straighten:
			#TODO steering make break if straigten speed is > steer sensitivity
			if absf(raw_steer_input) - SETTINGS.joystick_deadzone < 0.01:
				if steer_input > 0.0:
					steer_input -= SETTINGS.gamepad_steer_straighten_speed * delta
					steer_input = clampf(steer_input, 0, 1.0)
				elif steer_input < 0.0:
					steer_input += SETTINGS.gamepad_steer_straighten_speed * delta
					steer_input = clampf(steer_input, -1.0, 0.0)

	### KBM STEERING ###
	if INPUT_SCHEME == INPUT_SCHEMES.KBM:
		var raw_steer_input : float = Input.get_axis("steer_left", "steer_right") * SETTINGS.KBM_steer_sensitivity
		steer_input += raw_steer_input
		steer_input = clampf(steer_input, -1.0, 1.0)

		### STEER STRAIGHTEN ###
		if do_wheel_straighten:
			if absf(raw_steer_input) < 0.01:
				#TODO steering make break if straigten speed is > steer sensitivity
				if steer_input > 0.0:
					steer_input -= SETTINGS.KBM_steer_straighten_speed * delta
					steer_input = clampf(steer_input, 0, 1.0)
				elif steer_input < 0.0:
					steer_input += SETTINGS.KBM_steer_straighten_speed * delta
					steer_input = clampf(steer_input, -1.0, 0.0)

	throttle = Input.get_action_strength("throttle")
	brake_input = Input.get_action_strength("brake")

	if Input.is_action_just_pressed("shift_up"):
		var new_gear : int = cur_gear + 1
		if new_gear < GEAR.size():
			_change_gear(new_gear)

	if Input.is_action_just_pressed("shift_down"):
		var new_gear : int = cur_gear - 1
		if new_gear >= 0:
			_change_gear(new_gear)
	
	if Input.is_action_pressed("restart"):
		_vel = 0
		get_tree().reload_current_scene()




	
func _input(event: InputEvent) -> void:
	#keyboard
	if event is InputEventKey or event is InputEventMouse:
		if INPUT_SCHEME != INPUT_SCHEMES.KBM:
			_set_input_scheme(INPUT_SCHEMES.KBM)
	#gamepad
	elif event is InputEventJoypadButton: 
		if INPUT_SCHEME != INPUT_SCHEMES.GAMEPAD:
			_set_input_scheme(INPUT_SCHEMES.GAMEPAD)
	elif event is InputEventJoypadMotion:
		#prevents switching input modes very quickly if there is stickdrift
		if event.axis_value > SETTINGS.joystick_deadzone:
			if INPUT_SCHEME != INPUT_SCHEMES.GAMEPAD:
				_set_input_scheme(INPUT_SCHEMES.GAMEPAD)

func _set_input_scheme(scheme: INPUT_SCHEMES)->void:
	INPUT_SCHEME = scheme 

	if INPUT_SCHEME == INPUT_SCHEMES.KBM:
		print("kbm")
	elif INPUT_SCHEME == INPUT_SCHEMES.GAMEPAD:
		print("gaempad")
