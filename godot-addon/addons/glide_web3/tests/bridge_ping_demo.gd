extends Control

const JsBridge := preload("res://addons/glide_web3/runtime/js_bridge.gd")

var _js_bridge: GlideJsBridge
var _status_label: Label


func _ready() -> void:
	_js_bridge = GlideJsBridge.new()
	_js_bridge.call_succeeded.connect(_on_js_bridge_call_succeeded)
	_js_bridge.call_failed.connect(_on_js_bridge_call_failed)
	_build_ui()


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var title := Label.new()
	title.text = "Glide Bridge Ping Demo"
	title.add_theme_font_size_override("font_size", 18)
	root.add_child(title)

	var description := Label.new()
	description.text = "Use this scene in a Web export to verify Godot can call window.glideWallet.ping()."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(description)

	var ping_button := Button.new()
	ping_button.text = "Ping Shell"
	ping_button.pressed.connect(_on_ping_shell_pressed)
	root.add_child(ping_button)

	_status_label = Label.new()
	_status_label.text = "Ready."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status_label)


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

	var request_id := _js_bridge.call_async("ping")
	_set_lines([
		"Ping Shell requested.",
		"Request ID: %d" % request_id,
		"Method: ping",
	])


func _on_js_bridge_call_succeeded(request_id: int, method_name: String, result: Variant) -> void:
	_set_lines([
		"JS bridge call succeeded.",
		"Request ID: %d" % request_id,
		"Method: %s" % method_name,
		"Result: %s" % JSON.stringify(result),
	])


func _on_js_bridge_call_failed(request_id: int, method_name: String, error: Dictionary) -> void:
	_set_lines([
		"JS bridge call failed.",
		"Request ID: %d" % request_id,
		"Method: %s" % method_name,
		"Error code: %s" % str(error.get("code", "unknown_error")),
		"Error message: %s" % str(error.get("message", "Unknown error.")),
	])


func _set_lines(lines: Array[String]) -> void:
	_status_label.text = "\n".join(lines)
