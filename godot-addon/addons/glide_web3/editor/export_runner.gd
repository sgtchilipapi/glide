@tool
extends RefCounted

const GlideConstants := preload("res://addons/glide_web3/config/glide_constants.gd")
const ManagedPresetConfig := preload("res://addons/glide_web3/editor/managed_preset_config.gd")

func run_web_export() -> Dictionary:
	var project_root := ProjectSettings.globalize_path("res://")
	var output_dir_absolute := ProjectSettings.globalize_path(GlideConstants.DEFAULT_OUTPUT_DIR)
	var output_file_absolute := output_dir_absolute.path_join(GlideConstants.DEFAULT_WEB_EXPORT_FILE)
	var executable_path := OS.get_executable_path()
	var lines: Array[String] = []
	var managed_preset_config := RefCounted.new()
	managed_preset_config.set_script(ManagedPresetConfig)

	var prep := _prepare_output_dir(output_dir_absolute)
	if not prep.get("ok", false):
		return {
			"ok": false,
			"lines": prep.get("lines", ["Export failed."]),
		}

	for prep_line in prep.get("lines", []):
		lines.append(str(prep_line))

	var shell_config := managed_preset_config.ensure_custom_shell_path()
	for shell_line in shell_config.get("lines", []):
		lines.append(str(shell_line))

	if not shell_config.get("ok", false):
		lines.push_front("Export failed.")
		return {
			"ok": false,
			"lines": lines,
		}

	if executable_path.is_empty():
		lines.push_front("Export failed.")
		lines.append("Could not determine Godot editor executable path.")
		return {
			"ok": false,
			"lines": lines,
		}

	var args := PackedStringArray([
		"--headless",
		"--path", project_root,
		"--export-release", GlideConstants.MANAGED_PRESET_NAME,
		output_file_absolute,
	])

	var output: Array = []
	var exit_code := OS.execute(executable_path, args, output, true, false)

	lines.append("Export command finished.")
	lines.append("Executable: %s" % executable_path)
	lines.append("Preset: %s" % GlideConstants.MANAGED_PRESET_NAME)
	lines.append("Output file: %s" % output_file_absolute)
	lines.append("Exit code: %d" % exit_code)

	if not output.is_empty():
		lines.append("Process output:")
		for chunk in output:
			var text := str(chunk).strip_edges()
			if text.is_empty():
				continue
			for line in text.split("\n", false):
				lines.append(line)

	if exit_code != 0:
		lines.push_front("Export failed.")
		return {
			"ok": false,
			"lines": lines,
		}

	var copy_result := _copy_shell_assets(output_dir_absolute)
	for copy_line in copy_result.get("lines", []):
		lines.append(str(copy_line))

	if not copy_result.get("ok", false):
		lines.push_front("Export failed.")
		return {
			"ok": false,
			"lines": lines,
		}

	lines.push_front("Export succeeded.")
	return {
		"ok": true,
		"lines": lines,
		"output_file": output_file_absolute,
	}


func _prepare_output_dir(output_dir_absolute: String) -> Dictionary:
	if DirAccess.dir_exists_absolute(output_dir_absolute):
		return {
			"ok": true,
			"lines": ["Output directory ready: %s" % output_dir_absolute],
		}

	var error := DirAccess.make_dir_recursive_absolute(output_dir_absolute)
	if error != OK:
		return {
			"ok": false,
			"lines": [
				"Export failed.",
				"Could not create output directory: %s" % output_dir_absolute,
				"DirAccess error code: %d" % error,
			],
		}

	return {
		"ok": true,
		"lines": ["Created output directory: %s" % output_dir_absolute],
	}


func _copy_shell_assets(output_dir_absolute: String) -> Dictionary:
	var source_bridge_absolute := ProjectSettings.globalize_path(GlideConstants.WEB_SHELL_BRIDGE)
	var target_bridge_absolute := output_dir_absolute.path_join(GlideConstants.WEB_SHELL_BRIDGE.get_file())

	if not FileAccess.file_exists(GlideConstants.WEB_SHELL_BRIDGE):
		return {
			"ok": false,
			"lines": [
				"Shell asset copy failed.",
				"Missing bridge source file: %s" % GlideConstants.WEB_SHELL_BRIDGE,
			],
		}

	var copy_error := DirAccess.copy_absolute(source_bridge_absolute, target_bridge_absolute)
	if copy_error != OK:
		return {
			"ok": false,
			"lines": [
				"Shell asset copy failed.",
				"Could not copy bridge.js to output folder.",
				"Source: %s" % source_bridge_absolute,
				"Target: %s" % target_bridge_absolute,
				"DirAccess error code: %d" % copy_error,
			],
		}

	return {
		"ok": true,
		"lines": [
			"Copied shell asset: %s" % target_bridge_absolute,
		],
	}
