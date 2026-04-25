@tool
extends Resource
class_name GlidePluginConfig

@export var backend_url := ""
@export var output_dir := "res://build/web/"
@export var pwa_enabled := false
@export var app_title := "Glide App"
@export var phantom_app_id := ""
@export var phantom_redirect_origin := ""
@export var preset_name := "GlideWeb"
