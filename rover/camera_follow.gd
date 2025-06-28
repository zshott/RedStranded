extends Camera3D


@export var spring_target : Node3D
@export var lerp_speed : float = 1.0


func _process(delta: float) -> void:
	position = lerp(position, spring_target.position, delta * lerp_speed)