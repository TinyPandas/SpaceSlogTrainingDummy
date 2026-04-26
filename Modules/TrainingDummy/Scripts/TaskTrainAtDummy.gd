## TaskTrainAtDummy - Custom task for the Training Dummy mod.
## Extends TaskCombat so we get the cancel_combat signal needed
## by pawn.lunge_and_return().
##
## Checks the pawn's equipped weapon:
##   - Ranged weapon (ProjectileWeapon): trains Ranged skill, no lunge
##   - Melee weapon / unarmed: trains Melee skill, lunge animation

extends TaskCombat

const TRAIN_DURATION_TICKS: int = 800  # roughly one in-game hour
const SWING_INTERVAL: int = 120        # ticks between practice swings
const XP_PER_SWING: float = 0.1        # XP gained per swing/shot (~0.6 XP per session)

var _dummy: Building
var _ticks: int = 0
var _is_ranged: bool = false
var _skill: StringName = RefOfSkill.MELEE


func on_task_selected(context: Context) -> void:
	_dummy = context.get(ref.variable)

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

	if _ticks % SWING_INTERVAL == 0:
		_do_practice_swing()

	if _ticks >= TRAIN_DURATION_TICKS:
		_finish_training()


func _do_practice_swing() -> void:
	if !_dummy || !_dummy.spawned:
		on_fail()
		return

	pawn.facing.face_target(_dummy)

	# Grant skill experience based on weapon type
	if pawn.skills:
		pawn.skills.increase_experience_of_skill(_skill, XP_PER_SWING)

	if _is_ranged:
		# Ranged: fire at the dummy (visual only, no projectile damage)
		if weapon and weapon.can_shoot_now():
			var target_pos: Vector2 = _dummy.position + _dummy.drawn_center()
			pawn.inventory.rotate_weapon_towards_pos(weapon, target_pos)
			weapon.try_shoot(target_pos, Callable(_on_ranged_hit), _dummy, pawn)
	else:
		# Melee: lunge animation toward the dummy
		pawn.lunge_and_return(_dummy.position, SWING_INTERVAL, _on_swing_landed, self)


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
	pawn.mood.try_gain_thought(RefOfThought.HAD_FUN)
	on_completed()
