extends RigidBody3D
class_name Rover

@export var wheels : Array[RayCast3D]
@export var accel : float = 100
@export var decel : float = 33
@export var max_speed : float = 20
@export var accel_curve : Curve

@export var spring_strength : float = 100
@export var spring_damping : float = 2
@export var wheel_radius : float = .2
@onready var rest_length : float = .5
@export var over_extend : float = 0.0 

var grounded : bool 
var motor_input : int = 0


func _physics_process(delta: float) -> void:
	grounded = false
	for wheel in wheels:
		wheel.force_raycast_update()
		if wheel.is_colliding(): grounded = true
		_do_single_wheel_suspension(wheel)
		_do_single_wheel_accel(wheel, delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("accelerate"):
		motor_input = 1
	if event.is_action_released("accelerate"):
		motor_input = 0

	if event.is_action_pressed("brake"):
		motor_input = -1
	if event.is_action_released("brake"):
		motor_input = 0

func _do_single_wheel_accel(wheel : RayCast3D, delta :float)->void:
	var forward_dir : Vector3 = -wheel.global_basis.z
	var vel : float = forward_dir.dot(linear_velocity)
	#wheel.wheel_mesh.rotate_x(-vel * delta * 2 * PI * wheel_radius) # wheel surface area

	if wheel.is_colliding():
		var contact : Vector3 = wheel.global_position
		var force_pos_offset : Vector3 = contact - global_position

		if motor_input:
			var speed_ratio := vel / max_speed
			var ac : float = accel_curve.sample_baked(speed_ratio)
			var force_vec :Vector3 = forward_dir * accel * motor_input * ac
		# if abs(vel) > max_speed:
		# 	force_vec = force_vec * 0.1
			apply_force(force_vec, force_pos_offset)
			DebugDraw3D.draw_arrow(contact, contact + (force_vec / mass), Color.BLUE,.01)
		elif abs(vel) > 0.15 and not motor_input:
			var drag_force_vec = global_basis.z * decel * signf(vel)
			apply_force(drag_force_vec, force_pos_offset)
			DebugDraw3D.draw_arrow(contact, contact + (drag_force_vec / mass), Color.AZURE,.01)

func _do_single_wheel_suspension(wheel : RayCast3D)->void:
	
	if wheel.is_colliding():
		wheel.target_position.y = -(rest_length + wheel_radius + over_extend)
		var contact : Vector3 = wheel.get_collision_point()
		var spring_up_dir : Vector3 = wheel.global_basis.y
		var spring_len : float = wheel.global_position.distance_to(contact) - wheel_radius
		var offset : float = rest_length - spring_len 

		#wheel.wheel_mesh.position.y  = -spring_len

		var spring_force : float = spring_strength * offset

		# damping force = damping * relative velocity
		var world_vel : Vector3 = _get_point_velocity(contact)
		var relative_vel : float = spring_up_dir.dot(world_vel)
		var spring_damp_force : float = spring_damping * relative_vel


		var force_vec : Vector3 = (spring_force - spring_damp_force) * wheel.get_collision_normal()

		#contact = wheel.wheel_mesh.global_position # makes car a bit more stable
		var force_pos_offset : Vector3 = contact - self.global_position # apply_forces wants an offset and not a global pos

		apply_force(force_vec, force_pos_offset)

		DebugDraw3D.draw_arrow(contact, contact + (force_vec / mass), Color.RED,.01) #draw_arrow_ray(contact, force_vec, 2.5)

func _get_point_velocity(point : Vector3)->Vector3:
	return linear_velocity + angular_velocity.cross(point - global_position)
