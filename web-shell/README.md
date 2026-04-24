# Glide Web Shell

This folder holds the standalone web-shell toolchain for Glide.

Current SDK choice:
- `@phantom/browser-sdk`

Why this package:
- Phantom's current official browser docs for vanilla JavaScript/TypeScript use `@phantom/browser-sdk`
- it supports both injected and embedded provider flows
- `@phantom/wallet-sdk` is deprecated and should not be used for new integration work

Official references:
- https://docs.phantom.com/sdks/browser-sdk

Current status:
- dependency installed
- no real Phantom runtime wiring yet
- wrapper module comes next in Slice 5.3

Before real integration:
1. register app in Phantom Portal
2. obtain App ID
3. allowlist local/dev origins
4. allowlist redirect URL used by the app

Expected next files:
- `src/phantom.ts`
- `src/walletBridge.ts`
- `src/types.ts`
