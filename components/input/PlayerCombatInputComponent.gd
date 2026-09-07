class_name PlayerCombatInputComponent
extends Node
## PlayerCombatInputComponent
##
## Modular orbital combat-movement controller. It keeps the player on one of
## FOUR concentric rings (Inner / Middle / Outer / Outermost) around a central
## enemy and lets the player rotate along the ring or hop between rings.
##
## Input actions used (see Project Settings -> Input Map):
##   - ui_left / ui_right : rotate counter-clockwise / clockwise on the ring
##   - shift_ring_in (E)   : move to the next INNER ring (clamped at Inner)
##   - shift_ring_out (Q)  : move to the next OUTER ring (clamped at Outermost)
##
## This is a pure "brain": it computes a target world position. The owning
## character script calls apply_to() (or reads get_target_position()) every
## physics frame to actually move the body.

# Emitted whenever the player actually hops to another ring (not blocked).
signal ring_shifted(ring_index: int)

# --- Public tuning ---------------------------------------------------------
# Ring radii matched to the four concentric stone walkways on the arena map
# (res://map.png): Inner ~141, Middle ~255, Outer ~390, plus the NEW dedicated
# Outermost path ~536 (measured from the map's 4th stone ring, band 503-572).
# Pressing Q repeatedly moves OUT one ring at a time through all four.
@export var inner_radius: float = 135.0        # Inner ring radius (px)
@export var middle_radius: float = 250.0       # Middle ring radius (px)
@export var outer_radius: float = 390.0        # Outer ring radius (px)
@export var outermost_radius: float = 536.0    # NEW Outermost ring radius (px)

@export var angular_speed: float = 3.0         # radians/second around the ring
@export var ring_transition_speed: float = 8.0 # lerp rate toward the active ring

# The enemy this component orbits. Its global_position is used as the ring
# center. Leave null to orbit fallback_center instead (e.g. world origin).
@export var enemy: Node2D = null
# Center used when no enemy reference is provided (default: world origin).
@export var fallback_center: Vector2 = Vector2.ZERO

# --- Runtime state ---------------------------------------------------------
var _ring_index: int = 1         # 0=Inner, 1=Middle, 2=Outer, 3=Outermost
var _angle: float = 0.0          # current orbital angle (radians)
var _radius: float = 0.0         # current (smoothed) radius toward active ring

const RING_COUNT := 4


func _ready() -> void:
	# Register the custom ring-shift actions if they are missing (e.g. when the
	# running editor has a stale InputMap and never picked them up from
	# project.godot). This keeps the component working regardless of cache.
	_ensure_actions()
	_radius = _ring_radius(_ring_index)


## Defensively registers the custom actions used by this component.
func _ensure_actions() -> void:
	if not InputMap.has_action("shift_ring_in"):
		InputMap.add_action("shift_ring_in")
		InputMap.action_add_event("shift_ring_in", _key_event(KEY_E))
	if not InputMap.has_action("shift_ring_out"):
		InputMap.add_action("shift_ring_out")
		InputMap.action_add_event("shift_ring_out", _key_event(KEY_Q))


## Builds an InputEventKey for the given physical key code.
func _key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	return event


# --- Public queries ---------------------------------------------------------

## Radius of the ring at `index`, clamped to the valid range.
func _ring_radius(index: int) -> float:
	var radii: Array[float] = [inner_radius, middle_radius, outer_radius, outermost_radius]
	return radii[clampi(index, 0, RING_COUNT - 1)]


## World-space center the rings revolve around.
func get_center_position() -> Vector2:
	if enemy != null and is_instance_valid(enemy):
		return enemy.global_position
	return fallback_center


## Radius of the currently active ring.
func get_current_radius() -> float:
	return _ring_radius(_ring_index)


## Current ring index (0=Inner, 1=Middle, 2=Outer, 3=Outermost).
func get_ring_index() -> int:
	return _ring_index


## Desired world position on the current ring at the current angle.
func get_target_position() -> Vector2:
	return get_center_position() + Vector2.from_angle(_angle) * _radius


# --- Main update -----------------------------------------------------------

## Advance the orbital state from live input for this frame.
## Call once per physics frame.
func update(delta: float) -> void:
	# Rotate along the ring. Support both the classic A/D actions and the
	# arrow keys (ui_left/ui_right), clamped so pressing both never doubles.
	var direction: float = Input.get_axis("move_left", "move_right")
	direction += Input.get_axis("ui_left", "ui_right")
	direction = clampf(direction, -1.0, 1.0)
	_angle += direction * angular_speed * delta

	# Hop between rings, guarded by boundary checks so we never leave the
	# valid Inner..Outer range. Only a successful hop emits ring_shifted.
	if Input.is_action_just_pressed("shift_ring_in") and _ring_index > 0:
		_ring_index -= 1
		ring_shifted.emit(_ring_index)
	if Input.is_action_just_pressed("shift_ring_out") and _ring_index < RING_COUNT - 1:
		_ring_index += 1
		ring_shifted.emit(_ring_index)

	# Smoothly glide the radius toward the active ring for a clean transition.
	var target_radius: float = _ring_radius(_ring_index)
	_radius = lerpf(_radius, target_radius, clampf(ring_transition_speed * delta, 0.0, 1.0))


## Convenience: update state, then place `entity` at the orbital position.
## Use this from the owning character's _physics_process.
func apply_to(entity: Node2D, delta: float) -> void:
	update(delta)
	entity.global_position = get_target_position()
