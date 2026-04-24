@tool
extends RefCounted

const PLUGIN_NAME := "Glide Web3"
const MANAGED_PRESET_NAME := "GlideWeb"
const DEFAULT_OUTPUT_DIR := "res://build/web/"
const DEFAULT_WEB_EXPORT_FILE := "index.html"
const CONFIG_DIR := "res://glide"
const CONFIG_FILE_PATH := CONFIG_DIR + "/glide_plugin_config.cfg"
const WEB_SHELL_DIR := "res://addons/glide_web3/web_shell"
const WEB_SHELL_HTML := WEB_SHELL_DIR + "/index.html"
const WEB_SHELL_BRIDGE := WEB_SHELL_DIR + "/bridge.js"
