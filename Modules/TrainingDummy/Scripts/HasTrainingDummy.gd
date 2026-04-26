## HasTrainingDummy - Consideration that finds an available Training Dummy.

extends PawnConsideration


func calculate(blackboard: Blackboard, actor: Pawn, option: Option) -> float:
	if actor.facility:
		var dummies: Array[Building] = _get_training_dummies(actor, actor.facility)
		if !dummies.is_empty():
			var target_info: TargetInfo = PawnAiUtility.get_closest_entity_to_pawn_with_path(
				dummies,
				actor,
				true,
				true
			)

			if target_info.entity && target_info.path:
				var context: Context = blackboard.get_context(option.ref.ref_type)
				context.entity = target_info.entity
				context.path = target_info.path
				return 0.25
	return 0


func _get_training_dummies(actor: Pawn, facility: Facility) -> Array[Building]:
	return facility.structure_tracker.all_structures.filter(
		func(b: Building) -> bool: return (
			!b.is_prefab
			&& b.ref.ref_type == &"TrainingDummy"
			&& ReservationUtility.can_reserve(actor, b)
		))
