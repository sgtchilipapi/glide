export type GlideProviderMode = "mock" | "phantom_browser_sdk";

export type GlideAuthProvider =
  | "google"
  | "apple"
  | "phantom"
  | "injected"
  | "deeplink";

export interface GlideShellEnv {
  provider: {
    name: string;
    mode: GlideProviderMode;
  };
  phantom: {
    clientId: string;
    appId: string;
    redirectOrigin: string;
  };
  backend: {
    url: string;
  };
  runtime: {
    appTitle: string;
    origin: string;
  };
}

export interface GlideWalletBridge {
  ping(): Promise<Record<string, unknown>>;
  getShellEnv(): Promise<Record<string, unknown>>;
  login(): Promise<Record<string, unknown>>;
  logout(): Promise<Record<string, unknown>>;
  isLoggedIn(): Promise<Record<string, unknown>>;
  getWalletAddress(): Promise<Record<string, unknown>>;
  signAndSendTransaction(payload: Record<string, unknown>): Promise<Record<string, unknown>>;
}
