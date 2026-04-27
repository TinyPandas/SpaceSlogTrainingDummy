## TaskTrainAtDummy - Custom task for the Training Dummy mod.
## Extends TaskCombat so we get the cancel_combat signal needed
## by pawn.lunge_and_return().
##
## Checks the pawn's equipped weapon:
##   - Ranged weapon (ProjectileWeapon): trains Ranged skill, no lunge
##   - Melee weapon / unarmed: trains Melee skill, lunge animation
##
## Configurable via ModLoader config system:
##   - training_speed_multiplier: scales XP gain and training duration
##   - enable_mood_boost: whether to grant "Had Fun" thought
##   - max_training_sessions: not used by the task directly (AI consideration)

extends TaskCombat

const MOD_ID: String = "tinypandas.training_dummy"
const BASE_TRAIN_DURATION_TICKS: int = 800  # roughly one in-game hour
const BASE_SWING_INTERVAL: int = 120        # ticks between practice swings
const BASE_XP_PER_SWING: float = 0.1        # XP gained per swing/shot (~0.6 XP per session)

var _dummy: Building
var _ticks: int = 0
var _is_ranged: bool = false
var _skill: StringName = RefOfSkill.MELEE

# Effective values (adjusted by config)
var _train_duration: int
var _swing_interval: int
var _xp_per_swing: float
var _mood_boost_enabled: bool


func on_task_selected(context: Context) -> void:
	_dummy = context.get(ref.variable)

	# Read config values
	var speed_mult: float = _get_config_float("training_speed_multiplier", 1.0)
	_mood_boost_enabled = _get_config_bool("enable_mood_boost", true)
	_xp_per_swing = _get_config_float("xp_per_swing", BASE_XP_PER_SWING)

	# Apply speed multiplier to duration only — XP is configured separately
	_train_duration = int(BASE_TRAIN_DURATION_TICKS / speed_mult)
	_swing_interval = BASE_SWING_INTERVAL

	if _dummy:
		target = _dummy
		completable = false
		pawn.facing.face_target(_dummy)

		# Determine training mode based on equipped weapon
		if pawn.inventory:
			var equipped: Weapon = pawn.inventory.try_get_item_in_slot(RefOfSlot.WEAPON)
			if equipped is ProjectileWeapon:
				_is_ranged = true
				_skill = RefOfSkill.RANGED
				weapon = equipped
	else:
		on_fail()


func task_tick() -> void:
	super()

	_ticks += 1

	if _ticks % _swing_interval == 0:
		_do_practice_swing()

	if _ticks >= _train_duration:
		_finish_training()


func _do_practice_swing() -> void:
	if !_dummy || !_dummy.spawned:
		on_fail()
		return

	pawn.facing.face_target(_dummy)

	# Grant skill experience based on weapon type
	if pawn.skills:
		pawn.skills.increase_experience_of_skill(_skill, _xp_per_swing)

	if _is_ranged:
		# Ranged: fire at the dummy (visual only, no projectile damage)
		if weapon and weapon.can_shoot_now():
			var target_pos: Vector2 = _dummy.position + _dummy.drawn_center()
			pawn.inventory.rotate_weapon_towards_pos(weapon, target_pos)
			weapon.try_shoot(target_pos, Callable(_on_ranged_hit), _dummy, pawn)
	else:
		# Melee: lunge animation toward the dummy
		pawn.lunge_and_return(_dummy.position, _swing_interval, _on_swing_landed, self)


func _on_swing_landed() -> void:
	if _dummy and _dummy.hit_sound_ref:
		var hit_type: StringName = pawn.get_hit_sound_type(weapon)
		var hit_sound: StringName = _dummy.hit_sound_ref.get(hit_type)
		if hit_sound:
			SoundManager.try_play_sfx_audio(hit_sound, _dummy.position)


func _on_ranged_hit(_entity_hit: Entity) -> void:
	# Absorb the hit — don't deal real damage to the dummy
	pass


func _finish_training() -> void:
	if _is_ranged and weapon:
		pawn.inventory.reset_weapon_offsets(pawn.curr_direction, weapon)
	completable = true
	if _mood_boost_enabled:
		pawn.mood.try_gain_thought(RefOfThought.HAD_FUN)
	on_completed()


# ─── Config helpers ──────────────────────────────────────────────

func _get_config_float(key: String, fallback: float) -> float:
	if ModdingAPI.has_method("get_config"):
		var val = ModdingAPI.get_config(MOD_ID, key)
		if val != null:
			return float(val)
	return fallback


func _get_config_bool(key: String, fallback: bool) -> bool:
	if ModdingAPI.has_method("get_config"):
		var val = ModdingAPI.get_config(MOD_ID, key)
		if val != null:
			return bool(val)
	return fallback
