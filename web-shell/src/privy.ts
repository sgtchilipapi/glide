import Privy, {
  LocalStorage,
  getUserEmbeddedEthereumWallet,
  getUserEmbeddedSolanaWallet,
  type OAuthProviderID,
  type User,
} from "@privy-io/js-sdk-core";
import type { GlideAuthProvider, GlideShellEnv } from "./types";

type GlidePrivySession = {
  loggedIn: boolean;
  walletAddress: string;
  userId: string;
  loginMethod: string;
};

const DEFAULT_LOGIN_MODE = "login-or-sign-up";

let embeddedIframe: HTMLIFrameElement | null = null;
let embeddedListenerAttached = false;

function logPrivy(event: string, payload?: Record<string, unknown>): void {
  const entry = {
    at: new Date().toISOString(),
    source: "privy",
    event,
    ...(payload ?? {}),
  };
  console.log("[Glide Privy]", event, payload ?? {});
  const debugWindow = window as Window & {
    __glideDebug?: {
      events: Array<Record<string, unknown>>;
      push?: (entry: Record<string, unknown>) => void;
    };
  };
  if (!debugWindow.__glideDebug) {
    return;
  }
  if (typeof debugWindow.__glideDebug.push === "function") {
    debugWindow.__glideDebug.push(entry);
    return;
  }
  debugWindow.__glideDebug.events.push(entry);
}

export function canUsePrivy(env: GlideShellEnv): boolean {
  return (
    env.provider.mode === "privy" &&
    env.privy.appId.trim().length > 0 &&
    env.privy.clientId.trim().length > 0
  );
}

export function createGlidePrivyClient(env: GlideShellEnv): Privy {
  logPrivy("create_client", {
    hasAppId: env.privy.appId.trim().length > 0,
    hasClientId: env.privy.clientId.trim().length > 0,
    originUrl: env.privy.originUrl,
    callbackUrl: env.privy.callbackUrl,
  });
  return new Privy({
    appId: env.privy.appId,
    clientId: env.privy.clientId,
    storage: new LocalStorage(),
  });
}

export async function initializePrivy(client: Privy): Promise<void> {
  logPrivy("initialize_start");
  await client.initialize();
  logPrivy("initialize_done");
  await ensureEmbeddedWalletContext(client);
  logPrivy("embedded_wallet_context_ready");
}

export async function restorePrivySession(client: Privy): Promise<GlidePrivySession> {
  try {
    const { user } = await client.user.get();
    const session = toPrivySession(user, "restored_session");
    logPrivy("restore_session", {
      loggedIn: session.loggedIn,
      walletAddress: session.walletAddress,
      userId: session.userId,
    });
    return session;
  } catch (error) {
    logPrivy("restore_session_failed", {
      error: error instanceof Error ? error.message : String(error),
    });
    return emptySession();
  }
}

export async function beginPrivyLogin(
  client: Privy,
  env: GlideShellEnv,
): Promise<{ redirectUrl: string }> {
  logPrivy("begin_login", {
    provider: env.provider.oauthProvider,
    callbackUrl: env.privy.callbackUrl,
  });
  const response = await client.auth.oauth.generateURL(
    toPrivyProvider(env.provider.oauthProvider),
    env.privy.callbackUrl,
  );
  logPrivy("begin_login_redirect", {
    redirectUrl: response.url,
  });
  window.location.assign(response.url);
  return { redirectUrl: response.url };
}

export async function completePrivyOAuthCallback(
  client: Privy,
  env: GlideShellEnv,
): Promise<GlidePrivySession | null> {
  const params = getOAuthCallbackParams();
  if (!params) {
    logPrivy("callback_absent");
    return null;
  }

  logPrivy("callback_detected", {
    codeLength: params.code.length,
    stateLength: params.state.length,
    currentUrl: window.location.href,
  });

  const result = await client.auth.oauth.loginWithCode(
    params.code,
    params.state,
    toPrivyProvider(env.provider.oauthProvider),
    undefined,
    DEFAULT_LOGIN_MODE,
    {
      embedded: {
        solana: {
          createOnLogin: "users-without-wallets",
        },
      },
    },
  );

  clearOAuthCallbackParams();
  const session = toPrivySession(result.user, "oauth_callback");
  logPrivy("callback_completed", {
    loggedIn: session.loggedIn,
    walletAddress: session.walletAddress,
    userId: session.userId,
  });
  return session;
}

export async function logoutPrivy(client: Privy): Promise<void> {
  logPrivy("logout_start");
  await client.auth.logout();
  logPrivy("logout_done");
}

function emptySession(): GlidePrivySession {
  return {
    loggedIn: false,
    walletAddress: "",
    userId: "",
    loginMethod: "",
  };
}

function toPrivySession(user: User | null, loginMethod: string): GlidePrivySession {
  if (!user) {
    return emptySession();
  }

  const solanaWallet = getUserEmbeddedSolanaWallet(user);
  const ethereumWallet = getUserEmbeddedEthereumWallet(user);
  const walletAddress = String(
    solanaWallet?.address ?? ethereumWallet?.address ?? "",
  );

  return {
    loggedIn: true,
    walletAddress,
    userId: String(user.id ?? ""),
    loginMethod,
  };
}

function getOAuthCallbackParams(): {
  code: string;
  state: string;
  provider: string;
} | null {
  const url = new URL(window.location.href);
  const code = url.searchParams.get("privy_oauth_code");
  const state = url.searchParams.get("privy_oauth_state");
  const provider = url.searchParams.get("privy_oauth_provider") ?? "";
  if (!code || !state) {
    return null;
  }

  return { code, state, provider };
}

function clearOAuthCallbackParams(): void {
  const url = new URL(window.location.href);
  if (
    !url.searchParams.has("privy_oauth_code") &&
    !url.searchParams.has("privy_oauth_state")
  ) {
    return;
  }

  url.searchParams.delete("privy_oauth_code");
  url.searchParams.delete("privy_oauth_state");
  url.searchParams.delete("privy_oauth_provider");
  window.history.replaceState({}, document.title, url.toString());
}

async function ensureEmbeddedWalletContext(client: Privy): Promise<void> {
  if (!embeddedIframe) {
    embeddedIframe = document.createElement("iframe");
    embeddedIframe.src = client.embeddedWallet.getURL();
    embeddedIframe.style.display = "none";
    embeddedIframe.style.width = "0";
    embeddedIframe.style.height = "0";
    embeddedIframe.setAttribute("aria-hidden", "true");
    document.body.appendChild(embeddedIframe);
    logPrivy("embedded_iframe_created", {
      iframeUrl: embeddedIframe.src,
    });
  }

  if (embeddedIframe.contentWindow) {
    client.setMessagePoster(embeddedIframe.contentWindow);
    logPrivy("embedded_message_poster_set");
  }

  if (!embeddedListenerAttached) {
    window.addEventListener("message", (event) => {
      client.embeddedWallet.onMessage(event.data);
    });
    embeddedListenerAttached = true;
    logPrivy("embedded_message_listener_attached");
  }

  try {
    await client.embeddedWallet.ping(5000);
    logPrivy("embedded_ping_ok");
  } catch {
    logPrivy("embedded_ping_timeout");
    // Leave the iframe mounted even if ping times out during early boot.
  }
}

function toPrivyProvider(provider: GlideAuthProvider): OAuthProviderID {
  return provider as OAuthProviderID;
}
