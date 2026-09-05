class_name DynamicPlayerCamera2D
extends Camera2D
## DynamicPlayerCamera2D
##
## A follow-camera that keeps a target (the player) fully framed on screen by
## continuously adjusting its position and zoom based on a configurable safety
## bounding box.
##
## The safety box is a central rectangle inset from the four screen edges by
## per-side margins given as fractions of the viewport size. Larger margins =>
## a smaller box => the camera starts moving and zooming out much sooner, so
## the player stays well away from the absolute edges of the viewport.
##
## The camera rests at `preferred_zoom`. When the player crosses the box limit
## the camera re-centers (smooth lerp) and zooms out so the player is framed
## back inside the box. Zoom is clamped between min_zoom and max_zoom. All
## transitions are frame-rate independent (lerp + delta).

# --- Safety margins (fractions of the viewport, 0.0 .. 0.5) -----------------
# Each margin insets the safety box from its own screen edge. 0.25 = the box
# ends a quarter of the viewport in from each edge (a central 50% x 50% box).
# The bigger the margins, the earlier the camera reacts near screen edges.
@export var margin_left: float = 0.25
@export var margin_right: float = 0.25
@export var margin_top: float = 0.25
@export var margin_bottom: float = 0.25

# Hard cap so a margin can never exceed half the viewport (which would make
# the safety box collapse or invert).
const MAX_MARGIN: float = 0.49

# --- Smoothing (higher = snappier follow) -----------------------------------
@export var follow_speed: float = 6.0
@export var zoom_speed: float = 5.0

# --- Zoom tuning ------------------------------------------------------------
# Preferred zoom when the player is comfortably inside the safety box.
@export var preferred_zoom: float = 1.4
# Hard limits: min_zoom = most zoomed OUT, max_zoom = most zoomed IN.
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.5

# The node to keep framed. Assign the Player in the editor; if left empty the
# camera falls back to any node in the "player" group.
@export var target: Node2D = null

# --- Debug visualization ----------------------------------------------------
# Toggle the bounding-box overlay rendered via _draw() in game AND editor.
@export var debug_draw: bool = false
@export var debug_fill_color: Color = Color(0.2, 1.0, 0.3, 0.25)
@export var debug_line_color: Color = Color(0.2, 1.0, 0.3, 0.9)


func _ready() -> void:
	if target == null:
		target = get_tree().get_first_node_in_group("player") as Node2D
	queue_redraw()


func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return

	if debug_draw:
		queue_redraw()  # keep the overlay in sync with zoom/resize

	var viewport_size: Vector2 = get_viewport_rect().size
	var current_zoom: float = zoom.x

	# Offset from the camera center to the player, in world units.
	var player_offset: Vector2 = target.global_position - global_position

	# World-space half-extents of the safety box on each side. The screen
	# margins (in pixels) are converted to world units by dividing by zoom.
	var box_left: float = (viewport_size.x * (0.5 - minf(margin_left, MAX_MARGIN))) / current_zoom
	var box_right: float = (viewport_size.x * (0.5 - minf(margin_right, MAX_MARGIN))) / current_zoom
	var box_top: float = (viewport_size.y * (0.5 - minf(margin_top, MAX_MARGIN))) / current_zoom
	var box_bottom: float = (viewport_size.y * (0.5 - minf(margin_bottom, MAX_MARGIN))) / current_zoom

	# --- Position: pull the camera so the player stays inside the safety box.
	var target_pos: Vector2 = global_position
	target_pos.x = target.global_position.x - clampf(player_offset.x, -box_left, box_right)
	target_pos.y = target.global_position.y - clampf(player_offset.y, -box_top, box_bottom)

	# --- Zoom: largest zoom that still frames the player inside the box.
	var framing_zoom: float = INF
	if absf(player_offset.x) > 0.001:
		var margin_x: float = margin_left if player_offset.x < 0.0 else margin_right
		framing_zoom = minf(
			framing_zoom,
			(viewport_size.x * (0.5 - minf(margin_x, MAX_MARGIN))) / absf(player_offset.x)
		)
	if absf(player_offset.y) > 0.001:
		var margin_y: float = margin_top if player_offset.y < 0.0 else margin_bottom
		framing_zoom = minf(
			framing_zoom,
			(viewport_size.y * (0.5 - minf(margin_y, MAX_MARGIN))) / absf(player_offset.y)
		)

	# Settle toward preferred_zoom, only zooming out as needed to frame, and
	# clamp to the hard limits.
	var desired_zoom: float = clampf(minf(preferred_zoom, framing_zoom), min_zoom, max_zoom)

	# --- Frame-rate independent interpolation ----------------------------------
	var t_pos: float = 1.0 - exp(-follow_speed * delta)
	var t_zoom: float = 1.0 - exp(-zoom_speed * delta)

	global_position = global_position.lerp(target_pos, t_pos)
	zoom = zoom.lerp(Vector2(desired_zoom, desired_zoom), t_zoom)


func _draw() -> void:
	## Renders the safety bounding box as a translucent rectangle with an
	## outline when debug_draw is enabled (works in the editor and in-game).
	if not debug_draw:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var z: float = zoom.x
	# Box borders live in screen pixels; divide by zoom so the rect lines up
	# with the actual on-screen safety area (Camera2D draws in world space
	# around its own position).
	var left: float = viewport_size.x * (minf(margin_left, MAX_MARGIN) - 0.5) / z
	var right: float = viewport_size.x * (0.5 - minf(margin_right, MAX_MARGIN)) / z
	var top: float = viewport_size.y * (minf(margin_top, MAX_MARGIN) - 0.5) / z
	var bottom: float = viewport_size.y * (0.5 - minf(margin_bottom, MAX_MARGIN)) / z
	var rect := Rect2(Vector2(left, top), Vector2(right - left, bottom - top))
	draw_rect(rect, debug_fill_color, true)
	draw_rect(rect, debug_line_color, false, 2.0)
