class_name InputComponent
extends Node

var direction: float = 0.0


func _process(_delta: float) -> void:
	direction = Input.get_axis("move_left", "move_right")
