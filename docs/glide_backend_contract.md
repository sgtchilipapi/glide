# Glide Sponsored Transaction Backend Contract

## Scope

This document defines the product-facing backend contract for Glide's intended runtime model:

- users authenticate with Privy embedded wallets
- Godot gameplay calls `WalletService`
- the shell talks to a backend to prepare a sponsored action
- the shell executes the returned transaction payload
- Godot receives structured completion results

This document defines the contract only.

It does **not** require Glide to bundle a backend or database implementation.

## Principles

- backend is authoritative
- gameplay code does not construct provider SDK objects
- gameplay code does not directly handle Privy tokens
- transaction bytes stay out of Godot until they are serialized into a JSON-safe payload
- all cross-boundary payloads must be JSON-safe

## Backend URL Source

Glide reads `backend_url` from plugin config and injects it into the exported shell as:

```javascript
window.__glideEnv.backend.url
```

If blank:

- backend-sponsored flows are unavailable
- shell should return a structured configuration error for backend-required actions

## Prepare Sponsored Action

Recommended endpoint:

```text
POST {backend_url}/api/sponsored-actions/prepare
```

Request body:

```json
{
  "request_id": "req_123",
  "wallet_address": "DNRtRyhQr2v7QVvRm2unENwTa8ib8iykcTCiNVmiNtfw",
  "chain": "solana",
  "action": {
    "kind": "game_action",
    "name": "claim_reward"
  },
  "game_payload": {
    "reward_id": "daily_001"
  },
  "metadata": {
    "scene": "wallet_login_demo"
  }
}
```

Required request fields:

- `request_id`
- `wallet_address`
- `chain`
- `action.kind`
- `action.name`

Response body on success:

```json
{
  "ok": true,
  "request_id": "req_123",
  "status": "prepared",
  "sponsor": {
    "sponsored": true,
    "type": "backend"
  },
  "transaction": {
    "kind": "solana_sign_and_send",
    "chain": "solana",
    "request_id": "req_123",
    "serialized_tx_base64": "<base64 serialized transaction>",
    "rpc_url": "https://api.devnet.solana.com",
    "options": {
      "preflightCommitment": "confirmed"
    },
    "metadata": {
      "policy": "reward_claim_v1"
    }
  }
}
```

Response body on failure:

```json
{
  "ok": false,
  "request_id": "req_123",
  "status": "failed",
  "error": {
    "code": "not_eligible",
    "message": "User is not eligible for this sponsored action."
  }
}
```

## Complete Sponsored Action

Recommended endpoint:

```text
POST {backend_url}/api/sponsored-actions/complete
```

Request body:

```json
{
  "request_id": "req_123",
  "wallet_address": "DNRtRyhQr2v7QVvRm2unENwTa8ib8iykcTCiNVmiNtfw",
  "signature": "<solana-transaction-signature>",
  "chain": "solana"
}
```

Recommended success response:

```json
{
  "ok": true,
  "request_id": "req_123",
  "status": "confirmed"
}
```

## Status Lookup

Recommended endpoint:

```text
GET {backend_url}/api/sponsored-actions/{request_id}
```

Recommended purpose:

- poll long-running sponsored flows if needed
- inspect pending/confirmed/failed state

## Shell Expectations

The shell should:

1. read `window.__glideEnv.backend.url`
2. reject backend-sponsored actions if blank
3. send the prepare request
4. validate the returned `transaction` payload
5. pass it into `signAndSendTransaction(...)`
6. report completion back to backend
7. return a JSON-safe result to Godot

Current shell entry point:

- backend-sponsored actions can enter the shell through `signAndSendTransaction(...)`
- use this payload shape:

```json
{
  "kind": "backend_sponsored_action",
  "request_id": "req_123",
  "wallet_address": "DNRtRyhQr2v7QVvRm2unENwTa8ib8iykcTCiNVmiNtfw",
  "chain": "solana",
  "action": {
    "kind": "game_action",
    "name": "claim_reward"
  },
  "game_payload": {
    "reward_id": "daily_001"
  },
  "metadata": {
    "scene": "wallet_login_demo"
  }
}
```

## Godot Expectations

Godot should only see:

- request initiated
- success with transaction signature
- failure with normalized error code/message

Godot should not need to know:

- Privy auth token handling
- backend auth headers
- provider SDK transaction object types

## Error Classes

Recommended normalized backend error classes:

- `misconfigured`
- `unauthorized`
- `not_eligible`
- `rate_limited`
- `backend_unavailable`
- `invalid_response`
- `unknown`

## Current Implementation Boundary

Current repo state:

- backend URL config exists in plugin UI
- backend URL is injected into shell env during build
- low-level transaction payload schema exists

Not yet implemented:

- shell fetch helper
- demo backend mode
- end-to-end backend-sponsored action runtime flow
