extends RefCounted
class_name GlideJsBridge

signal call_succeeded(request_id: int, method_name: String, result: Variant)
signal call_failed(request_id: int, method_name: String, error: Dictionary)

const GLIDE_BRIDGE_OBJECT := "glideWallet"

var _next_request_id := 1
var _success_callbacks: Dictionary = {}
var _error_callbacks: Dictionary = {}


static func is_supported() -> bool:
	return OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge")


static func is_bridge_ready() -> bool:
	if not is_supported():
		return false

	return bool(JavaScriptBridge.eval(
		"typeof window !== 'undefined' && window.__glideBridgeReady === true",
		true
	))


static func has_bridge_method(method_name: String) -> bool:
	if not is_supported():
		return false

	var js_method_name := JSON.stringify(method_name)
	return bool(JavaScriptBridge.eval(
		"typeof window !== 'undefined' && !!window.%s && typeof window.%s[%s] === 'function'" % [
			GLIDE_BRIDGE_OBJECT,
			GLIDE_BRIDGE_OBJECT,
			js_method_name,
		],
		true
	))


static func get_bridge_status() -> Dictionary:
	if not is_supported():
		return {
			"ok": false,
			"code": "unsupported_platform",
			"message": "JavaScriptBridge is only available in Web exports.",
		}

	if not is_bridge_ready():
		return {
			"ok": false,
			"code": "bridge_unavailable",
			"message": "window.__glideBridgeReady is false or missing.",
		}

	return {
		"ok": true,
		"code": "ready",
		"message": "Bridge is ready.",
	}


func call_async(method_name: String, payload: Variant = {}) -> int:
	var request_id := _reserve_request_id()

	if not is_supported():
		_emit_call_failed(request_id, method_name, {
			"code": "unsupported_platform",
			"message": "JavaScriptBridge is only available in Web exports.",
		})
		return request_id

	if not is_bridge_ready():
		_emit_call_failed(request_id, method_name, {
			"code": "bridge_unavailable",
			"message": "window.__glideBridgeReady is false or missing.",
		})
		return request_id

	if not has_bridge_method(method_name):
		_emit_call_failed(request_id, method_name, {
			"code": "missing_method",
			"message": "Bridge method not found: %s" % method_name,
		})
		return request_id

	var window := JavaScriptBridge.get_interface("window")
	var success_name := "__glideGodotSuccess_%d" % request_id
	var error_name := "__glideGodotError_%d" % request_id

	var success_callback := JavaScriptBridge.create_callback(
		Callable(self, "_on_js_call_succeeded").bind(request_id, method_name, success_name, error_name)
	)
	var error_callback := JavaScriptBridge.create_callback(
		Callable(self, "_on_js_call_failed").bind(request_id, method_name, success_name, error_name)
	)

	_success_callbacks[request_id] = success_callback
	_error_callbacks[request_id] = error_callback
	window[success_name] = success_callback
	window[error_name] = error_callback

	var js_method_name := JSON.stringify(method_name)
	var js_payload := JSON.stringify(payload)
	var js_success_name := JSON.stringify(success_name)
	var js_error_name := JSON.stringify(error_name)

	JavaScriptBridge.eval(
		"""
		(function () {
			const successName = %s;
			const errorName = %s;
			const payload = %s;
			const method = window.%s[%s];

			Promise.resolve(method(payload))
				.then(function (result) {
					window[successName](result);
				})
				.catch(function (error) {
					const normalizedError = {
						code: "javascript_error",
						message: String(error && error.message ? error.message : error)
					};
					window[errorName](normalizedError);
				});
		}());
		""" % [
			js_success_name,
			js_error_name,
			js_payload,
			GLIDE_BRIDGE_OBJECT,
			js_method_name,
		],
		true
	)

	return request_id


func _on_js_call_succeeded(args: Array, request_id: int, method_name: String, success_name: String, error_name: String) -> void:
	var result: Variant = null
	if not args.is_empty():
		result = args[0]

	_cleanup_request_callbacks(request_id, success_name, error_name)
	call_succeeded.emit(request_id, method_name, result)


func _on_js_call_failed(args: Array, request_id: int, method_name: String, success_name: String, error_name: String) -> void:
	var error := {
		"code": "unknown_error",
		"message": "Unknown JavaScript bridge failure.",
	}
	if not args.is_empty() and args[0] is Dictionary:
		error = args[0]
	elif not args.is_empty():
		error["message"] = str(args[0])

	_cleanup_request_callbacks(request_id, success_name, error_name)
	call_failed.emit(request_id, method_name, error)


func _cleanup_request_callbacks(request_id: int, success_name: String, error_name: String) -> void:
	_success_callbacks.erase(request_id)
	_error_callbacks.erase(request_id)

	if not is_supported():
		return

	var window := JavaScriptBridge.get_interface("window")
	window[success_name] = null
	window[error_name] = null


func _emit_call_failed(request_id: int, method_name: String, error: Dictionary) -> void:
	call_failed.emit(request_id, method_name, error)


func _reserve_request_id() -> int:
	var request_id := _next_request_id
	_next_request_id += 1
	return request_id
