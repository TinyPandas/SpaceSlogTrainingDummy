extends Node

## Training Dummy Mod - Autoload entry point
##
## The core challenge: Maker.make_task() and Maker.make_consideration() use
## ResourceLoader with res:// paths that only resolve inside the PCK.
## Loose .gd files on disk aren't visible to ResourceLoader in exported builds.
##
## Solution: We load our scripts from the filesystem using FileAccess,
## compile them into GDScript resources via source_code + reload(), then
## use take_over_path() to register them at the res:// paths that Maker
## expects. This makes ResourceLoader.exists() return true and load()
## return our script for those paths.

const MOD_TAG: String = "[TrainingDummyMod]"

## Resolve the mod folder on disk (works in both editor and export).
## In release builds, OS.get_executable_path().get_base_dir() gives us
## the game install directory where Mods/ lives.
var _mod_folder: String

var _patched: bool = false


func _ready() -> void:
	var base_dir: String = OS.get_executable_path().get_base_dir()
	_mod_folder = base_dir.path_join("Modules/TrainingDummy")
	print("%s Mod loaded. Mod folder: %s" % [MOD_TAG, _mod_folder])
	print("%s Waiting for data import..." % MOD_TAG)


func _process(_delta: float) -> void:
	if _patched:
		return

	# Data.tasks is populated by Core.import_data_files() during the splash screen.
	if Data.tasks.is_empty():
		return

	_patched = true
	set_process(false)
	print("%s Data loaded, applying patches..." % MOD_TAG)
	_apply_patches()


func _apply_patches() -> void:
	# Step 1: Load and register our custom scripts at the paths Maker expects.
	var task_ok: bool = _register_script(
		_mod_folder.path_join("Scripts/TaskTrainAtDummy.gd"),
		"res://Prefabs/AI/PawnAI/Tasks/TaskTrainAtDummy.gd"
	)
	var consideration_ok: bool = _register_script(
		_mod_folder.path_join("Scripts/HasTrainingDummy.gd"),
		"res://Prefabs/AI/PawnAI/Considerations/HasTrainingDummy.gd"
	)

	if !task_ok || !consideration_ok:
		printerr("%s Failed to register scripts, aborting." % MOD_TAG)
		return

	# Step 2: Register data entries.
	_register_task()
	_register_task_driver()
	_register_consideration()
	_register_pawn_option()
	_patch_human_reasoner()

	print("%s All patches applied successfully." % MOD_TAG)


# ─── Script loading via filesystem ──────────────────────────────────

## Reads a .gd file from disk, compiles it, and registers it at a res:// path
## so that ResourceLoader.exists() and load() will find it.
func _register_script(disk_path: String, res_path: String) -> bool:
	if !FileAccess.file_exists(disk_path):
		printerr("%s Script not found on disk: %s" % [MOD_TAG, disk_path])
		return false

	var file: FileAccess = FileAccess.open(disk_path, FileAccess.READ)
	if !file:
		printerr("%s Cannot open: %s (error %d)" % [MOD_TAG, disk_path, FileAccess.get_open_error()])
		return false

	var source: String = file.get_as_text()
	file.close()

	var script: GDScript = GDScript.new()
	script.source_code = source
	var err: Error = script.reload()
	if err != OK:
		printerr("%s Failed to compile %s (error %d)" % [MOD_TAG, disk_path, err])
		return false

	# take_over_path makes this resource the canonical resource for the given
	# res:// path. After this call, load(res_path) returns our script and
	# ResourceLoader.exists(res_path) returns true.
	script.take_over_path(res_path)

	print("%s  Registered script: %s -> %s" % [MOD_TAG, disk_path, res_path])
	return true


# ─── Data registration ───────────────────────────────────────────────

func _register_task() -> void:
	var task_data: Dictionary[StringName, Variant] = {
		&"task_type": &"TaskTrainAtDummy",
		&"title": "Train at dummy.",
		&"variable": "entity",
	}
	var ref: TaskRef = TaskRef.new(task_data)
	ref.ref_type = &"TrainAtDummy"
	Data.tasks[&"TrainAtDummy"] = ref
	print("%s  Registered task: TrainAtDummy" % MOD_TAG)


func _register_task_driver() -> void:
	var td_data: Dictionary[StringName, Variant] = {
		&"title": "Use training dummy.",
		&"description": "Training at {object_a}.",
		&"tasks": [&"Reserve", &"MoveTo", &"TrainAtDummy"] as Array[StringName],
		&"should_holster_weapon": false,
	}
	var ref: TaskDriverRef = TaskDriverRef.new(td_data)
	ref.ref_type = &"UseTrainingDummy"
	Data.task_driver[&"UseTrainingDummy"] = ref
	print("%s  Registered task driver: UseTrainingDummy" % MOD_TAG)


func _register_consideration() -> void:
	var con_data: Dictionary[StringName, Variant] = {
		&"consideration_type": &"HasTrainingDummy",
		&"title": "Has a training dummy to use.",
	}
	var ref: ConsiderationRef = ConsiderationRef.new(con_data)
	ref.ref_type = &"HasTrainingDummy"
	Data.pawn_considerations[&"HasTrainingDummy"] = ref
	print("%s  Registered consideration: HasTrainingDummy" % MOD_TAG)


func _register_pawn_option() -> void:
	var opt_data: Dictionary[StringName, Variant] = {
		&"title": "Use training dummy",
		&"context_text": "train at {entity_name}",
		&"pawn_considerations": [&"HasTrainingDummy"] as Array[StringName],
		&"task_driver": &"UseTrainingDummy",
		&"schedule_types": [&"Entertainment"] as Array[StringName],
	}
	var ref: OptionRef = OptionRef.new(opt_data)
	ref.ref_type = &"UseTrainingDummy"
	Data.pawn_options[&"UseTrainingDummy"] = ref
	print("%s  Registered pawn option: UseTrainingDummy" % MOD_TAG)


func _patch_human_reasoner() -> void:
	var human_reasoner: ReasonerRef = Data.pawn_reasoners.get(&"Human")
	if !human_reasoner:
		printerr("%s Could not find Human reasoner to patch!" % MOD_TAG)
		return

	if &"UseTrainingDummy" not in human_reasoner.pawn_options:
		human_reasoner.pawn_options.append(&"UseTrainingDummy")
		print("%s  Injected UseTrainingDummy into Human reasoner" % MOD_TAG)
	else:
		print("%s  UseTrainingDummy already in Human reasoner" % MOD_TAG)
