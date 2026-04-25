import { createWalletBridge } from "./walletBridge";
import type { GlideShellEnv, GlideWalletBridge } from "./types";

declare global {
  interface Window {
    __glideEnv?: GlideShellEnv;
    glideWallet?: GlideWalletBridge;
  }
}

function getDefaultEnv(): GlideShellEnv {
  return {
    provider: {
      name: "phantom_embedded",
      mode: "mock",
    },
    phantom: {
      clientId: "",
      appId: "",
      originUrl: window.location.origin,
      callbackUrl: `${window.location.origin}/auth/callback`,
    },
    backend: {
      url: "",
    },
    runtime: {
      appTitle: document.title,
      origin: window.location.origin,
    },
  };
}

const env = window.__glideEnv ?? getDefaultEnv();
window.__glideEnv = env;
window.glideWallet = createWalletBridge(env);

console.log("[Glide Web3] bundled bridge loaded", {
  provider: env.provider.name,
  mode: env.provider.mode,
});
