import type { BrowserSDK } from "@phantom/browser-sdk";
import { canUseEmbeddedPhantom, connectWithPhantom, createGlidePhantomSdk, getDefaultLoginProvider } from "./phantom";
import type { GlideShellEnv, GlideWalletBridge } from "./types";

export function createWalletBridge(env: GlideShellEnv): GlideWalletBridge {
  let sdk: BrowserSDK | null = null;
  let loggedIn = false;
  let walletAddress = "";

  function getSdk(): BrowserSDK {
    if (sdk === null) {
      sdk = createGlidePhantomSdk(env);
    }
    return sdk;
  }

  return {
    async ping() {
      return {
        ok: true,
        source: "shell",
        provider_mode: env.provider.mode,
      };
    },

    async getShellEnv() {
      return {
        ok: true,
        env,
      };
    },

    async login() {
      if (!canUseEmbeddedPhantom(env)) {
        loggedIn = true;
        walletAddress = "MOCK_ADDRESS_001";
        return {
          ok: true,
          address: walletAddress,
          source: "mock_shell",
          provider: env.provider.name,
          provider_mode: env.provider.mode,
        };
      }

      const result = await connectWithPhantom(getSdk(), getDefaultLoginProvider());
      loggedIn = true;
      walletAddress = String(result.address ?? "");
      return {
        ...result,
        source: "phantom_browser_sdk",
        provider_mode: env.provider.mode,
      };
    },

    async logout() {
      if (sdk) {
        await sdk.disconnect();
      }
      loggedIn = false;
      walletAddress = "";
      return {
        ok: true,
        source: env.provider.mode,
      };
    },

    async isLoggedIn() {
      return {
        ok: true,
        logged_in: loggedIn,
      };
    },

    async getWalletAddress() {
      return {
        ok: true,
        address: walletAddress,
      };
    },

    async signAndSendTransaction(payload: Record<string, unknown>) {
      return {
        ok: true,
        signature: "MOCK_TX_001",
        request_payload: payload,
      };
    },
  };
}
