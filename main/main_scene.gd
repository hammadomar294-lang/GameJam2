class_name MainScene
extends Node2D


func _ready() -> void:
	# Match the clear (background) colour to the dark forest edge of the arena
	# map so the pillarbox bars blend seamlessly on the 16:9 viewport. Set at
	# runtime (RenderingServer) because the project setting is re-serialized by
	# the editor as an unparsable quoted string.
	RenderingServer.set_default_clear_color(Color(0.0431, 0.1961, 0.1373))


func _notification(what: int) -> void:
	# Terminate immediately when the player manually closes the window.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
