@tool
extends EditorPlugin

const GlideConstants := preload("res://addons/glide_web3/config/glide_constants.gd")
const GlidePluginConfig := preload("res://addons/glide_web3/config/glide_plugin_config.gd")
const JsBridge := preload("res://addons/glide_web3/runtime/js_bridge.gd")
const EXPORT_PRESETS_FILE := "res://export_presets.cfg"

var _panel: Control
var _bottom_panel_button: Button
var _status_label: Label
var _preset_status_label: Label
var _output_dir_label: Label
var _shell_path_label: Label
var _backend_url_edit: LineEdit
var _output_dir_edit: LineEdit
var _app_title_edit: LineEdit
var _pwa_enabled_check: CheckBox
var _plugin_config: GlidePluginConfig

func _enter_tree() -> void:
	_plugin_config = _load_or_create_plugin_config()
	_panel = PanelContainer.new()
	_panel.name = GlideConstants.PLUGIN_NAME
	_build_panel_ui()
	_bottom_panel_button = add_control_to_bottom_panel(_panel, GlideConstants.PLUGIN_NAME)
	make_bottom_panel_item_visible(_panel)
	print("%s plugin enabled." % GlideConstants.PLUGIN_NAME)


func _exit_tree() -> void:
	if _panel:
		remove_control_from_bottom_panel(_panel)
		_panel.queue_free()
		_panel = null
		_bottom_panel_button = null
		_status_label = null
		_preset_status_label = null
		_output_dir_label = null
		_shell_path_label = null
		_backend_url_edit = null
		_output_dir_edit = null
		_app_title_edit = null
		_pwa_enabled_check = null
		_plugin_config = null
	print("%s plugin disabled." % GlideConstants.PLUGIN_NAME)


func _build_panel_ui() -> void:
	_panel.custom_minimum_size = Vector2(420, 180)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	_panel.add_child(content)

	var title_label := Label.new()
	title_label.text = GlideConstants.PLUGIN_NAME
	title_label.add_theme_font_size_override("font_size", 18)
	content.add_child(title_label)

	var description_label := Label.new()
	description_label.text = "Managed Web export and embedded wallet toolkit for Godot."
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(description_label)

	_preset_status_label = Label.new()
	_preset_status_label.text = _get_preset_status_text()
	content.add_child(_preset_status_label)

	_output_dir_label = Label.new()
	_output_dir_label.text = "Output: %s" % _get_output_dir()
	_output_dir_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_output_dir_label)

	_shell_path_label = Label.new()
	_shell_path_label.text = "Shell HTML: %s" % GlideConstants.WEB_SHELL_HTML
	_shell_path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_shell_path_label)

	var form := GridContainer.new()
	form.columns = 2
	form.add_theme_constant_override("h_separation", 8)
	form.add_theme_constant_override("v_separation", 6)
	content.add_child(form)

	var backend_url_title := Label.new()
	backend_url_title.text = "Backend URL"
	form.add_child(backend_url_title)

	_backend_url_edit = LineEdit.new()
	_backend_url_edit.placeholder_text = "https://api.example.com"
	_backend_url_edit.text = _plugin_config.backend_url
	form.add_child(_backend_url_edit)

	var output_dir_title := Label.new()
	output_dir_title.text = "Output Dir"
	form.add_child(output_dir_title)

	_output_dir_edit = LineEdit.new()
	_output_dir_edit.placeholder_text = GlideConstants.DEFAULT_OUTPUT_DIR
	_output_dir_edit.text = _plugin_config.output_dir
	form.add_child(_output_dir_edit)

	var app_title_title := Label.new()
	app_title_title.text = "App Title"
	form.add_child(app_title_title)

	_app_title_edit = LineEdit.new()
	_app_title_edit.placeholder_text = "Glide App"
	_app_title_edit.text = _plugin_config.app_title
	form.add_child(_app_title_edit)

	var pwa_title := Label.new()
	pwa_title.text = "Enable PWA"
	form.add_child(pwa_title)

	_pwa_enabled_check = CheckBox.new()
	_pwa_enabled_check.text = "On"
	_pwa_enabled_check.button_pressed = _plugin_config.pwa_enabled
	form.add_child(_pwa_enabled_check)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	content.add_child(button_row)

	var save_button := Button.new()
	save_button.text = "Save Config"
	save_button.pressed.connect(_on_save_config_pressed)
	button_row.add_child(save_button)

	var validate_button := Button.new()
	validate_button.text = "Validate Setup"
	validate_button.pressed.connect(_on_validate_setup_pressed)
	button_row.add_child(validate_button)

	var build_button := Button.new()
	build_button.text = "Build Web"
	build_button.pressed.connect(_on_build_web_pressed)
	button_row.add_child(build_button)

	var ping_button := Button.new()
	ping_button.text = "Ping Shell"
	ping_button.pressed.connect(_on_ping_shell_pressed)
	button_row.add_child(ping_button)

	_status_label = Label.new()
	_status_label.text = "Ready."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_status_label)


