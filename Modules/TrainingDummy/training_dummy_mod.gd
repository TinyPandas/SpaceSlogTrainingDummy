# training_dummy_mod.gd — rewritten for ModLoader/ModdingAPI
extends SpaceslogMod

var _context_menu = null
var _context_menu_patched: bool = false


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


func _on_mod_ready() -> void:
	# Listen for the ContextMenu node to appear (when a game is loaded)
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if _context_menu_patched:
		return
	if node.name == "ContextMenu" and "_building_actions" in node:
		_context_menu = node
		node._building_actions.append(_train_at_dummy)
		_context_menu_patched = true
		context.log("Patched ContextMenu with 'Train at Training Dummy' action")


func _train_at_dummy(thing, id: int) -> void:
	# Only show for built TrainingDummy buildings
	if not thing is Building:
		return
	if thing.ref.ref_type != &"TrainingDummy":
		return
	if thing.is_prefab:
		return

	var pawn = _context_menu._thing_selected
	var data = ContextMenuData.new(id, pawn, &"UseTrainingDummy")
	if not data or not data.option_ref:
		return

	# Check if already reserved by another pawn
	if not ReservationUtility.can_reserve(pawn, thing):
		var reservee = ReservationUtility.get_reservee_of(pawn.world, thing)
		var name_text = reservee.bio.nickname if reservee else Lang.translate("context", "someone_else")
		data.display_text = Lang.translate("context", "reserved_by_someone_else").format(
			{someone_else = name_text})
		data.disabled = true
		data.display_text = data.display_text.format(
			{adjective = _context_menu.get_text(data.option_ref.context_text, thing)})
		_context_menu.add_action_button(data)
		return

	# Use the same pathfinding as the AI consideration — finds the interaction cell (front)
	var target_info = PawnAiUtility.get_closest_entity_to_pawn_with_path(
		[thing], pawn, true, true
	)

	if target_info and target_info.entity and target_info.path:
		data.context.entity = target_info.entity
		data.context.path = target_info.path
		data.display_text = "{adjective}."
	else:
		data.display_text = Lang.translate("context", "no_path")
		data.disabled = true

	if data.display_text:
		data.display_text = data.display_text.format(
			{adjective = _context_menu.get_text(data.option_ref.context_text, thing)})
		_context_menu.add_action_button(data)
