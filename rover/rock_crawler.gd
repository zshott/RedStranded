extends Node3D
class_name RockCrawler

@export var wheels: Array[Generic6DOFJoint3D]
@export var wheel_body : Array[RigidBody3D]
@export var test : RigidBody3D

@export var ACCEL : float = 30
@export var MAX_SPEED : float = 40
@export var WHEEL_FORCE_LIMIT : float = 5000

var motor_input : int = 0

func _ready() -> void:
	for w in wheels:
		w.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_MOTOR_FORCE_LIMIT, WHEEL_FORCE_LIMIT)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("accelerate"):
		motor_input = 1
	if event.is_action_released("accelerate"):
		motor_input = 0

	if event.is_action_pressed("brake"):
		motor_input = -1
	if event.is_action_released("brake"):
		motor_input = 0

func _physics_process(delta: float) -> void:
	for w in wheels:
		_do_wheel_accel(w, delta)
	#for w in wheel_body:
	#	test_accel(w)


func _do_wheel_accel(w: Generic6DOFJoint3D, delta: float):
	w.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, motor_input * ACCEL)

	if abs(test.angular_velocity.dot(-test.global_basis.x)) > 1 or abs(test.linear_velocity.dot(-test.global_basis.x)) > 1:
		print(test.angular_velocity.dot(-test.global_basis.x), " | ", test.linear_velocity.dot(-test.global_basis.x))
	
func test_accel(w: RigidBody3D):
	w.apply_force(-w.global_basis.z * ACCEL * motor_input, w.position)
