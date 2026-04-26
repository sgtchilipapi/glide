import type Privy from "@privy-io/js-sdk-core";
import {
  completeSponsoredAction,
  isBackendSponsoredActionPayload,
  prepareSponsoredAction,
} from "./backend";
import {
  beginPrivyLogin,
  canUsePrivy,
  completePrivyOAuthCallback,
  createGlidePrivyClient,
  initializePrivy,
  logoutPrivy,
  restorePrivySession,
  signAndSendPrivySolanaTransaction,
} from "./privy";
import type { GlideShellEnv, GlideWalletBridge } from "./types";

export function createWalletBridge(env: GlideShellEnv): GlideWalletBridge {
  let client: Privy | null = null;
  let initPromise: Promise<void> | null = null;
  let loggedIn = false;
  let walletAddress = "";
  let userId = "";
  let loginMethod = "";

  function logBridge(event: string, payload?: Record<string, unknown>): void {
    const entry = {
      at: new Date().toISOString(),
      event,
      ...(payload ?? {}),
    };
    console.log("[Glide Bridge]", entry);
    const debugWindow = window as Window & {
      __glideDebug?: {
        events: Array<Record<string, unknown>>;
        push?: (entry: Record<string, unknown>) => void;
      };
    };
    if (!debugWindow.__glideDebug) {
      debugWindow.__glideDebug = { events: [] };
    }
    if (typeof debugWindow.__glideDebug.push === "function") {
      debugWindow.__glideDebug.push(entry);
      return;
    }
    debugWindow.__glideDebug.events.push(entry);
  }

  function getClient(): Privy {
    if (client === null) {
      logBridge("create_client");
      client = createGlidePrivyClient(env);
    }
    return client;
  }

  async function ensureInitialized(): Promise<void> {
    logBridge("ensure_initialized_start", {
      providerMode: env.provider.mode,
      alreadyLoggedIn: loggedIn,
      hasInitPromise: initPromise !== null,
    });
    if (env.provider.mode === "mock") {
      logBridge("ensure_initialized_mock_mode");
      return;
    }

    if (initPromise) {
      logBridge("ensure_initialized_wait_existing");
      await initPromise;
      return;
    }

    initPromise = (async () => {
      if (!canUsePrivy(env)) {
        logBridge("ensure_initialized_misconfigured", {
          hasAppId: env.privy.appId.trim().length > 0,
          hasClientId: env.privy.clientId.trim().length > 0,
        });
        return;
      }

      const activeClient = getClient();
      await initializePrivy(activeClient);

      let callbackSession = null;
      try {
        callbackSession = await completePrivyOAuthCallback(activeClient, env);
      } catch (error) {
        logBridge("callback_failed", normalizePrivyError(error));
        throw error;
      }
      if (callbackSession) {
        loggedIn = callbackSession.loggedIn;
        walletAddress = callbackSession.walletAddress;
        userId = callbackSession.userId;
        loginMethod = callbackSession.loginMethod;
        logBridge("callback_session_applied", {
          loggedIn,
          walletAddress,
          userId,
          loginMethod,
        });
        return;
      }

      const restoredSession = await restorePrivySession(activeClient);
      loggedIn = restoredSession.loggedIn;
      walletAddress = restoredSession.walletAddress;
      userId = restoredSession.userId;
      loginMethod = restoredSession.loginMethod;
      logBridge("restored_session_applied", {
        loggedIn,
        walletAddress,
        userId,
        loginMethod,
      });
    })();

    await initPromise;
    logBridge("ensure_initialized_done", {
      loggedIn,
      walletAddress,
      userId,
      loginMethod,
    });
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
      logBridge("login_requested", {
        providerMode: env.provider.mode,
        alreadyLoggedIn: loggedIn,
      });
      await ensureInitialized();

      if (loggedIn) {
        logBridge("login_return_existing_session", {
          walletAddress,
        });
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
        logBridge("login_mock_success", {
          walletAddress,
        });
        return {
          ok: true,
          address: walletAddress,
          source: "mock_shell",
          provider: env.provider.name,
          provider_mode: env.provider.mode,
        };
      }

      if (!canUsePrivy(env)) {
        logBridge("login_misconfigured", {
          hasAppId: env.privy.appId.trim().length > 0,
          hasClientId: env.privy.clientId.trim().length > 0,
        });
        throw {
          code: "misconfigured",
          message: "Privy mode requires valid Privy appId and clientId.",
        };
      }

      try {
        const result = await beginPrivyLogin(getClient(), env);
        logBridge("login_redirect_started", {
          redirectUrl: result.redirectUrl,
          oauthProvider: env.provider.oauthProvider,
        });
        return {
          ok: true,
          redirect_started: true,
          redirect_url: result.redirectUrl,
          source: "privy_oauth_redirect",
          provider_mode: env.provider.mode,
          oauth_provider: env.provider.oauthProvider,
        };
      } catch (error) {
        const normalizedError = normalizePrivyError(error);
        logBridge("login_failed", normalizedError);
        throw normalizedError;
      }
    },

    async logout() {
      logBridge("logout_requested", {
        hadClient: client !== null,
      });
      await ensureInitialized();

      if (client) {
        await logoutPrivy(client);
      }
      loggedIn = false;
      walletAddress = "";
      userId = "";
      loginMethod = "";
      logBridge("logout_done");
      return {
        ok: true,
        source: env.provider.mode,
      };
    },

    async isLoggedIn() {
      await ensureInitialized();
      logBridge("is_logged_in", {
        loggedIn,
      });
      return {
        ok: true,
        logged_in: loggedIn,
      };
    },

    async getWalletAddress() {
      await ensureInitialized();
      logBridge("get_wallet_address", {
        walletAddress,
      });
      return {
        ok: true,
        address: walletAddress,
      };
    },

    async signAndSendTransaction(payload: Record<string, unknown>) {
      logBridge("sign_and_send_transaction_requested", {
        providerMode: env.provider.mode,
        payloadKeys: Object.keys(payload),
      });
      await ensureInitialized();

      if (env.provider.mode === "mock") {
        logBridge("sign_and_send_transaction_mock", {
          payload,
        });
        return {
          ok: true,
          signature: "MOCK_TX_001",
          request_payload: payload,
          source: "mock_shell",
          provider_mode: env.provider.mode,
        };
      }

      if (!loggedIn) {
        throw {
          code: "not_logged_in",
          message: "User must be logged in before sending a transaction.",
        };
      }

      try {
        if (isBackendSponsoredActionPayload(payload)) {
          logBridge("backend_sponsored_prepare_start", {
            requestId: payload.request_id,
            action: payload.action,
          });
          const prepared = await prepareSponsoredAction(env, payload);
          logBridge("backend_sponsored_prepare_done", {
            requestId: prepared.request_id,
            transactionKind: prepared.transaction?.kind,
          });
          const signed = await signAndSendPrivySolanaTransaction(
            getClient(),
            prepared.transaction,
          );
          const completed = await completeSponsoredAction(env, {
            request_id: prepared.request_id,
            wallet_address: signed.walletAddress,
            signature: signed.signature,
            chain: "solana",
          });
          logBridge("backend_sponsored_complete_done", {
            requestId: completed.request_id,
            status: completed.status,
            signature: signed.signature,
          });
          return {
            ok: true,
            request_id: prepared.request_id,
            signature: signed.signature,
            address: signed.walletAddress,
            provider_mode: env.provider.mode,
            source: "backend_sponsored_action",
            backend_status: completed.status,
          };
        }

        const result = await signAndSendPrivySolanaTransaction(getClient(), payload);
        logBridge("sign_and_send_transaction_done", {
          signature: result.signature,
          walletAddress: result.walletAddress,
        });
        return {
          ok: true,
          signature: result.signature,
          address: result.walletAddress,
          provider_mode: env.provider.mode,
          source: "privy_embedded_wallet",
        };
      } catch (error) {
        const normalizedError = normalizePrivyError(error);
        logBridge("sign_and_send_transaction_failed", normalizedError);
        throw normalizedError;
      }
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

  if (
    normalizedMessage.includes("wallet") ||
    normalizedMessage.includes("transaction") ||
    normalizedMessage.includes("rpc") ||
    normalizedMessage.includes("access token") ||
    normalizedMessage.includes("logged in")
  ) {
    return {
      code: privyCode || "transaction_error",
      message,
    };
  }

  return {
    code: privyCode || "unknown",
    message,
  };
}
