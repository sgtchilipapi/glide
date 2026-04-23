@tool
extends PanelContainer

const TITLE := "Glide Web3"
const DESCRIPTION := "Managed Web export and embedded wallet toolkit for Godot."

var _status_label: Label

func _ready() -> void:
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
	_set_status("Validate Setup will be implemented in the next work order.")


func _on_build_web_pressed() -> void:
	_set_status("Build Web will be wired after setup validation and preset discovery.")


func _set_status(message: String) -> void:
	_status_label.text = message
	print("[Glide Web3] %s" % message)
