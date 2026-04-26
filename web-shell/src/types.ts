export type GlideProviderMode = "mock" | "privy";

export type GlideAuthProvider =
  | "google"
  | "apple"
  | "twitter"
  | "github"
  | "discord"
  | "linkedin"
  | "spotify"
  | "tiktok"
  | "instagram"
  | "line";

export interface GlideShellEnv {
  provider: {
    name: string;
    mode: GlideProviderMode;
    oauthProvider: GlideAuthProvider;
  };
  privy: {
    appId: string;
    clientId: string;
    originUrl: string;
    callbackUrl: string;
  };
  backend: {
    url: string;
  };
  runtime: {
    appTitle: string;
    origin: string;
  };
}

export interface GlideSolanaTransactionOptions {
  skipPreflight?: boolean;
  maxRetries?: number;
  preflightCommitment?: "processed" | "confirmed" | "finalized";
  minContextSlot?: number;
}

export interface GlideTransactionPayload {
  kind: "solana_sign_and_send";
  chain: "solana";
  request_id: string;
  serialized_tx_base64: string;
  rpc_url: string;
  options?: GlideSolanaTransactionOptions;
  metadata?: Record<string, unknown>;
}

export interface GlideSponsoredActionPrepareRequest {
  kind: "backend_sponsored_action";
  request_id: string;
  wallet_address: string;
  chain: "solana";
  action: {
    kind: string;
    name: string;
  };
  game_payload?: Record<string, unknown>;
  metadata?: Record<string, unknown>;
}

export interface GlideSponsoredActionPrepareResponse {
  ok: boolean;
  request_id: string;
  status: "prepared" | "failed";
  sponsor: {
    sponsored: boolean;
    type: "backend";
  };
  transaction?: GlideTransactionPayload;
  error?: {
    code: string;
    message: string;
  };
}

export interface GlideSponsoredActionCompleteRequest {
  request_id: string;
  wallet_address: string;
  signature: string;
  chain: "solana";
}

export interface GlideSponsoredActionCompleteResponse {
  ok: boolean;
  request_id: string;
  status: "confirmed" | "failed";
  error?: {
    code: string;
    message: string;
  };
}

export interface GlideWalletBridge {
  ping(): Promise<Record<string, unknown>>;
  getShellEnv(): Promise<Record<string, unknown>>;
  getLoginState(): Promise<Record<string, unknown>>;
  login(): Promise<Record<string, unknown>>;
  logout(): Promise<Record<string, unknown>>;
  isLoggedIn(): Promise<Record<string, unknown>>;
  getWalletAddress(): Promise<Record<string, unknown>>;
  signAndSendTransaction(payload: GlideTransactionPayload | Record<string, unknown>): Promise<Record<string, unknown>>;
}
