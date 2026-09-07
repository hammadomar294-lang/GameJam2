class_name Player
extends CharacterBody2D
## ============================================================
## اللاعب (سلّايم) في نظام المدارات
## ------------------------------------------------------------
## - يدور حول العدو على 3 حلقات (120/180/260) ويطلق النار.
## - أنيميشن walk/idle + flip_h حسب اتجاه الحركة على الحلقة.
## - اللون يتغير حسب الحياة: أزرق -> أخضر -> أحمر + شريط حياة.
## ============================================================

@export var max_health: float = 3.0

var health: float = 0.0

# بادئة اسم الأنيميشن حسب المرحلة: [أزرق, أخضر, أحمر] (الأحمر مسمّى psd)
const COLOR_PREFIX: Array[String] = ["blue", "green", "psd"]

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_component: Node = %AttackComponent
@onready var health_bar: HealthBar = $HealthBar
@onready var hit_stop_manager: Node = get_node_or_null("/root/HitStopManager")
@onready var combat_input: PlayerCombatInputComponent = %PlayerCombatInputComponent
@onready var movement_bar_controller: PlayerMovementBarController = %PlayerMovementBarController


func _ready() -> void:
	add_to_group("player")
	health_bar.width = 44.0
	health_bar.height = 6.0
	health = max_health
	health_bar.set_ratio(1.0)

	# Orbit the enemy: resolve it from the "enemies" group so the rings revolve
	# around the correct center.
	combat_input.enemy = get_tree().get_first_node_in_group("enemies") as Node2D

	# The movement overheat bar is owned by PlayerMovementBarController
	# (child of Components), which reads the A/D hold duration to fill the
	# meter. Wire its ProgressBar path here explicitly (3 levels up from the
	# controller: Components -> Player -> Scene root, then into UI).
	if movement_bar_controller != null \
			and movement_bar_controller.movement_bar_path == NodePath():
		movement_bar_controller.movement_bar_path = NodePath("../../../UI/HeatPanel/MovementHeatBar")

	# Also allow firing with the Space key (in addition to the mouse click).
	_bind_space_to_shoot()
	_update_animation_state()


func take_damage(amount: float) -> void:
	if hit_stop_manager != null:
		hit_stop_manager.medium_hit_stop()

	health = maxf(health - amount, 0.0)
	health_bar.set_ratio(health / max_health)
	_update_animation_state()

	if health <= 0.0:
		get_tree().quit()  # player died -> close the game immediately


func _physics_process(delta: float) -> void:
	# Resolve the enemy lazily: it may not be in the "enemies" group yet when
	# _ready() ran, so re-check until we have a valid orbit center.
	if combat_input.enemy == null:
		combat_input.enemy = get_tree().get_first_node_in_group("enemies") as Node2D

	# Movement overheat lockout: while overheated the controller locks ALL
	# movement (orbit rotation + ring hops); the player stays pinned in place.
	# Shooting is intentionally unaffected.
	var movement_locked: bool = movement_bar_controller != null \
		and movement_bar_controller.is_movement_locked()
	if not movement_locked:
		combat_input.apply_to(self, delta)

	if Input.is_action_just_pressed("shoot"):
		_on_player_attacked()

	_update_animation_state()
	_flip_sprite()


func _on_player_attacked() -> void:
	attack_component.shoot()


func _color_prefix() -> String:
	# الحياة 3 -> أزرق (0)، 2 -> أخضر (1)، 1 -> أحمر (2)
	var stage: int = clampi(int(round(max_health - health)), 0, COLOR_PREFIX.size() - 1)
	return COLOR_PREFIX[stage]


func _update_animation_state() -> void:
	var prefix: String = _color_prefix()
	if absf(velocity.x) > 1.0:
		animated_sprite.play(prefix + " walk")
	else:
		animated_sprite.play(prefix + " idle")


func _flip_sprite() -> void:
	# وجّه السلّايم نحو الاتجاه الأفقي للحركة على الحلقة.
	if velocity.x > 1.0:
		animated_sprite.flip_h = false
	elif velocity.x < -1.0:
		animated_sprite.flip_h = true


## Registers the Space key on the "shoot" action if it is not already bound,
## so the player can fire with Space regardless of the cached Input Map.
func _bind_space_to_shoot() -> void:
	var space_event := InputEventKey.new()
	space_event.physical_keycode = KEY_SPACE
	if not InputMap.action_has_event("shoot", space_event):
		InputMap.action_add_event("shoot", space_event)
