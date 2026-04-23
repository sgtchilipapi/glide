@tool
extends RefCounted

const GlideConstants := preload("res://addons/glide_web3/config/glide_constants.gd")
const EXPORT_PRESETS_FILE := "res://export_presets.cfg"

func has_glide_web_preset() -> bool:
	return find_managed_preset_name() != ""


func find_managed_preset_name() -> String:
	if not FileAccess.file_exists(EXPORT_PRESETS_FILE):
		return ""

	var file := FileAccess.open(EXPORT_PRESETS_FILE, FileAccess.READ)
	if file == null:
		return ""

	var current_section := ""

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty():
			continue

		if line.begins_with("[") and line.ends_with("]"):
			current_section = line.substr(1, line.length() - 2)
			continue

		if not current_section.begins_with("preset."):
			continue

		if not line.begins_with("name="):
			continue

		var value := line.trim_prefix("name=").strip_edges()
		value = value.trim_prefix("\"").trim_suffix("\"")
		if value == GlideConstants.MANAGED_PRESET_NAME:
			return value

	return ""


func get_preset_status_text() -> String:
	if has_glide_web_preset():
		return "Preset: %s (found)" % GlideConstants.MANAGED_PRESET_NAME
	return "Preset: %s (missing)" % GlideConstants.MANAGED_PRESET_NAME
