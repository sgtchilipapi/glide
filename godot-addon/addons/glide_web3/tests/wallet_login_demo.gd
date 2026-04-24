extends Control

const WebWalletService := preload("res://addons/glide_web3/runtime/web_wallet_service.gd")

var _wallet_service: WebWalletService
var _status_label: Label
var _address_label: Label


func _ready() -> void:
	_wallet_service = WebWalletService.new()
	_wallet_service.login_success.connect(_on_login_success)
	_wallet_service.login_failed.connect(_on_login_failed)
	_wallet_service.logout_success.connect(_on_logout_success)
	_wallet_service.tx_success.connect(_on_tx_success)
	_wallet_service.tx_failed.connect(_on_tx_failed)
	_build_ui()
	_refresh_labels("Ready.")


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var title := Label.new()
	title.text = "Glide Wallet Login Demo"
	title.add_theme_font_size_override("font_size", 18)
	root.add_child(title)

	var description := Label.new()
	description.text = "Use this scene in a Web export to verify WalletService can log in through the mock shell."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(description)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	root.add_child(button_row)

	var login_button := Button.new()
	login_button.text = "Login"
	login_button.pressed.connect(_on_login_pressed)
	button_row.add_child(login_button)

	var logout_button := Button.new()
	logout_button.text = "Logout"
	logout_button.pressed.connect(_on_logout_pressed)
	button_row.add_child(logout_button)

	_address_label = Label.new()
	_address_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_address_label)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status_label)


func _on_login_pressed() -> void:
	_refresh_labels("Login requested.")
	_wallet_service.login()


func _on_logout_pressed() -> void:
	_refresh_labels("Logout requested.")
	_wallet_service.logout()


func _on_login_success(address: String) -> void:
	_refresh_labels("Login succeeded.")
	_address_label.text = "Address: %s" % address


func _on_login_failed(error: Dictionary) -> void:
	_refresh_labels("Login failed: %s" % str(error.get("message", "Unknown error.")))


func _on_logout_success() -> void:
	_refresh_labels("Logout succeeded.")


func _on_tx_success(result: Dictionary) -> void:
	_refresh_labels("Transaction succeeded: %s" % JSON.stringify(result))


func _on_tx_failed(error: Dictionary) -> void:
	_refresh_labels("Transaction failed: %s" % str(error.get("message", "Unknown error.")))


func _refresh_labels(status_text: String) -> void:
	if _address_label:
		var address := _wallet_service.get_wallet_address()
		if address.is_empty():
			address = "(none)"
		_address_label.text = "Address: %s" % address

	if _status_label:
		_status_label.text = "Logged in: %s\nStatus: %s" % [
			str(_wallet_service.is_logged_in()),
			status_text,
		]
