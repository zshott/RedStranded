extends Control
@export var crawler : RockCrawler
@export var label : Label

var total_decel : float = 0.0
var torque : float = 0.0
func _process(_delta: float) -> void:
	if crawler:
		label.text = "FPS: %d" % Engine.get_frames_per_second()
		label.text += "\nWheel Vel: " + str(crawler._vel ).left(5)
		label.text += "\nRPM: " + str(crawler._rpm).left(5)
		label.text += "\nDecel: " + str(total_decel).left(5)
		label.text += "\nTorque: " + str(torque).left(5)
		label.text += "\nSteer: " + str(crawler.steer_input).left(5)
		label.text += "\nThrottle: " + str(crawler.throttle).left(5)
		label.text += "\nBrake: " + str(crawler.brake_input).left(5)
		label.text += "\nGear: " + str(crawler.cur_gear)
