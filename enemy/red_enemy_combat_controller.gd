class_name RedEnemyCombatController
extends Node
## RedEnemyCombatController
##
## Orchestrates the red boss's combat behaviour. It owns:
##
##   1. TRANSFORM ANCHORS  - centres the enemy at the arena origin and doubles
##      its visual scale (exactly 2x).
##   2. AXIS ALIGNMENT     - rotates the boss sprite so it tracks the player
##      along Godot's default 2D forward vector (+X / Right), so it never
##      looks sideways while rotating.
##   3. STANDARD BULLETS   - drives the boss's normal bullet weapon at an
##      ACCELERATED fire rate via ShootTimer (base interval / 1.25).
##   4. RED BOMBS          - throws bomb projectiles onto random coordinates
##      across the three orbital movement rings (Inner / Middle / Outer).
##
## All members are strictly typed and follow PascalCase conventions.

# --- 1. Transform setup ----------------------------------------------------
# The arena origin the enemy is anchored to.
@export var anchor_position: Vector2 = Vector2.ZERO
# Exactly double the enemy's original size.
@export var enemy_scale: Vector2 = Vector2(2.0, 2.0)

# --- 3. Standard bullet weapon (accelerated firing) ------------------------
# Base seconds between standard bullet shots.
@export var shoot_interval: float = 0.5
# Firing-frequency multiplier: new_interval = base_interval / 1.25.
@export var shoot_speed_multiplier: float = 1.25

# --- 4. Red bomb launcher ---------------------------------------------------
@export var bomb_scene: PackedScene = null   # the RedBomb scene to throw
# Ring radii matched to the arena map's four stone walkways (~135/250/390/536).
@export var inner_radius: float = 135.0       # Inner ring radius (px)
@export var middle_radius: float = 250.0      # Middle ring radius (px)
@export var outer_radius: float = 390.0       # Outer ring radius (px)
@export var outermost_radius: float = 536.0   # Outermost ring radius (px)
# Optional explicit ring center. If left null the controller uses its parent
# node (the enemy) as the ring center.
@export var center_override: Node2D = null

const RING_COUNT := 4

@onready var bomb_timer: Timer = $BombTimer
@onready var shoot_timer: Timer = $ShootTimer


func _ready() -> void:
	# Seed the global RNG once so spawn patterns differ run-to-run.
	randomize()
	_apply_transform_setup()
	_configure_shoot_timer()
	_ensure_bomb_timer()


## ---- 1. Transform anchors -----------------------------------------------
## Centres the enemy at the arena origin (or parent centre) and doubles its
## visual size. The AnimatedSprite2D is kept centred on that origin via its
## offset so it can be rotated in place later.
func _apply_transform_setup() -> void:
	var host := get_parent() as Node2D
	if host == null:
		return
	host.position = anchor_position
	host.scale = enemy_scale


## ---- 2. Axis alignment (kept for reference; rotation is DISABLED) --------
## The boss is intentionally stuck and never rotates to track the player. It
## remains anchored at the arena origin facing a fixed direction (Godot's
## default 2D forward = +X / Right). To re-enable player tracking later, set
## sprite.rotation = host.global_position.direction_to(player).angle().
#
# func _process(_delta: float) -> void:
# 	var host := get_parent() as Node2D
# 	if host == null:
# 		return
# 	var sprite := host.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
# 	if sprite == null:
# 		return
# 	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
# 	if player == null or not is_instance_valid(player):
# 		return
# 	sprite.rotation = host.global_position.direction_to(player.global_position).angle()


## ---- 3. Accelerated standard-bullet timer -------------------------------
## The new shoot wait time is the base interval divided by the speed
## multiplier, e.g. 0.5 / 1.25 = 0.4 s (a 1.25x increase in fire frequency).
func _configure_shoot_timer() -> void:
	if shoot_timer == null:
		return
	var accelerated_interval: float = shoot_interval / shoot_speed_multiplier
	shoot_timer.wait_time = maxf(accelerated_interval, 0.01)
	shoot_timer.start()


## Fires the boss's standard bullet weapon. Connected to ShootTimer.timeout.
func _on_shoot_timer_timeout() -> void:
	var host: Node = get_parent()
	if host != null and host.has_method("fire_bullets"):
		host.fire_bullets()


## ---- 4. Red bomb launcher ------------------------------------------------
## Defensive: guarantee the bomb spawn timer is running even if the scene's
## Timer was not configured with autostart.
func _ensure_bomb_timer() -> void:
	if bomb_timer != null and bomb_timer.is_stopped():
		bomb_timer.start()


## World-space center the rings revolve around.
func _get_center() -> Vector2:
	if center_override != null and is_instance_valid(center_override):
		return center_override.global_position
	var parent: Node = get_parent()
	if parent is Node2D:
		return (parent as Node2D).global_position
	return Vector2.ZERO


## Radius of the ring at `index`, clamped to the valid range.
func _ring_radius(index: int) -> float:
	var radii: Array[float] = [inner_radius, middle_radius, outer_radius, outermost_radius]
	return radii[clampi(index, 0, RING_COUNT - 1)]


## Picks one of the 4 rings explicitly, a completely random angle, and returns
## a global landing coordinate on that ring.
func _get_random_ring_target() -> Vector2:
	var radii: Array[float] = [inner_radius, middle_radius, outer_radius, outermost_radius]
	var ring_index: int = randi_range(0, radii.size() - 1)
	var radius: float = radii[ring_index]
	var angle: float = randf_range(0.0, TAU)
	return _get_center() + Vector2.from_angle(angle) * radius


## Fires every 10 seconds: spawns a bomb onto a random ring coordinate. The
## bomb itself teleports to its landing point (see RedBomb).
func _on_bomb_timer_timeout() -> void:
	if bomb_scene == null:
		return
	_spawn_bomb()


## Instantiates a bomb at the enemy center aimed at a random ring coordinate.
func _spawn_bomb() -> void:
	var target_pos: Vector2 = _get_random_ring_target()

	var bomb: Node = bomb_scene.instantiate()
	get_tree().current_scene.add_child(bomb)
	bomb.global_position = _get_center()
	if bomb.has_method("initialize_bomb"):
		bomb.initialize_bomb(target_pos)
