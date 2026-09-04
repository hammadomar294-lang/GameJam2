class_name HealthBar
extends Node2D

@export var width: float = 140.0
@export var height: float = 14.0
@export var fill_color: Color = Color(0.22, 0.9, 0.3)
@export var background_color: Color = Color(0, 0, 0, 0.75)
@export var border_color: Color = Color(1, 1, 1, 0.5)

var ratio: float = 1.0


func set_ratio(value: float) -> void:
	ratio = clampf(value, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var top_left := Vector2(-width * 0.5, -height * 0.5)
	var bg_rect := Rect2(top_left, Vector2(width, height))

	draw_rect(bg_rect, background_color)

	if ratio > 0.0:
		var fill_rect := Rect2(top_left, Vector2(width * ratio, height))
		draw_rect(fill_rect, fill_color)

	draw_rect(bg_rect, border_color, false, 1.0)
