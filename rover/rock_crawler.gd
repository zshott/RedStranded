extends RigidBody3D
class_name RockCrawler

@export var wheels: Array[JoltGeneric6DOFJoint3D]
@export var wheel_body : Array[RigidBody3D]
@export var test : RigidBody3D

@export var ACCEL : float = 30
@export var MAX_SPEED : float = 40
@export var WHEEL_FORCE_LIMIT : float = 5000

var motor_input : float = 0

func _ready() -> void:
	for w in wheels:
		w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_MAX_TORQUE, WHEEL_FORCE_LIMIT)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("accelerate"):
		motor_input += 0.01
		print("blah")
	# if event.is_action_released("accelerate"):
	# 	motor_input = 0

	elif event.is_action_pressed("brake"):
		motor_input -= 0.01
	# if event.is_action_released("brake"):
	# 	motor_input = 0
	else:
		var s := signf(motor_input)
		motor_input += -s * 0.01

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("accelerate"):
		motor_input += 0.01

	elif Input.is_action_pressed("brake"):
		motor_input -= 0.01
	# if event.is_action_released("brake"):
	# 	motor_input = 0
	else:
		var s := signf(motor_input)
		motor_input += -s * 0.01
	motor_input = clampf(motor_input, -1.0, 1.0)
	for w in wheels:
		_do_wheel_accel(w, delta)
	print(-test.angular_velocity.dot(test.global_basis.x))#.dot(test.global_basis.z))
	#print(wheels[0].get_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY))
	#for w in wheel_body:
	#	test_accel(w)


func _do_wheel_accel(w: JoltGeneric6DOFJoint3D, delta: float):
	w.set_param_x(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, motor_input * ACCEL)

	
func test_accel(w: RigidBody3D):
	w.apply_force(-w.global_basis.z * ACCEL * motor_input, w.position)
