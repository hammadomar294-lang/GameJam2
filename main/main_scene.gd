class_name MainScene
extends Node2D


func _notification(what: int) -> void:
	# Terminate immediately when the player manually closes the window.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