func _on_validate_setup_pressed() -> void:
	var result: Dictionary = _validate_setup()
	_refresh_preset_status()
	_refresh_output_dir_label()
	_set_validation_status(result)


func _on_build_web_pressed() -> void:
	var result: Dictionary = _validate_setup()
	_refresh_preset_status()
	_refresh_output_dir_label()

	if result.get("errors", 0) > 0:
		_set_validation_status(result)
		return

	if not _has_glide_web_preset():
		_set_status(
			"Build blocked. Missing managed preset %s. Create a Web export preset with that exact name in Project > Export."
			% GlideConstants.MANAGED_PRESET_NAME
		)
		return

	var export_result: Dictionary = _run_web_export()
	_set_lines(export_result.get("lines", ["Export finished."]))


func _on_save_config_pressed() -> void:
	_plugin_config.backend_url = _backend_url_edit.text.strip_edges()
	_plugin_config.output_dir = _output_dir_edit.text.strip_edges()
	_plugin_config.app_title = _app_title_edit.text.strip_edges()
	_plugin_config.pwa_enabled = _pwa_enabled_check.button_pressed
	_plugin_config.preset_name = GlideConstants.MANAGED_PRESET_NAME

	if _plugin_config.output_dir.is_empty():
		_plugin_config.output_dir = GlideConstants.DEFAULT_OUTPUT_DIR
		_output_dir_edit.text = _plugin_config.output_dir

	if _plugin_config.app_title.is_empty():
		_plugin_config.app_title = "Glide App"
		_app_title_edit.text = _plugin_config.app_title

	_save_plugin_config(_plugin_config)
	_refresh_output_dir_label()
	_set_lines([
		"Config saved.",
		"Backend URL: %s" % _plugin_config.backend_url,
		"Output: %s" % _plugin_config.output_dir,
		"App title: %s" % _plugin_config.app_title,
		"Shell HTML: %s" % GlideConstants.WEB_SHELL_HTML,
		"PWA enabled: %s" % str(_plugin_config.pwa_enabled),
	])


func _on_ping_shell_pressed() -> void:
	var bridge_status := JsBridge.get_bridge_status()
	if not bridge_status.get("ok", false):
		_set_lines([
			"JS bridge call failed.",
			"Method: ping",
			"Error code: %s" % str(bridge_status.get("code", "unknown_error")),
			"Error message: %s" % str(bridge_status.get("message", "Unknown error.")),
		])
		return

	_set_lines([
		"JS bridge call available.",
		"Method: ping",
		"Bridge status: ready",
		"Next step: route runtime ping through a Web-facing test surface.",
	])


func _refresh_preset_status() -> void:
	if _preset_status_label:
		_preset_status_label.text = _get_preset_status_text()


