(function () {
	if (window.glideWallet) {
		return;
	}

	let loggedIn = false;
	let walletAddress = "";
	const glideEnv = window.__glideEnv || {
		provider: {
			name: "phantom_embedded",
			mode: "mock"
		},
		phantom: {
			clientId: "",
			appId: "",
			redirectOrigin: window.location.origin
		},
		backend: {
			url: ""
		},
		runtime: {
			appTitle: document.title,
			origin: window.location.origin
		}
	};
	window.__glideEnv = glideEnv;

	window.glideWallet = {
		ping: async function () {
			return {
				ok: true,
				source: "shell",
				provider_mode: glideEnv.provider.mode
			};
		},
		getShellEnv: async function () {
			return {
				ok: true,
				env: glideEnv
			};
		},
		login: async function () {
			loggedIn = true;
			walletAddress = "MOCK_ADDRESS_001";
			return {
				ok: true,
				address: walletAddress,
				source: "mock_shell",
				provider: glideEnv.provider.name,
				provider_mode: glideEnv.provider.mode
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
