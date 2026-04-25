import { AddressType, BrowserSDK, type BrowserSDKConfig } from "@phantom/browser-sdk";
import type { GlideAuthProvider, GlideShellEnv } from "./types";

export function createGlidePhantomSdk(env: GlideShellEnv): BrowserSDK {
  const config: BrowserSDKConfig = {
    providers: getAllowedProviders(),
    addressTypes: [AddressType.solana],
    appId: env.phantom.appId || undefined,
    authOptions: {
      redirectUrl: env.phantom.redirectOrigin || env.runtime.origin,
    },
    autoConnect: true,
  };

  return new BrowserSDK(config);
}

export function canUseEmbeddedPhantom(env: GlideShellEnv): boolean {
  return env.provider.mode === "phantom_browser_sdk" && env.phantom.appId.trim().length > 0;
}

export function getAllowedProviders(): GlideAuthProvider[] {
  return ["phantom", "google", "apple", "injected", "deeplink"];
}

export function getDefaultLoginProvider(): GlideAuthProvider {
  return "google";
}

export async function connectWithPhantom(
  sdk: BrowserSDK,
  provider: GlideAuthProvider,
): Promise<Record<string, unknown>> {
  const result = await sdk.connect({ provider });
  const primaryAddress =
    result.addresses && result.addresses.length > 0
      ? (result.addresses[0]?.address ?? "")
      : "";

  return {
    ok: true,
    provider,
    addresses: result.addresses ?? [],
    address: primaryAddress,
  };
}