func _refresh_output_dir_label() -> void:
	if _output_dir_label:
		_output_dir_label.text = "Output: %s" % _get_output_dir()


func _set_validation_status(result: Dictionary) -> void:
	var lines: Array[String] = []
	lines.append(result.get("summary", "Validation finished."))

	var messages: Array = result.get("messages", [])
	for message in messages:
		lines.append(str(message))

	_set_lines(lines)


func _set_lines(lines: Array[String]) -> void:
	var full_message := "\n".join(lines)
	_status_label.text = full_message

	for line in lines:
		print("[Glide Web3] %s" % line)


func _set_status(message: String) -> void:
	_status_label.text = message
	print("[Glide Web3] %s" % message)


func _validate_setup() -> Dictionary:
	var messages: Array[String] = []
	var errors := 0
	var warnings := 0

	if _validate_shell_files(messages):
		messages.append("OK: Web shell files found.")
	else:
		errors += 1

	if _validate_output_dir(messages):
		messages.append("OK: Output path is resolvable.")
	else:
		errors += 1

	var export_check := _validate_web_export_capability()
	messages.append(str(export_check.get("message", "")))
	if not export_check.get("ok", false):
		if str(export_check.get("severity", "")) == "warning":
			warnings += 1
		else:
			errors += 1

	var templates_check := _validate_web_export_templates()
	for message in templates_check.get("messages", []):
		messages.append(str(message))
	if not templates_check.get("ok", false):
		if str(templates_check.get("severity", "")) == "warning":
			warnings += 1
		else:
			errors += 1

	var preset_check := _validate_managed_preset()
	messages.append(str(preset_check.get("message", "")))
	if not preset_check.get("ok", false):
		if str(preset_check.get("severity", "")) == "warning":
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
	var output_dir := _get_output_dir()
	if not (output_dir.begins_with("res://") or output_dir.begins_with("user://")):
		messages.append("ERROR: Output path must start with res:// or user://: %s" % output_dir)
		return false

	var absolute_path := ProjectSettings.globalize_path(output_dir)
	if absolute_path.is_empty():
		messages.append("ERROR: Output path could not be resolved: %s" % output_dir)
		return false

	messages.append("INFO: Output path resolves to: %s" % absolute_path)
	messages.append("INFO: Managed shell path: %s" % GlideConstants.WEB_SHELL_HTML)
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

	var editor_paths := EditorPaths.new()
	var templates_dir := editor_paths.get_data_dir().path_join("export_templates").path_join(version_dir)
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


func _validate_managed_preset() -> Dictionary:
	if _has_glide_web_preset():
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


func _has_glide_web_preset() -> bool:
	return _find_managed_preset_section().is_empty() == false


func _get_preset_status_text() -> String:
	if _has_glide_web_preset():
		return "Preset: %s (found)" % GlideConstants.MANAGED_PRESET_NAME
	return "Preset: %s (missing)" % GlideConstants.MANAGED_PRESET_NAME


func _run_web_export() -> Dictionary:
	var project_root := ProjectSettings.globalize_path("res://")
	var output_dir_absolute := ProjectSettings.globalize_path(_get_output_dir())
	var output_file_absolute := output_dir_absolute.path_join(GlideConstants.DEFAULT_WEB_EXPORT_FILE)
	var executable_path := OS.get_executable_path()
	var lines: Array[String] = []

	var prep := _prepare_output_dir(output_dir_absolute)
	for prep_line in prep.get("lines", []):
		lines.append(str(prep_line))
	if not prep.get("ok", false):
		lines.push_front("Export failed.")
		return {"ok": false, "lines": lines}

	var shell_config := _ensure_custom_shell_path()
	for shell_line in shell_config.get("lines", []):
		lines.append(str(shell_line))
	if not shell_config.get("ok", false):
		lines.push_front("Export failed.")
		return {"ok": false, "lines": lines}

	if executable_path.is_empty():
		lines.push_front("Export failed.")
		lines.append("Could not determine Godot editor executable path.")
		return {"ok": false, "lines": lines}

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
		return {"ok": false, "lines": lines}

	var copy_result := _copy_shell_assets(output_dir_absolute)
	for copy_line in copy_result.get("lines", []):
		lines.append(str(copy_line))
	if not copy_result.get("ok", false):
		lines.push_front("Export failed.")
		return {"ok": false, "lines": lines}

	var build_config_result := _apply_build_config(output_file_absolute)
	for config_line in build_config_result.get("lines", []):
		lines.append(str(config_line))
	if not build_config_result.get("ok", false):
		lines.push_front("Export failed.")
		return {"ok": false, "lines": lines}

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
				"Could not create output directory: %s" % output_dir_absolute,
				"DirAccess error code: %d" % error,
			],
		}

	return {
		"ok": true,
		"lines": ["Created output directory: %s" % output_dir_absolute],
	}


