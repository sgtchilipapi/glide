import type Privy from "@privy-io/js-sdk-core";
import {
  beginPrivyLogin,
  canUsePrivy,
  completePrivyOAuthCallback,
  createGlidePrivyClient,
  initializePrivy,
  logoutPrivy,
  restorePrivySession,
} from "./privy";
import type { GlideShellEnv, GlideWalletBridge } from "./types";

export function createWalletBridge(env: GlideShellEnv): GlideWalletBridge {
  let client: Privy | null = null;
  let initPromise: Promise<void> | null = null;
  let loggedIn = false;
  let walletAddress = "";
  let userId = "";
  let loginMethod = "";

  function getClient(): Privy {
    if (client === null) {
      client = createGlidePrivyClient(env);
    }
    return client;
  }

  async function ensureInitialized(): Promise<void> {
    if (env.provider.mode === "mock") {
      return;
    }

    if (initPromise) {
      await initPromise;
      return;
    }

    initPromise = (async () => {
      if (!canUsePrivy(env)) {
        return;
      }

      const activeClient = getClient();
      await initializePrivy(activeClient);

      const callbackSession = await completePrivyOAuthCallback(activeClient, env);
      if (callbackSession) {
        loggedIn = callbackSession.loggedIn;
        walletAddress = callbackSession.walletAddress;
        userId = callbackSession.userId;
        loginMethod = callbackSession.loginMethod;
        return;
      }

      const restoredSession = await restorePrivySession(activeClient);
      loggedIn = restoredSession.loggedIn;
      walletAddress = restoredSession.walletAddress;
      userId = restoredSession.userId;
      loginMethod = restoredSession.loginMethod;
    })();

    await initPromise;
  }

  return {
    async ping() {
      await ensureInitialized();
      return {
        ok: true,
        source: "shell",
        provider_mode: env.provider.mode,
        logged_in: loggedIn,
      };
    },

    async getShellEnv() {
      await ensureInitialized();
      return {
        ok: true,
        env,
      };
    },

    async getLoginState() {
      await ensureInitialized();
      return {
        ok: true,
        logged_in: loggedIn,
        address: walletAddress,
        user_id: userId,
        login_method: loginMethod,
      };
    },

    async login() {
      await ensureInitialized();

      if (loggedIn) {
        return {
          ok: true,
          address: walletAddress,
          source: "privy_session",
          provider: env.provider.name,
          provider_mode: env.provider.mode,
        };
      }

      if (env.provider.mode === "mock") {
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

      if (!canUsePrivy(env)) {
        throw {
          code: "misconfigured",
          message: "Privy mode requires valid Privy appId and clientId.",
        };
      }

      try {
        const result = await beginPrivyLogin(getClient(), env);
        return {
          ok: true,
          redirect_started: true,
          redirect_url: result.redirectUrl,
          source: "privy_oauth_redirect",
          provider_mode: env.provider.mode,
          oauth_provider: env.provider.oauthProvider,
        };
      } catch (error) {
        throw normalizePrivyError(error);
      }
    },

    async logout() {
      await ensureInitialized();

      if (client) {
        await logoutPrivy(client);
      }
      loggedIn = false;
      walletAddress = "";
      userId = "";
      loginMethod = "";
      return {
        ok: true,
        source: env.provider.mode,
      };
    },

    async isLoggedIn() {
      await ensureInitialized();
      return {
        ok: true,
        logged_in: loggedIn,
      };
    },

    async getWalletAddress() {
      await ensureInitialized();
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

function normalizePrivyError(error: unknown): Record<string, unknown> {
  const privyCode =
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    typeof (error as { code?: unknown }).code === "string"
      ? String((error as { code: string }).code)
      : "";

  const message =
    typeof error === "object" &&
    error !== null &&
    "error" in error &&
    typeof (error as { error?: unknown }).error === "string"
      ? String((error as { error: string }).error)
      : error instanceof Error
        ? error.message
        : typeof error === "string"
          ? error
          : JSON.stringify(error);

  if (
    privyCode === "oauth_user_denied" ||
    privyCode === "failed_to_complete_login_with_oauth_was_cancelled_by_user"
  ) {
    return {
      code: "cancelled",
      message,
    };
  }

  if (
    privyCode === "allowlist_rejected" ||
    privyCode === "invalid_origin" ||
    privyCode === "configuration_error" ||
    privyCode === "pkce_state_code_mismatch"
  ) {
    return {
      code: "misconfigured",
      message,
    };
  }

  const normalizedMessage = message.toLowerCase();
  if (
    normalizedMessage.includes("origin") ||
    normalizedMessage.includes("redirect") ||
    normalizedMessage.includes("client") ||
    normalizedMessage.includes("appid") ||
    normalizedMessage.includes("app id")
  ) {
    return {
      code: "misconfigured",
      message,
    };
  }

  if (
    normalizedMessage.includes("cancel") ||
    normalizedMessage.includes("denied") ||
    normalizedMessage.includes("closed")
  ) {
    return {
      code: "cancelled",
      message,
    };
  }

  if (
    normalizedMessage.includes("network") ||
    normalizedMessage.includes("timeout") ||
    normalizedMessage.includes("unavailable")
  ) {
    return {
      code: "unavailable",
      message,
    };
  }

  return {
    code: privyCode || "unknown",
    message,
  };
}
