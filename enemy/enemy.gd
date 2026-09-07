class_name Enemy
extends Area2D
## ============================================================
## العدو (سلّايم) في نظام المدارات
## ------------------------------------------------------------
## - يبقى مثبّتاً في مركز الشاشة (locked_to_center).
## - يطلق رصاصات باتجاه اللاعب، وفي المرحلة 2 (تحت 50 صحة) يطلق
##   رشقة من 3 رصاصات وينفجر لونه إلى الأحمر (psd).
## - يرمي قنابل حمراء عبر RedEnemyCombatController على الحلقات.
## - يظهر شريط الحياة فوقه.
## ============================================================

@export var max_health: float = 100.0
@export var bullet_stats: Resource
@export var bullet_spawn_distance: float = 60.0
@export var phase2_hp_threshold: float = 50.0
@export var phase2_spread_degrees: float = 30.0
# The enemy stays pinned at the world origin (teleportation applies to the
# bomb, not the enemy).
@export var locked_to_center: bool = true

var health: float = 0.0
var _phase2: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: HealthBar = $HealthBar
@onready var hit_stop_manager: Node = get_node_or_null("/root/HitStopManager")


func _ready() -> void:
	add_to_group("enemies")

	collision_layer = 0
	set_collision_layer_value(6, true)   # enemy_hurtbox
	collision_mask = 0
	set_collision_mask_value(4, true)   # bullets
	set_collision_mask_value(2, true)   # player

	health = max_health
	health_bar.set_ratio(1.0)

	animated_sprite.play("blue idle")


func _physics_process(_delta: float) -> void:
	# The enemy stays fixed at the center of the screen (locked to center).
	if locked_to_center:
		global_position = Vector2.ZERO


## Public entry point for the standard bullet weapon. Called by the
## RedEnemyCombatController's ShootTimer at the accelerated fire rate.
func fire_bullets() -> void:
	if bullet_stats == null or bullet_stats.bullet_scene == null:
		return

	var direction: Vector2 = Vector2.LEFT
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player != null:
		var to_player: Vector2 = (player.global_position - global_position).normalized()
		if to_player != Vector2.ZERO:
			direction = to_player

	var bullet_count: int = 3 if _phase2 else 1
	var spread_angle: float = deg_to_rad(phase2_spread_degrees) if _phase2 else 0.0

	for index in range(bullet_count):
		var bullet_direction := _get_bullet_direction(direction, index, bullet_count, spread_angle)
		var bullet: Area2D = bullet_stats.bullet_scene.instantiate()
		var scene_root: Node = get_tree().current_scene
		if scene_root == null:
			bullet.queue_free()
			return
		scene_root.add_child(bullet)
		bullet.global_position = global_position + bullet_direction * bullet_spawn_distance
		bullet.setup(bullet_stats, bullet_direction)


func _get_bullet_direction(base_direction: Vector2, index: int, count: int, spread: float) -> Vector2:
	if count == 1:
		return base_direction
	var angle_step: float = spread / float(count - 1)
	var angle_offset: float = -spread * 0.5 + angle_step * index
	return base_direction.rotated(angle_offset)


func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("bullets"):
		return

	var damage: float = 1.0
	if area.stats != null and "damage" in area.stats:
		damage = float(area.stats.damage)

	take_damage(damage)
	if hit_stop_manager != null:
		hit_stop_manager.medium_hit_stop()


func take_damage(amount: float) -> void:
	health = maxf(health - amount, 0.0)
	health_bar.set_ratio(health / max_health)

	if not _phase2 and health <= phase2_hp_threshold:
		_enter_phase2()

	if health <= 0.0:
		get_tree().quit()  # enemy killed -> close the game immediately
		queue_free()


func _enter_phase2() -> void:
	_phase2 = true
	# Enrage: يتحول لون السلّايم إلى الأحمر ويعزف "psd idle".
	animated_sprite.play("psd idle")
