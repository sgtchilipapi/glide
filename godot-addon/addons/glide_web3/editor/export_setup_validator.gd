@tool
extends RefCounted

const GlideConstants := preload("res://addons/glide_web3/config/glide_constants.gd")
const PresetDiscovery := preload("res://addons/glide_web3/editor/preset_discovery.gd")

func validate() -> Dictionary:
	var messages: Array[String] = []
	var errors := 0
	var warnings := 0
	var preset_discovery := RefCounted.new()
	preset_discovery.set_script(PresetDiscovery)

	if _validate_shell_files(messages):
		messages.append("OK: Web shell files found.")
	else:
		errors += 1

	if _validate_output_dir(messages):
		messages.append("OK: Output path is resolvable.")
	else:
		errors += 1

	var export_check := _validate_web_export_capability()
	messages.append(export_check.message)
	if export_check.ok:
		pass
	elif export_check.severity == "warning":
		warnings += 1
	else:
		errors += 1

	var templates_check := _validate_web_export_templates()
	messages.append_array(templates_check.messages)
	if templates_check.ok:
		pass
	elif templates_check.severity == "warning":
		warnings += 1
	else:
		errors += 1

	var preset_check := _validate_managed_preset(preset_discovery)
	messages.append(preset_check.message)
	if preset_check.ok:
		pass
	elif preset_check.severity == "warning":
		warnings += 1
	else:
		errors += 1

	var summary := "Validation passed."
	if errors > 0:
		summary = "Validation failed."
	elif warnings > 0:
		summary = "Validation passed with warnings."

	return {
		"ok": errors == 0,
		"summary": summary,
		"messages": messages,
		"errors": errors,
		"warnings": warnings,
	}


func _validate_shell_files(messages: Array[String]) -> bool:
	var ok := true

	if not FileAccess.file_exists(GlideConstants.WEB_SHELL_HTML):
		messages.append("ERROR: Missing shell HTML: %s" % GlideConstants.WEB_SHELL_HTML)
		ok = false

	if not FileAccess.file_exists(GlideConstants.WEB_SHELL_BRIDGE):
		messages.append("ERROR: Missing shell bridge: %s" % GlideConstants.WEB_SHELL_BRIDGE)
		ok = false

	return ok


func _validate_output_dir(messages: Array[String]) -> bool:
	var output_dir: String = GlideConstants.DEFAULT_OUTPUT_DIR

	if not (output_dir.begins_with("res://") or output_dir.begins_with("user://")):
		messages.append("ERROR: Output path must start with res:// or user://: %s" % output_dir)
		return false

	var absolute_path := ProjectSettings.globalize_path(output_dir)
	if absolute_path.is_empty():
		messages.append("ERROR: Output path could not be resolved: %s" % output_dir)
		return false

	messages.append("INFO: Output path resolves to: %s" % absolute_path)
	return true


func _validate_web_export_capability() -> Dictionary:
	if ClassDB.class_exists("EditorExportPlatformWeb"):
		return {
			"ok": true,
			"severity": "info",
			"message": "OK: Web export platform is available in the editor.",
		}

	return {
		"ok": false,
		"severity": "error",
		"message": "ERROR: Web export platform is not available in this editor build.",
	}


func _validate_managed_preset(preset_discovery: RefCounted) -> Dictionary:
	if preset_discovery.has_glide_web_preset():
		return {
			"ok": true,
			"severity": "info",
			"message": "OK: Managed preset found: %s" % GlideConstants.MANAGED_PRESET_NAME,
		}

	return {
		"ok": false,
		"severity": "warning",
		"message": "WARNING: Managed preset missing: %s" % GlideConstants.MANAGED_PRESET_NAME,
	}


func _validate_web_export_templates() -> Dictionary:
	if not Engine.has_singleton("EditorPaths"):
		return {
			"ok": false,
			"severity": "warning",
			"messages": [
				"WARNING: Could not access EditorPaths singleton to verify export templates.",
			],
		}

	var version_info := Engine.get_version_info()
	var version_dir := "%s.%s.%s.%s" % [
		str(version_info.get("major", 0)),
		str(version_info.get("minor", 0)),
		str(version_info.get("patch", 0)),
		str(version_info.get("status", "stable")),
	]

	var editor_data_dir := EditorPaths.get_data_dir()
	var templates_dir := editor_data_dir.path_join("export_templates").path_join(version_dir)
	var required_files := [
		templates_dir.path_join("web_nothreads_debug.zip"),
		templates_dir.path_join("web_nothreads_release.zip"),
	]

	var missing: Array[String] = []
	for file_path in required_files:
		if not FileAccess.file_exists(file_path):
			missing.append(file_path)

	if missing.is_empty():
		return {
			"ok": true,
			"severity": "info",
			"messages": [
				"OK: Web export templates found in: %s" % templates_dir,
			],
		}

	var messages: Array[String] = []
	messages.append("ERROR: Missing required Web export templates for Godot %s." % version_dir)
	for file_path in missing:
		messages.append("ERROR: Missing template: %s" % file_path)
	messages.append("ERROR: Install templates from Editor > Manage Export Templates.")

	return {
		"ok": false,
		"severity": "error",
		"messages": messages,
	}
