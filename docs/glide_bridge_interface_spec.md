# Glide Bridge Interface Spec

## Scope

This document freezes the initial Glide shell bridge contract for Slice 2.

Current goal:
- prove Godot can call a shell method
- keep payloads JSON-safe
- keep provider-specific types out of the bridge

## Global Bridge Object

The shell must expose this global object before Godot boot finishes:

```javascript
window.glideWallet = {
  ping: async () => ({ ok: true, source: "shell" })
};
```

The shell must also confirm bridge readiness before starting Godot.

Current boot marker:

```javascript
window.__glideBridgeReady = true;
```

## Method Contract

### `ping()`

Purpose:
- smoke test shell reachability from Godot

Return shape:

```json
{
  "ok": true,
  "source": "shell"
}
```

Rules:
- must be async / promise-based
- must return plain JSON-safe data
- must not return SDK objects or DOM objects
- must exist before Godot boot begins

## Godot-Side Expected Shape

For Slice 2, Godot should expect a dictionary equivalent to:

```gdscript
{
	"ok": true,
	"source": "shell"
}
```

Required fields:
- `ok: bool`
- `source: String`

## Non-Goals For This Slice

Not part of 2.1:
- login
- logout
- wallet address retrieval
- transaction signing
- Phantom SDK calls from Godot

Those come in later slice items.

## Current Source Of Truth

Shell implementation:
- `godot-addon/addons/glide_web3/web_shell/bridge.js`
- `godot-addon/addons/glide_web3/web_shell/index.html`

This spec document:
- `docs/glide_bridge_interface_spec.md`
