extends JoltGeneric6DOFJoint3D

@export var rb : RigidBody3D
@export var is_steer : bool = false 

var last_rot_y : float = 0