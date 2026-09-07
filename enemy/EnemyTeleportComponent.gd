class_name EnemyTeleportComponent
extends Node
## EnemyTeleportComponent
##
## Modular enemy component that abruptly teleports ("respawns") the enemy at a
## completely random location along one of the four concentric combat rings
## (Inner / Middle / Outer / Outermost). It selects a random ring and a random
## angle, then snaps the enemy's global_position to that point.
##
## A smooth fade-out / fade-in Tween on the enemy's Sprite2D hides the move so
## it reads as a clean blink teleport. After reappearing the enemy rotates to
## face the player so its existing bomb-throwing aim stays correct.
##
## Coordinates with other systems via the `teleport_completed` signal, which is
## emitted once the enemy is at its new position (after the fade-out, before
## the fade-in finishes).

## Emitted once the enemy has moved to its new ring position.
signal teleport_completed

# --- Public tuning ---------------------------------------------------------
@export var target: Node2D = null           # the enemy to teleport (defaults to parent)
@export var sprite: Sprite2D = null         # sprite to fade (defaults to target's Sprite2D)
@export var inner_radius: float = 135.0      # Inner ring radius (px)
@export var middle_radius: float = 250.0     # Middle ring radius (px)
@export var outer_radius: float = 390.0      # Outer ring radius (px)
@export var outermost_radius: float = 536.0  # Outermost ring radius (px)
# Optional explicit arena center. If left null the teleport uses the world
# origin as the rings' pivot (the enemy starts there).
@export var center_override: Node2D = null
@export var fade_duration: float = 0.25      # seconds for each fade half

const RING_COUNT := 4


func _ready() -> void:
	if target == null:
		target = get_parent() as Node2D
	if sprite == null and target != null:
		sprite = target.get_node_or_null("Sprite2D") as Sprite2D


## World-space center the rings revolve around.
func _get_center() -> Vector2:
	if center_override != null and is_instance_valid(center_override):
		return center_override.global_position
	return Vector2.ZERO


## Radius of the ring at `index`, clamped to the valid range.
func _ring_radius(index: int) -> float:
	var radii: Array[float] = [inner_radius, middle_radius, outer_radius, outermost_radius]
	return radii[clampi(index, 0, RING_COUNT - 1)]


## Teleports the enemy to a random coordinate on a randomly chosen ring.
## Public entry point for state machines / other components.
func teleport_to_random_ring_position() -> void:
	if target == null or not is_instance_valid(target):
		return
	var ring_index: int = randi_range(0, RING_COUNT - 1)
	var angle: float = randf_range(0.0, TAU)
	var destination: Vector2 = _get_center() + Vector2.from_angle(angle) * _ring_radius(ring_index)
	_perform_teleport(destination)


## Runs the fade-out -> move -> fade-in sequence and emits teleport_completed
## once the enemy is at its destination.
func _perform_teleport(destination: Vector2) -> void:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if sprite != null:
		tween.tween_property(sprite, "modulate:a", 0.0, fade_duration)

	tween.tween_callback(func() -> void:
		if target != null and is_instance_valid(target):
			target.global_position = destination
			_face_player()
		teleport_completed.emit()
	)

	if sprite != null:
		tween.tween_property(sprite, "modulate:a", 1.0, fade_duration)


## Rotates the enemy sprite toward the player so it keeps aiming correctly.
## Rotates only the sprite (not the whole enemy) so the health bar stays upright.
func _face_player() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null or not is_instance_valid(player):
		return
	var node_to_rotate: Node2D = sprite if sprite != null else target
	if node_to_rotate != null and is_instance_valid(node_to_rotate):
		node_to_rotate.look_at(player.global_position)