func _ensure_custom_shell_path() -> Dictionary:
	if not FileAccess.file_exists(EXPORT_PRESETS_FILE):
		return {
			"ok": false,
			"lines": ["Missing export presets file: %s" % EXPORT_PRESETS_FILE],
		}

	var config := ConfigFile.new()
	var load_error := config.load(EXPORT_PRESETS_FILE)
	if load_error != OK:
		return {
			"ok": false,
			"lines": [
				"Could not load export presets file: %s" % EXPORT_PRESETS_FILE,
				"ConfigFile error code: %d" % load_error,
			],
		}

	var preset_section := _find_managed_preset_section()
	if preset_section.is_empty():
		return {
			"ok": false,
			"lines": ["Preset not found: %s" % GlideConstants.MANAGED_PRESET_NAME],
		}

	var options_section := "%s.options" % preset_section
	config.set_value(options_section, "html/custom_html_shell", GlideConstants.WEB_SHELL_HTML)

	var save_error := config.save(EXPORT_PRESETS_FILE)
	if save_error != OK:
		return {
			"ok": false,
			"lines": [
				"Could not save export presets file: %s" % EXPORT_PRESETS_FILE,
				"ConfigFile error code: %d" % save_error,
			],
		}

	return {
		"ok": true,
		"lines": [
			"Configured managed preset shell path.",
			"Preset: %s" % GlideConstants.MANAGED_PRESET_NAME,
			"Shell HTML: %s" % GlideConstants.WEB_SHELL_HTML,
		],
	}


func _find_managed_preset_section() -> String:
	if not FileAccess.file_exists(EXPORT_PRESETS_FILE):
		return ""

	var config := ConfigFile.new()
	if config.load(EXPORT_PRESETS_FILE) != OK:
		return ""

	for section in config.get_sections():
		if not section.begins_with("preset."):
			continue
		if section.ends_with(".options"):
			continue

		var preset_name := str(config.get_value(section, "name", ""))
		if preset_name == GlideConstants.MANAGED_PRESET_NAME:
			return section

	return ""


func _copy_shell_assets(output_dir_absolute: String) -> Dictionary:
	var source_bridge_absolute := ProjectSettings.globalize_path(GlideConstants.WEB_SHELL_BRIDGE)
	var target_bridge_absolute := output_dir_absolute.path_join(GlideConstants.WEB_SHELL_BRIDGE.get_file())

	if not FileAccess.file_exists(GlideConstants.WEB_SHELL_BRIDGE):
		return {
			"ok": false,
			"lines": ["Missing bridge source file: %s" % GlideConstants.WEB_SHELL_BRIDGE],
		}

	var copy_error := DirAccess.copy_absolute(source_bridge_absolute, target_bridge_absolute)
	if copy_error != OK:
		return {
			"ok": false,
			"lines": [
				"Could not copy bridge.js to output folder.",
				"Source: %s" % source_bridge_absolute,
				"Target: %s" % target_bridge_absolute,
				"DirAccess error code: %d" % copy_error,
			],
		}

	return {
		"ok": true,
		"lines": ["Copied shell asset: %s" % target_bridge_absolute],
	}


