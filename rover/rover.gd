extends RigidBody3D
class_name Rover

@export var wheels : Array[Wheel]

@export var spring_strength : float = 100
@export var spring_damping : float = 2
@export var wheel_radius : float = .2
@onready var rest_length : float 

func _ready() -> void:
	# length of the raycast
	rest_length = absf((wheels[0].position.y - wheels[0].target_position.y)) / 2
	


func _physics_process(delta: float) -> void:
	for wheel in wheels:
		_do_single_wheel_suspension(wheel)

func _do_single_wheel_suspension(wheel : Wheel)->void:
	wheel.force_raycast_update()
	if wheel.is_colliding():
		wheel.target_position.y = -(rest_length + wheel_radius)
		var contact : Vector3 = wheel.get_collision_point()
		var spring_up_dir : Vector3 = wheel.global_basis.y
		var spring_len : float = wheel.global_position.distance_to(contact) - wheel_radius
		var offset : float = rest_length - spring_len 

		wheel.wheel_mesh.position.y  = -spring_len

		var spring_force : float = spring_strength * offset

		# damping force = damping * relative velocity
		var world_vel : Vector3 = _get_point_velocity(contact)
		var relative_vel : float = spring_up_dir.dot(world_vel)
		var spring_damp_force : float = spring_damping * relative_vel


		var force_vec : Vector3 = (spring_force - spring_damp_force) * spring_up_dir

		var force_pos_offset : Vector3 = contact - self.global_position # apply_forces wants an offset and not a global pos

		apply_force(force_vec, force_pos_offset)

		DebugDraw3D.draw_arrow(contact, contact + force_vec, Color.RED,.01) #draw_arrow_ray(contact, force_vec, 2.5)

func _get_point_velocity(point : Vector3)->Vector3:
	return linear_velocity + angular_velocity.cross(point - global_position)
