extends Control
@export var crawler : RockCrawler
@export var label : Label

func _process(_delta: float) -> void:
	if crawler:
		label.text = "FPS: %d\n" % Engine.get_frames_per_second()
		label.text += "RPM: %d\n" % crawler._rpm
		label.text += "Wheel Vel: %d\n" % crawler._vel
		label.text += "Wheel torque: %d\n" % crawler._wish_wheel_torque
		label.text += "Steer: %d\n" % crawler.steer_input
		label.text += "Throttle: %d\n" % crawler.throttle