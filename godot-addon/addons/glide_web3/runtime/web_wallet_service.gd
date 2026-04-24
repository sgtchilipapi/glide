extends WalletService
class_name WebWalletService

const GlideJsBridge := preload("res://addons/glide_web3/runtime/js_bridge.gd")

var _js_bridge: GlideJsBridge
var _pending_requests: Dictionary = {}
var _logged_in := false
var _wallet_address := ""


func _init() -> void:
	_js_bridge = GlideJsBridge.new()
	_js_bridge.call_succeeded.connect(_on_js_call_succeeded)
	_js_bridge.call_failed.connect(_on_js_call_failed)


func login() -> void:
	_request_bridge_call("login", {})


func logout() -> void:
	_request_bridge_call("logout", {})


func is_logged_in() -> bool:
	return _logged_in


func get_wallet_address() -> String:
	return _wallet_address


func sign_and_send_transaction(payload: Dictionary) -> void:
	_request_bridge_call("signAndSendTransaction", payload)


func _request_bridge_call(method_name: String, payload: Dictionary) -> void:
	var bridge_status := GlideJsBridge.get_bridge_status()
	if not bridge_status.get("ok", false):
		_emit_method_error(method_name, {
			"code": str(bridge_status.get("code", "bridge_unavailable")),
			"message": str(bridge_status.get("message", "Bridge unavailable.")),
		})
		return

	var request_id := _js_bridge.call_async(method_name, payload)
	_pending_requests[request_id] = method_name


func _on_js_call_succeeded(request_id: int, method_name: String, result: Variant) -> void:
	_pending_requests.erase(request_id)

	match method_name:
		"login":
			_handle_login_success(result)
		"logout":
			_logged_in = false
			_wallet_address = ""
			logout_success.emit()
		"signAndSendTransaction":
			var tx_result := _normalize_result_dictionary(result)
			tx_success.emit(tx_result)


func _on_js_call_failed(request_id: int, method_name: String, error: Dictionary) -> void:
	_pending_requests.erase(request_id)
	_emit_method_error(method_name, error)


func _handle_login_success(result: Variant) -> void:
	var payload := _normalize_result_dictionary(result)
	if not payload.get("ok", false):
		login_failed.emit({
			"code": "login_failed",
			"message": "Login did not return ok=true.",
		})
		return

	_logged_in = true
	_wallet_address = str(payload.get("address", ""))
	login_success.emit(_wallet_address)


func _emit_method_error(method_name: String, error: Dictionary) -> void:
	match method_name:
		"login":
			login_failed.emit(error)
		"signAndSendTransaction":
			tx_failed.emit(error)


func _normalize_result_dictionary(result: Variant) -> Dictionary:
	if result is Dictionary:
		return result

	return {
		"ok": false,
		"raw_result": result,
	}
