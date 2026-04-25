import { AddressType, BrowserSDK, type BrowserSDKConfig } from "@phantom/browser-sdk";
import type { GlideShellEnv } from "../../../../web-shell/src/types";

export function createGlidePhantomSdk(env: GlideShellEnv): BrowserSDK {
  const config: BrowserSDKConfig = {
    addressTypes: [AddressType.solana],
    appId: env.phantom.appId || undefined,
    authOptions: {
      redirectUrl: env.phantom.callbackUrl || `${env.runtime.origin}/auth/callback`,
    },
  };

  return new BrowserSDK(config);
}

export function canUseEmbeddedPhantom(env: GlideShellEnv): boolean {
  return env.provider.mode === "phantom_browser_sdk" && env.phantom.appId.trim().length > 0;
}

export function getAllowedProviders() {
  return ["phantom", "google", "apple", "injected", "deeplink"];
}

export function getDefaultLoginProvider(): string {
  return "google";
}

export async function connectWithPhantom(
  sdk: BrowserSDK,
  provider: string,
): Promise<Record<string, unknown>> {
  const result = await sdk.connect({ provider });

  return {
    ok: true,
    provider,
    address: result?.addresses?.[0]?.address ?? "",
    addresses: result?.addresses ?? [],
  };
}
