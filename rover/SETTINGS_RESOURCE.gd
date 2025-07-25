extends Resource
class_name SettingsResource


@export_group("Controls")
@export_subgroup("Gamepad")
@export var joystick_deadzone : float = 0.1
var joy_axis_rescale : float = 1.0/(1.0-joystick_deadzone)
const joy_rotation_multiplier = 200.0 * PI / 180.0

@export var gamepad_steer_sensitivity : float = 1.0
@export var gamepad_steer_straighten_speed : float = 1.0
@export var gamepad_throttle_sensitivity : float = 1.0
@export var gamepad_brake_sensitivity : float = 1.0
@export var gamepad_pedal_return_speed : float = 1.0

@export_subgroup("KBM")
@export var KBM_steer_sensitivity : float = 1.0
@export var KBM_steer_straighten_speed : float = 1.0
@export var KBM_throttle_sensitivity : float = 1.0
@export var KBM_brake_sensitivity : float = 1.0
@export var KBM_pedal_return_speed : float = 1.0