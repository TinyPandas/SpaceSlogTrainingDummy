# training_dummy_mod.gd — rewritten for ModLoader/ModdingAPI
extends SpaceslogMod


func _on_mod_register(api: ModdingAPI) -> void:
	api.register_task(
		context.mod_id, &"TrainAtDummy", &"TaskTrainAtDummy",
		"Train at dummy.", "entity"
	)
	api.register_task_driver(
		context.mod_id, &"UseTrainingDummy",
		"Use training dummy.", "Training at {object_a}.",
		[&"Reserve", &"MoveTo", &"TrainAtDummy"] as Array[StringName]
	)
	api.register_consideration(
		context.mod_id, &"HasTrainingDummy", &"HasTrainingDummy",
		"Has a training dummy to use."
	)
	api.register_pawn_option(
		context.mod_id, &"UseTrainingDummy",
		"Use training dummy", "train at {entity_name}",
		[&"HasTrainingDummy"] as Array[StringName],
		&"UseTrainingDummy",
		[&"Entertainment"] as Array[StringName]
	)


func _on_mod_patch(api: ModdingAPI) -> void:
	api.patch_reasoner(context.mod_id, &"Human", &"UseTrainingDummy")
