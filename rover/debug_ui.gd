extends Control
@export var crawler : RockCrawler
@export var label : Label

var total_decel : float = 0.0
func _process(_delta: float) -> void:
	if crawler:
		label.text = "FPS: %d\n" % Engine.get_frames_per_second()
		label.text += "Wheel Vel: %d\n" % crawler._vel
		label.text += "Decel: %d\n" % total_decel
		label.text += "Steer: %d\n" % crawler.steer_input
		label.text += "Throttle: %d\n" % crawler.throttle
		label.text += "Brake: %d\n" % crawler.brake_input
