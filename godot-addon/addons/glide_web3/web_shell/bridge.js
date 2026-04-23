(function () {
	if (window.glideWallet) {
		return;
	}

	window.glideWallet = {
		ping: async function () {
			return {
				ok: true,
				source: "glide-shell"
			};
		}
	};

	console.log("[Glide Web3] bridge.js loaded");
}());
