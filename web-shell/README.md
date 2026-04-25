# Glide Web Shell

This folder holds the standalone web-shell toolchain for Glide.

Current SDK choice:
- `@privy-io/js-sdk-core`

Why this package:
- Privy’s official vanilla JavaScript docs use `@privy-io/js-sdk-core`
- Glide uses it to run OAuth login and embedded wallet provisioning from the Web shell
- Glide now treats Phantom as legacy, not active provider code

Official references:
- https://docs.privy.io/recipes/core-js
- https://docs.privy.io/basics/get-started/dashboard/app-clients
- https://docs.privy.io/recipes/react/allowed-oauth-redirects

Current status:
- dependency installed
- active wrapper source lives in:
  - `src/privy.ts`
  - `src/walletBridge.ts`
  - `src/types.ts`
- build output goes to:
  - `../godot-addon/addons/glide_web3/web_shell/bridge.js`

Before real Privy login:
1. create a Privy app
2. create a Privy app client
3. configure allowed origins for the app client
4. configure allowed OAuth redirect URLs
5. enable the chosen OAuth provider in the Privy Dashboard

Build:

```powershell
cd C:\Users\Paps\projects\glide\web-shell
npm run build
```

Legacy Phantom archive:
- `../legacy/phantom/`
