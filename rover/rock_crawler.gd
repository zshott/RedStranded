extends RigidBody3D
class_name RockCrawler

@export var wheels: Array[JoltGeneric6DOFJoint3D]
@export var steer_wheels: Array[JoltGeneric6DOFJoint3D]
@export var axles: Array[JoltGeneric6DOFJoint3D]
@export var wheel_body : Array[RigidBody3D]
@export var test : RigidBody3D
@export var debug : Label

@export var ACCEL : float = 30
@export var MAX_SPEED : float = 40
@export_range(0.0, 90.0, 0.1) var MAX_STEER_ANGLE : float = 180
@export var WHEEL_FORCE_LIMIT : float = 5000

var motor_input : int = 0
var steer_input : float = 0
var last_rotation : float = 0

enum INPUT_SCEMES {KBM, GAMEPAD}
static var INPUT_SCHEME := INPUT_SCEMES.KBM

func _ready() -> void:
	for w in wheels:
		
		if w.is_steer:
				w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_UPPER, deg_to_rad(MAX_STEER_ANGLE))
				w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_LOWER, deg_to_rad(-MAX_STEER_ANGLE))
				#w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_MAX_TORQUE, 3000)
	for w in wheels:
		w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_MAX_TORQUE, WHEEL_FORCE_LIMIT)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("accelerate"):
		motor_input = 1
		print("blah")
	if event.is_action_released("accelerate"):
		motor_input = 0

	elif event.is_action_pressed("brake"):
		motor_input = -1
	if event.is_action_released("brake"):
		motor_input = 0
	# else:
	# 	var s := signf(motor_input)
	# 	motor_input += -s * 0.01

func _physics_process(delta: float) -> void:
	# if Input.is_action_pressed("accelerate"):
	# 	motor_input = 1

	# elif Input.is_action_pressed("brake"):
	# 	motor_input = -1
	# if event.is_action_released("brake"):
	# 	motor_input = 0
	# else:
	# 	var s := signf(motor_input)
	# 	motor_input += -s * 0.01
	
	# motor_input = clampf(motor_input, -1.0, 1.0)

	steer_input = Input.get_axis("steer_left", "steer_right")
	print(steer_input)
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
					

	# if steer_input:
# for w in wheels:
# 	if w.is_steer:
# 		#w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_UPPER, deg_to_rad(w.last_rot_y))
# 		#w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_LOWER, deg_to_rad(w.last_rot_y))
# 		if steer_input:
# 			w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_LOWER, deg_to_rad(-MAX_STEER_ANGLE))
# 			w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_UPPER, deg_to_rad(MAX_STEER_ANGLE))
# 		#w.rb.apply_torque(Vector3.UP * steer_input * 20) 
# 		#w.rb.apply_torque(Vector3.UP.cross(w.rb.basis.y) * 5)
# 		#.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_MOTOR, true)
# 		#w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_MAX_TORQUE, 10)
# 		w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, deg_to_rad(steer_input * 50))
# 	# elif w.is_steer:
# 		w.last_rot_y = w.rb.rotation_degrees.y

# 		# if w.last_rot_y < 2 and w.last_rot_y > -178:
# 		# 	w.last_rot_y = 0
			

# 		w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_SPRING_EQUILIBRIUM_POINT, deg_to_rad(w.last_rot_y))
		# 	w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, 0)

	for w in wheels:
		_do_wheel_accel(w, delta)
	# else:
	# 	for w in wheels:
			
	# 		if w.is_steer:
	# 			w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_UPPER, w.last_rot_y)
	# 			w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_LOWER, w.last_rot_y)
	# 			#w.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_MOTOR, false)
	# 			w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_MAX_TORQUE, 0)
	# 			w.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, 0)

	# 	for wb in wheel_body:
	# 			wb.apply_torque(Vector3.UP.cross(wb.basis.y) * 5)
	# 			last_rotation = test.rotation.y

	debug.text = str(-test.angular_velocity.dot(test.global_basis.x), '\n', test.rotation_degrees.y)#.dot(test.global_basis.z))
	#print(wheels[0].get_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY))
	#for w in wheel_body:
	#	test_accel(w)


func _do_wheel_accel(w: JoltGeneric6DOFJoint3D, delta: float)->void:
	w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, -motor_input * ACCEL)
	#w.rb.apply_torque(Vector3.LEFT.cross(w.rb.global_basis.x) * motor_input * ACCEL * 5)
	#DebugDraw3D.draw_arrow(w.rb.global_position, w.rb.global_position + (w.rb.global_basis) * Vector3.LEFT * motor_input * ACCEL, Color.BLUE, .01)
	#DebugDraw3D.draw_arrow(w.rb.global_position, w.rb.global_position + (-Vector3.UP.cross(w.rb.global_basis.y)) * motor_input *ACCEL/ 4, Color.RED, .01)

	
