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

export function canUsePrivy(env: GlideShellEnv): boolean {
  return (
    env.provider.mode === "privy" &&
    env.privy.appId.trim().length > 0 &&
    env.privy.clientId.trim().length > 0
  );
}

export function createGlidePrivyClient(env: GlideShellEnv): Privy {
  return new Privy({
    appId: env.privy.appId,
    clientId: env.privy.clientId,
    storage: new LocalStorage(),
  });
}

export async function initializePrivy(client: Privy): Promise<void> {
  await client.initialize();
  await ensureEmbeddedWalletContext(client);
}

export async function restorePrivySession(client: Privy): Promise<GlidePrivySession> {
  try {
    const { user } = await client.user.get();
    return toPrivySession(user, "restored_session");
  } catch {
    return emptySession();
  }
}

export async function beginPrivyLogin(
  client: Privy,
  env: GlideShellEnv,
): Promise<{ redirectUrl: string }> {
  const response = await client.auth.oauth.generateURL(
    toPrivyProvider(env.provider.oauthProvider),
    env.privy.callbackUrl,
  );
  window.location.assign(response.url);
  return { redirectUrl: response.url };
}

export async function completePrivyOAuthCallback(
  client: Privy,
  env: GlideShellEnv,
): Promise<GlidePrivySession | null> {
  const params = getOAuthCallbackParams();
  if (!params) {
    return null;
  }

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
  return toPrivySession(result.user, "oauth_callback");
}

export async function logoutPrivy(client: Privy): Promise<void> {
  await client.auth.logout();
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

function getOAuthCallbackParams(): { code: string; state: string } | null {
  const url = new URL(window.location.href);
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");
  if (!code || !state) {
    return null;
  }

  return { code, state };
}

function clearOAuthCallbackParams(): void {
  const url = new URL(window.location.href);
  if (!url.searchParams.has("code") && !url.searchParams.has("state")) {
    return;
  }

  url.searchParams.delete("code");
  url.searchParams.delete("state");
  url.searchParams.delete("provider");
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
  }

  if (embeddedIframe.contentWindow) {
    client.setMessagePoster(embeddedIframe.contentWindow);
  }

  if (!embeddedListenerAttached) {
    window.addEventListener("message", (event) => {
      client.embeddedWallet.onMessage(event.data);
    });
    embeddedListenerAttached = true;
  }

  try {
    await client.embeddedWallet.ping(5000);
  } catch {
    // Leave the iframe mounted even if ping times out during early boot.
  }
}

function toPrivyProvider(provider: GlideAuthProvider): OAuthProviderID {
  return provider as OAuthProviderID;
}
