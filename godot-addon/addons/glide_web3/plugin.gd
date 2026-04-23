@tool
extends EditorPlugin

const PLUGIN_NAME := "Glide Web3"

func _enter_tree() -> void:
	print("%s plugin enabled." % PLUGIN_NAME)


func _exit_tree() -> void:
	print("%s plugin disabled." % PLUGIN_NAME)
