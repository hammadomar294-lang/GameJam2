class_name RedBomb
extends Area2D
## RedBomb
##
## A bomb thrown by the RedEnemyCombatController. Instead of flying across the
## arena, it abruptly TELEPORTS to its landing coordinate on one of the three
## orbital rings: it fades out at the enemy's position, reappears at the target
## ring position, then explodes after a short fuse.
##
## The teleport and explosion are driven by Tweens (frame-rate independent),
## and all state is strictly typed.

# --- Public tuning ---------------------------------------------------------
@export var teleport_duration: float = 0.3   # total fade-out + fade-in time (s)
@export var fuse_duration: float = 1.2       # seconds after landing before boom
@export var lifespan: float = 5.0            # max seconds in scene before cleanup
@export var explosion_radius: float = 45.0   # blast radius (px) around landing
@export var damage: float = 1.0              # damage dealt to the player on hit

# --- Runtime state ---------------------------------------------------------
var _target_pos: Vector2 = Vector2.ZERO
var _fuse_timer: float = 0.0
var _active: bool = false


func _ready() -> void:
	# Safety net: guarantee the bomb clears itself after `lifespan` seconds even
	# if the fuse/explosion never triggers. create_timer is process-independent
	# and the connection auto-drops if the bomb is freed earlier.
	get_tree().create_timer(lifespan).timeout.connect(_expire_lifetime)


## Cleanup fallback: detonate (or clear) the bomb after its max lifespan.
func _expire_lifetime() -> void:
	if is_instance_valid(self):
		_explode()


## Receives the landing destination, colors the bomb red, and starts the
## teleport. Called by the spawning controller right after the bomb is added.
func initialize_bomb(target_pos: Vector2) -> void:
	_target_pos = target_pos
	modulate = Color.RED
	_teleport_to_target()


## Fades out, snaps to the target ring position, fades back in, then arms the
## fuse. Uses a Tween so the sequence is smooth and frame-rate independent.
func _teleport_to_target() -> void:
	var half: float = teleport_duration * 0.5
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(self, "modulate:a", 0.0, half)
	tween.tween_callback(func() -> void:
		global_position = _target_pos
	)
	tween.tween_property(self, "modulate:a", 1.0, half)
	tween.tween_callback(func() -> void:
		_active = true
		_fuse_timer = fuse_duration
	)


func _process(delta: float) -> void:
	if not _active:
		return
	_fuse_timer -= delta
	if _fuse_timer <= 0.0:
		_explode()


## Damages the player if inside the blast radius, plays a quick red flash,
## then frees the node.
func _explode() -> void:
	_active = false
	set_process(false)

	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player != null and is_instance_valid(player) \
			and global_position.distance_to(player.global_position) <= explosion_radius \
			and player.has_method("take_damage"):
		player.take_damage(damage)

	var tween: Tween = create_tween()
	tween.tween_property($Sprite2D, "scale", Vector2(3.0, 3.0), 0.15)
	tween.parallel().tween_property($Sprite2D, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)
