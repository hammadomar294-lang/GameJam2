extends Node
## HitStopManager
##
## A production-ready Hit Stop (time freeze) singleton.
##
## Freezes gameplay for a very short moment by dropping Engine.time_scale to 0,
## then safely restores it after an independent SceneTreeTimer elapses. The
## timer runs on real (wall-clock) time, so it always fires and restores the
## game even while the whole scene is frozen.
##
## Usage (from any node, once added as an AutoLoad named "HitStopManager"):
##   HitStopManager.small_hit_stop()
##   HitStopManager.medium_hit_stop()
##   HitStopManager.big_hit_stop()

# --- Public tuning presets -------------------------------------------------
# Quick, subtle freeze (pistol hits, minor impacts).
const SMALL_DURATION := 0.04
# Standard impactful freeze (melee hits, medium enemy strikes).
const MEDIUM_DURATION := 0.09
# Heavy, dramatic freeze (boss hits, critical damage, kills).
const BIG_DURATION := 0.16

# The time_scale applied while a freeze is active (0 fully freezes the game).
const FREEZE_SCALE := 0.0

# Guards against overlapping hit stops so an older, longer freeze can never
# restore time while a newer one is still running.
var _freeze_token: int = 0

# The time_scale to restore once the freeze ends (in case it was not 1.0).
var _original_time_scale: float = 1.0


## Quick, subtle freeze (pistol hits, minor impacts).
func small_hit_stop() -> void:
	_apply_hit_stop(SMALL_DURATION)


## Standard impactful freeze (melee hits, medium enemy strikes).
func medium_hit_stop() -> void:
	_apply_hit_stop(MEDIUM_DURATION)


## Heavy, dramatic freeze (boss hits, critical damage, kills).
func big_hit_stop() -> void:
	_apply_hit_stop(BIG_DURATION)


## Core coroutine: freeze the engine, wait in real time, then restore time
## only if this is still the most recent hit stop request.
func _apply_hit_stop(duration: float) -> void:
	if duration <= 0.0:
		return

	_freeze_token += 1
	var token: int = _freeze_token

	# Only remember the "normal" scale if we are not already frozen, so an
	# overlapping hit stop restores to the correct original value, not to 0.
	if Engine.time_scale != FREEZE_SCALE:
		_original_time_scale = Engine.time_scale

	Engine.time_scale = FREEZE_SCALE

	# process_always=true     -> the timer keeps running even if the tree pauses.
	# ignore_time_scale=true  -> it counts down in REAL time, so it fires even
	#                            though we just set Engine.time_scale to 0.
	var timer: SceneTreeTimer = get_tree().create_timer(duration, true, false, true)
	await timer.timeout

	# Only restore if no newer hit stop started while we were frozen.
	if token == _freeze_token:
		Engine.time_scale = _original_time_scale
