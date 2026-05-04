# training_dummy_mod.gd — rewritten for ModLoader/ModdingAPI
extends SpaceslogMod

var _context_menu = null
var _context_menu_patched: bool = false

## Config-bound properties — updated automatically when the player changes settings
var training_speed_multiplier: float = 1.0
var xp_per_swing: float = 0.1
var enable_mood_boost: bool = true
var dummy_label: String = "Training Dummy"


func _on_mod_init(ctx) -> void:
	# Bind config values to properties — they're set immediately and auto-update on change
	ModdingAPI.bind_config(context.mod_id, "training_speed_multiplier", self, "training_speed_multiplier")
	ModdingAPI.bind_config(context.mod_id, "xp_per_swing", self, "xp_per_swing")
	ModdingAPI.bind_config(context.mod_id, "enable_mood_boost", self, "enable_mood_boost")
	ModdingAPI.bind_config(context.mod_id, "dummy_label", self, "dummy_label")
	context.log("Config bound — speed: %s, xp: %s, mood: %s, label: %s" % [
		training_speed_multiplier, xp_per_swing, enable_mood_boost, dummy_label])


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
	# Apply the dummy_label config to the building ref
	_apply_dummy_label()
	# Listen for config changes to update the label dynamically
	if ModdingAPI.has_method("_config_manager") or "_config_manager" in ModdingAPI:
		ModdingAPI._config_manager.config_value_changed.connect(_on_config_changed)

	# Reset patch state — the game scene may be rebuilt after _on_mod_ready
	# (e.g. "Restarting Systems"), so we must NOT eagerly patch here.
	# We rely on node_added to catch the ContextMenu when it is created.
	_context_menu_patched = false
	_context_menu = null

	# Listen for the ContextMenu node to appear (first load or after scene rebuild)
	get_tree().node_added.connect(_on_node_added)


func _apply_dummy_label() -> void:
	if Data.building.has(&"TrainingDummy"):
		Data.building[&"TrainingDummy"].title = dummy_label
		context.log("Set Training Dummy label to: %s" % dummy_label)


func _on_config_changed(mod_id: String, value_name: String, new_value) -> void:
	if mod_id != context.mod_id:
		return
	if value_name == "dummy_label":
		_apply_dummy_label()


func _patch_context_menu(node: Node) -> void:
	_context_menu = node
	# Remove any _train_at_dummy callables left by previous mod instances.
	# Old instances stay in the tree after ModLoader reloads, so their
	# callables are still "valid" — filter by method name instead.
	var cleaned: Array[Callable] = []
	for c in node._building_actions:
		if c.get_method() != &"_train_at_dummy":
			cleaned.append(c)
	node._building_actions = cleaned
	# Append our action
	node._building_actions.append(_train_at_dummy)
	_context_menu_patched = true
	context.log("Patched ContextMenu with 'Train at Training Dummy' action")


func _on_node_added(node: Node) -> void:
	if node.name == "ContextMenu" and "_building_actions" in node:
		# Always re-patch when a new ContextMenu appears — the old one may
		# have been destroyed during a scene rebuild.
		_context_menu_patched = false
		_patch_context_menu(node)


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
