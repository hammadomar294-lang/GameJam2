class_name PlayerMovementBarController
extends Node
## PlayerMovementBarController
##
## Time-based movement overheat system for the orbital player.
##
## Buildup (A / D held):
##   While the player HOLDS a rotation input (move_left / move_right, or the
##   ui_left / ui_right arrow keys) the movement meter fills continuously from
##   the time spent pressing the key. A full bar corresponds to
##   `max_press_time` seconds of uninterrupted holding.
##
## Decay:
##   Releasing every rotation key makes the meter drain back toward 0 at a
##   steady, customizable rate (`decay_rate` units per second).
##
## Overheat penalty (3-second lockout):
##   When the meter hits its MAXIMUM value:
##     1. ALL movement is locked instantly (is_movement_locked()).
##     2. A strict window runs via get_tree().create_timer(3.0).timeout.
##     3. The ProgressBar flashes aggressively (red/white Tween loop).
##     4. When the window elapses the bar resets to 0, flashing stops, and
##        movement is re-enabled.
##
## This is a pure "brain": the owning CharacterBody2D polls
## is_movement_locked() each physics frame to decide whether to apply orbital
## movement. Rotating along a ring (A / D) is the ONLY thing that builds heat.

# --- Signals ---------------------------------------------------------------
## Emitted when the movement lock state changes (true = locked / false = free).
signal movement_lock_changed(locked: bool)

# --- Public tuning ---------------------------------------------------------
## Continuous seconds of holding a rotation key that fills the whole bar.
@export var max_press_time: float = 2.5
## Meter units lost per second while no rotation key is held (decay speed).
@export var decay_rate: float = 0.6
## Total lockout duration in seconds once the bar maxes out.
@export var overheat_penalty_duration: float = 1.0
## Path to the UI ProgressBar that shows the meter (relative to this node).
@export var movement_bar_path: NodePath = NodePath()

# --- Runtime state ---------------------------------------------------------
var _heat: float = 0.0
var _movement_locked: bool = false
var _movement_bar: ProgressBar = null
var _flash_tween: Tween = null


func _ready() -> void:
	_resolve_bar()


## Time-accumulation core. Runs every physics frame:
## - fills the meter while a rotation key is held,
## - drains it steadily once released,
## - triggers the 3-second overheat penalty at full capacity.
func _physics_process(delta: float) -> void:
	_resolve_bar()
	if _movement_locked:
		return  # meter frozen (full + flashing) during the penalty window

	var key_held: bool = _is_rotation_input_held()
	if key_held:
		# Continuous press-time accumulation: full bar = max_press_time seconds.
		_heat = minf(_heat + delta / maxf(max_press_time, 0.01), 1.0)
	else:
		# Steady natural decay while resting.
		_heat = maxf(_heat - decay_rate * delta, 0.0)

	_sync_bar_value()
	if _heat >= 1.0:
		_start_overheat()


## Whether movement inputs are currently locked (overheated).
func is_movement_locked() -> bool:
	return _movement_locked


## True while any rotation key (A / D or the arrow keys) is held down.
func _is_rotation_input_held() -> bool:
	return Input.is_action_pressed("move_left") \
		or Input.is_action_pressed("move_right") \
		or Input.is_action_pressed("ui_left") \
		or Input.is_action_pressed("ui_right")


## Resolves the ProgressBar lazily. The UI is a later sibling in the scene
## tree, so it may only exist after the first frames. Safe to call repeatedly;
## it is a no-op once the bar is found.
##
## Resolution order:
##   1. `movement_bar_path` (explicit @export NodePath, set by the scene).
##   2. A node in the "movement_reload_bar" group as a robust fallback.
func _resolve_bar() -> void:
	if _movement_bar != null:
		return
	if movement_bar_path != NodePath():
		_movement_bar = get_node_or_null(movement_bar_path) as ProgressBar
	if _movement_bar == null:
		_movement_bar = get_tree().get_first_node_in_group("movement_reload_bar") as ProgressBar
	if _movement_bar != null:
		_movement_bar.max_value = 1.0
		_movement_bar.value = _heat
		_movement_bar.show_percentage = false


func _sync_bar_value() -> void:
	if _movement_bar != null:
		_movement_bar.value = _heat


## Locks all movement and opens the 3-second flashing penalty window. Uses a
## process-independent SceneTree timer so the penalty always elapses.
func _start_overheat() -> void:
	_movement_locked = true
	movement_lock_changed.emit(true)
	_start_flashing()
	get_tree().create_timer(overheat_penalty_duration).timeout.connect(_end_overheat)


## Oscillates the bar between its standard color and bright red via an
## infinitely looping Tween. Killed cleanly when the penalty ends.
func _start_flashing() -> void:
	if _movement_bar == null:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween().set_loops()
	_flash_tween.tween_property(_movement_bar, "self_modulate", Color(1.0, 0.1, 0.1), 0.12)
	_flash_tween.tween_property(_movement_bar, "self_modulate", Color.WHITE, 0.12)


## Ends the penalty: resets the meter to 0, stops the flashing visual, and
## restores full movement controls.
func _end_overheat() -> void:
	_movement_locked = false
	_heat = 0.0
	if _movement_bar != null:
		_movement_bar.value = 0.0
		_movement_bar.self_modulate = Color.WHITE
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = null
	movement_lock_changed.emit(false)