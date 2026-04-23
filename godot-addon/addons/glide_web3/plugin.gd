@tool
extends EditorPlugin

const PLUGIN_NAME := "Glide Web3"
const EditorPanel := preload("res://addons/glide_web3/ui/glide_web3_panel.gd")

var _panel: Control
var _bottom_panel_button: Button

func _enter_tree() -> void:
	_panel = EditorPanel.new()
	_panel.name = PLUGIN_NAME
	_bottom_panel_button = add_control_to_bottom_panel(_panel, PLUGIN_NAME)
	make_bottom_panel_item_visible(_panel)
	print("%s plugin enabled." % PLUGIN_NAME)


func _exit_tree() -> void:
	if _panel:
		remove_control_from_bottom_panel(_panel)
		_panel.queue_free()
		_panel = null
		_bottom_panel_button = null
	print("%s plugin disabled." % PLUGIN_NAME)
