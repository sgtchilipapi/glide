# Glide User Guide

## Current Product State

Glide is a Godot addon that manages a wrapped Web export with:

- a custom HTML shell
- a bundled JavaScript bridge
- persistent plugin config
- a Privy-based embedded auth path

Active auth provider:
- Privy

Legacy provider:
- Phantom
- archived under `legacy/phantom/`

## Install The Addon

Copy this folder into your Godot project:

```text
godot-addon/addons/glide_web3
```

Your project should look like:

```text
your-project/
  project.godot
  addons/
    glide_web3/
      plugin.cfg
      plugin.gd
```

Then in Godot:

1. Open the project.
2. Go to `Project > Project Settings > Plugins`.
3. Enable `Glide Web3`.

The plugin appears in Godot’s bottom panel as `Glide Web3`.

## Plugin Fields

Current active fields:

- `Backend URL`
- `Output Dir`
- `App Title`
- `Privy App ID`
- `Privy Client ID`
- `Privy Origin URL`
- `Privy Callback URL`
- `Enable PWA`

Save them with `Save Config`.

They persist to:

```text
res://glide/glide_plugin_config.cfg
```

## Required Privy Configuration

Glide’s active Privy path expects these values to be configured in the plugin:

1. `Privy App ID`
2. `Privy Client ID`
3. `Privy Origin URL`
4. `Privy Callback URL`

Meaning:

- `Privy App ID`
  - your Privy app identifier from the Privy Dashboard
- `Privy Client ID`
  - your Privy app client identifier
- `Privy Origin URL`
  - the exact web origin that serves the app
  - example:
    - `https://your-domain.example`
- `Privy Callback URL`
  - the exact OAuth redirect URL
  - example:
    - `https://your-domain.example/auth/callback`

## Required Privy Dashboard Configuration

Based on Privy’s official docs, Glide’s core JS integration requires:

1. a Privy app
2. a Privy app client
3. the app client allowed origins configured for your web origin
4. allowed OAuth redirect URLs configured for your callback URL
5. the chosen OAuth login method enabled in the Privy Dashboard

For Glide’s current default login flow:

- enabled OAuth provider should include `Google`

Important:

- Privy allowed origins must match the origin exactly
- Privy allowed OAuth redirect URLs must match the callback URL exactly
- query params and trailing slash mismatches can fail

## Build Flow

Use the Glide bottom panel:

1. `Save Config`
2. `Validate Setup`
3. `Build Web`

`Build Web` does this:

- validates the addon shell files
- validates export capability
- ensures the managed preset uses Glide’s custom shell
- exports the Web build
- copies `bridge.js` into the build output
- injects the active Glide config into exported `index.html`
- generates a callback page for the configured callback URL path

Default output:

```text
res://build/web/
```

In the sample project used during development, that resolves to:

```text
C:\Users\Paps\Documents\sample\build\web
```

## Run The Exported App

Serve the build over HTTP.

Example:

```powershell
cd C:\Users\Paps\Documents\sample\build\web
python -m http.server 8000 --bind 127.0.0.1
```

Then open:

```text
http://127.0.0.1:8000/index.html
```

Do not use `file://` for runtime testing.

## What To Verify In Browser

At minimum:

1. the shell shows `Glide Web Shell Template`
2. the shell status shows `Bridge: ready`
3. the Godot app loads inside the canvas

If you are testing the wallet demo scene:

1. set main scene to `res://scenes/wallet_login_demo.tscn`
2. rebuild with Glide
3. serve the build
4. click `Login`

## Current Auth Behavior

Current active auth flow:

- Glide uses Privy core JS
- Glide defaults to Google OAuth for the embedded login attempt
- on successful callback, Glide completes the Privy OAuth flow before Godot boot
- Glide restores session state on later page loads if the Privy session still exists

Current embedded wallet behavior:

- Glide requests Solana wallet creation on login for users without one
- wallet address is restored from the Privy user object when available

Current fallback behavior:

- if `Privy App ID` or `Privy Client ID` is blank, Glide stays in `mock` mode

In mock mode:

- login returns a mock success
- address is `MOCK_ADDRESS_001`

## Important Current Limitation

The active runtime auth provider is Privy, but the transaction path is still only stubbed in Glide.

So current production-ready area:

- wrapped Web export
- shell bridge
- Privy login configuration path
- Privy OAuth callback completion path

Not yet finalized:

- real transaction signing and send path
- backend-prepared transaction execution

## Active Source Of Truth

Main addon files:

- `godot-addon/addons/glide_web3/plugin.gd`
- `godot-addon/addons/glide_web3/config/glide_plugin_config.gd`
- `godot-addon/addons/glide_web3/runtime/js_bridge.gd`
- `godot-addon/addons/glide_web3/runtime/web_wallet_service.gd`
- `godot-addon/addons/glide_web3/web_shell/index.html`
- `godot-addon/addons/glide_web3/web_shell/bridge.js`

Web shell source:

- `web-shell/src/index.ts`
- `web-shell/src/types.ts`
- `web-shell/src/privy.ts`
- `web-shell/src/walletBridge.ts`

Legacy Phantom archive:

- `legacy/phantom/`
