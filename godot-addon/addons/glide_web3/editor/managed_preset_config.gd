@tool
extends RefCounted

const GlideConstants := preload("res://addons/glide_web3/config/glide_constants.gd")
const EXPORT_PRESETS_FILE := "res://export_presets.cfg"

func ensure_custom_shell_path() -> Dictionary:
	if not FileAccess.file_exists(EXPORT_PRESETS_FILE):
		return {
			"ok": false,
			"lines": [
				"Failed to configure managed preset.",
				"Missing export presets file: %s" % EXPORT_PRESETS_FILE,
			],
		}

	var config := ConfigFile.new()
	var load_error := config.load(EXPORT_PRESETS_FILE)
	if load_error != OK:
		return {
			"ok": false,
			"lines": [
				"Failed to configure managed preset.",
				"Could not load export presets file: %s" % EXPORT_PRESETS_FILE,
				"ConfigFile error code: %d" % load_error,
			],
		}

	var preset_section := _find_managed_preset_section(config)
	if preset_section.is_empty():
		return {
			"ok": false,
			"lines": [
				"Failed to configure managed preset.",
				"Preset not found: %s" % GlideConstants.MANAGED_PRESET_NAME,
			],
		}

	var options_section := "%s.options" % preset_section
	config.set_value(options_section, "html/custom_html_shell", GlideConstants.WEB_SHELL_HTML)

	var save_error := config.save(EXPORT_PRESETS_FILE)
	if save_error != OK:
		return {
			"ok": false,
			"lines": [
				"Failed to configure managed preset.",
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


func _find_managed_preset_section(config: ConfigFile) -> String:
	for section in config.get_sections():
		if not section.begins_with("preset."):
			continue
		if section.ends_with(".options"):
			continue

		var preset_name := str(config.get_value(section, "name", ""))
		if preset_name == GlideConstants.MANAGED_PRESET_NAME:
			return section

	return ""