func _apply_build_config(output_file_absolute: String) -> Dictionary:
	var app_title := _plugin_config.app_title.strip_edges()
	if app_title.is_empty():
		app_title = "Glide App"

	if not FileAccess.file_exists(output_file_absolute):
		return {
			"ok": false,
			"lines": ["Missing exported HTML for build config step: %s" % output_file_absolute],
		}

	var file := FileAccess.open(output_file_absolute, FileAccess.READ)
	if file == null:
		return {
			"ok": false,
			"lines": ["Could not open exported HTML for reading: %s" % output_file_absolute],
		}

	var html := file.get_as_text()
	file.close()

	var title_start := html.find("<title>")
	var title_end := html.find("</title>")
	if title_start == -1 or title_end == -1 or title_end <= title_start:
		return {
			"ok": false,
			"lines": ["Could not find <title> tag in exported HTML: %s" % output_file_absolute],
		}

	var updated_html := "%s<title>%s</title>%s" % [
		html.substr(0, title_start),
		app_title,
		html.substr(title_end + 8),
	]

	file = FileAccess.open(output_file_absolute, FileAccess.WRITE)
	if file == null:
		return {
			"ok": false,
			"lines": ["Could not open exported HTML for writing: %s" % output_file_absolute],
		}

	file.store_string(updated_html)
	file.close()

	return {
		"ok": true,
		"lines": ["Applied app title to exported HTML: %s" % app_title],
	}


func _load_or_create_plugin_config() -> GlidePluginConfig:
	var config := GlidePluginConfig.new()
	config.output_dir = GlideConstants.DEFAULT_OUTPUT_DIR
	config.preset_name = GlideConstants.MANAGED_PRESET_NAME

	if FileAccess.file_exists(GlideConstants.CONFIG_FILE_PATH):
		var file := ConfigFile.new()
		var load_error := file.load(GlideConstants.CONFIG_FILE_PATH)
		if load_error == OK:
			config.backend_url = str(file.get_value("glide", "backend_url", config.backend_url))
			config.output_dir = str(file.get_value("glide", "output_dir", config.output_dir))
			config.pwa_enabled = bool(file.get_value("glide", "pwa_enabled", config.pwa_enabled))
			config.app_title = str(file.get_value("glide", "app_title", config.app_title))
			config.preset_name = str(file.get_value("glide", "preset_name", config.preset_name))
			return config

	_save_plugin_config(config)
	return config


func _save_plugin_config(config: GlidePluginConfig) -> void:
	var file := ConfigFile.new()
	file.set_value("glide", "backend_url", config.backend_url)
	file.set_value("glide", "output_dir", config.output_dir)
	file.set_value("glide", "pwa_enabled", config.pwa_enabled)
	file.set_value("glide", "app_title", config.app_title)
	file.set_value("glide", "preset_name", config.preset_name)

	var config_dir_absolute := ProjectSettings.globalize_path(GlideConstants.CONFIG_DIR)
	var dir_error := DirAccess.make_dir_recursive_absolute(config_dir_absolute)
	if dir_error != OK:
		push_warning("Could not create Glide config directory %s (error %d)." % [
			GlideConstants.CONFIG_DIR,
			dir_error,
		])
		return

	var save_error := file.save(GlideConstants.CONFIG_FILE_PATH)
	if save_error != OK:
		push_warning("Could not save Glide plugin config to %s (error %d)." % [
			GlideConstants.CONFIG_FILE_PATH,
			save_error,
		])


func _get_output_dir() -> String:
	if _plugin_config and not _plugin_config.output_dir.is_empty():
		return _plugin_config.output_dir
	return GlideConstants.DEFAULT_OUTPUT_DIR
