(function () {
	if (window.glideWallet) {
		return;
	}

	let loggedIn = false;
	let walletAddress = "";

	window.glideWallet = {
		ping: async function () {
			return {
				ok: true,
				source: "shell"
			};
		},
		login: async function () {
			loggedIn = true;
			walletAddress = "MOCK_ADDRESS_001";
			return {
				ok: true,
				address: walletAddress,
				source: "mock_shell"
			};
		},
		logout: async function () {
			loggedIn = false;
			walletAddress = "";
			return {
				ok: true,
				source: "mock_shell"
			};
		},
		isLoggedIn: async function () {
			return {
				ok: true,
				logged_in: loggedIn
			};
		},
		getWalletAddress: async function () {
			return {
				ok: true,
				address: walletAddress
			};
		},
		signAndSendTransaction: async function (payload) {
			return {
				ok: true,
				signature: "MOCK_TX_001",
				request_payload: payload || {}
			};
		}
	};

	console.log("[Glide Web3] bridge.js loaded");
}());
