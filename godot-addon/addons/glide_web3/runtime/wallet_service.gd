extends RefCounted
class_name WalletService

signal login_success(address: String)
signal login_failed(error: Dictionary)
signal logout_success()
signal tx_success(result: Dictionary)
signal tx_failed(error: Dictionary)


func login() -> void:
	push_warning("WalletService.login() is not implemented.")


func logout() -> void:
	push_warning("WalletService.logout() is not implemented.")


func is_logged_in() -> bool:
	return false


func get_wallet_address() -> String:
	return ""


func sign_and_send_transaction(payload: Dictionary) -> void:
	push_warning("WalletService.sign_and_send_transaction() is not implemented.")
