@tool
extends PanelContainer

const GlideConstants := preload("res://addons/glide_web3/config/glide_constants.gd")
const ExportSetupValidator := preload("res://addons/glide_web3/editor/export_setup_validator.gd")
const ExportRunner := preload("res://addons/glide_web3/editor/export_runner.gd")
const PresetDiscovery := preload("res://addons/glide_web3/editor/preset_discovery.gd")

const TITLE := GlideConstants.PLUGIN_NAME
const DESCRIPTION := "Managed Web export and embedded wallet toolkit for Godot."

var _status_label: Label
var _preset_status_label: Label
var _export_setup_validator: RefCounted
var _export_runner: RefCounted
var _preset_discovery: RefCounted

func _ready() -> void:
	_export_setup_validator = RefCounted.new()
	_export_setup_validator.set_script(ExportSetupValidator)
	_export_runner = RefCounted.new()
	_export_runner.set_script(ExportRunner)
	_preset_discovery = RefCounted.new()
	_preset_discovery.set_script(PresetDiscovery)
	_build_ui()


func _build_ui() -> void:
	custom_minimum_size = Vector2(420, 180)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	add_child(content)

	var title_label := Label.new()
	title_label.text = TITLE
	title_label.add_theme_font_size_override("font_size", 18)
	content.add_child(title_label)

	var description_label := Label.new()
	description_label.text = DESCRIPTION
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(description_label)

	_preset_status_label = Label.new()
	_preset_status_label.text = _preset_discovery.get_preset_status_text()
	content.add_child(_preset_status_label)

	var output_dir_label := Label.new()
	output_dir_label.text = "Output: %s" % GlideConstants.DEFAULT_OUTPUT_DIR
	output_dir_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(output_dir_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	content.add_child(button_row)

	var validate_button := Button.new()
	validate_button.text = "Validate Setup"
	validate_button.pressed.connect(_on_validate_setup_pressed)
	button_row.add_child(validate_button)

	var build_button := Button.new()
	build_button.text = "Build Web"
	build_button.pressed.connect(_on_build_web_pressed)
	button_row.add_child(build_button)

	_status_label = Label.new()
	_status_label.text = "Ready."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_status_label)


func _on_validate_setup_pressed() -> void:
	var result := _export_setup_validator.validate()
	_refresh_preset_status()
	_set_validation_status(result)


func _on_build_web_pressed() -> void:
	var result := _export_setup_validator.validate()
	_refresh_preset_status()

	if result.get("errors", 0) > 0:
		_set_validation_status(result)
		return

	if not _preset_discovery.has_glide_web_preset():
		_set_status(
			"Build blocked. Missing managed preset %s. Create a Web export preset with that exact name in Project > Export."
			% GlideConstants.MANAGED_PRESET_NAME
		)
		return

	var export_result := _export_runner.run_web_export()
	_set_lines(export_result.get("lines", ["Export finished."]))


func _refresh_preset_status() -> void:
	if _preset_status_label:
		_preset_status_label.text = _preset_discovery.get_preset_status_text()


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
