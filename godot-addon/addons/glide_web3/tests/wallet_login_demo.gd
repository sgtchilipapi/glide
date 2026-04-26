extends Control

const WebWalletService := preload("res://addons/glide_web3/runtime/web_wallet_service.gd")

var _wallet_service: WebWalletService
var _status_label: Label
var _address_label: Label
var _rpc_url_edit: LineEdit
var _transaction_base64_edit: TextEdit


func _ready() -> void:
	_wallet_service = WebWalletService.new()
	_wallet_service.login_success.connect(_on_login_success)
	_wallet_service.login_failed.connect(_on_login_failed)
	_wallet_service.logout_success.connect(_on_logout_success)
	_wallet_service.tx_success.connect(_on_tx_success)
	_wallet_service.tx_failed.connect(_on_tx_failed)
	_build_ui()
	_refresh_labels("Ready.")
	_wallet_service.refresh_session()
	_refresh_labels("Startup session refresh requested.")


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
	description.text = "Use this scene in a Web export to verify WalletService login through Glide's active shell auth path."
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

	var refresh_button := Button.new()
	refresh_button.text = "Refresh Session"
	refresh_button.pressed.connect(_on_refresh_session_pressed)
	button_row.add_child(refresh_button)

	var send_tx_button := Button.new()
	send_tx_button.text = "Send Transaction"
	send_tx_button.pressed.connect(_on_send_transaction_pressed)
	button_row.add_child(send_tx_button)

	var rpc_label := Label.new()
	rpc_label.text = "Solana RPC URL"
	root.add_child(rpc_label)

	_rpc_url_edit = LineEdit.new()
	_rpc_url_edit.placeholder_text = "https://api.devnet.solana.com"
	_rpc_url_edit.text = "https://api.devnet.solana.com"
	root.add_child(_rpc_url_edit)

	var tx_label := Label.new()
	tx_label.text = "Serialized transaction (base64)"
	root.add_child(tx_label)

	_transaction_base64_edit = TextEdit.new()
	_transaction_base64_edit.custom_minimum_size = Vector2(0, 120)
	_transaction_base64_edit.placeholder_text = "Paste a base64-encoded Solana transaction here."
	root.add_child(_transaction_base64_edit)

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


func _on_refresh_session_pressed() -> void:
	_refresh_labels("Session refresh requested.")
	_wallet_service.refresh_session()


func _on_send_transaction_pressed() -> void:
	var rpc_url := _rpc_url_edit.text.strip_edges()
	var transaction_base64 := _transaction_base64_edit.text.strip_edges()
	_refresh_labels("Transaction requested.")
	_wallet_service.sign_and_send_transaction({
		"kind": "solana_sign_and_send",
		"chain": "solana",
		"request_id": "demo_tx_%d" % Time.get_ticks_msec(),
		"rpc_url": rpc_url,
		"serialized_tx_base64": transaction_base64,
	})


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
