# Glide Product Implementation Plan
## Godot Embedded Wallet Web Export Toolkit — Vertical Slice Plan

## Provider Migration Notice

Active embedded auth provider:

- Privy

Legacy embedded auth provider:

- Phantom
- archived under `legacy/phantom/`

Interpretation rule for this plan:

- active implementation work should target Privy
- any older Phantom-specific references below are historical unless explicitly reactivated

## Context

This plan is for building a **Godot addon product** that lets a Godot developer:

- install an addon,
- configure a Web export preset managed by the product,
- export a Godot game to Web using a **custom HTML shell**,
- wrap the exported game in a **TypeScript/JavaScript shell**,
- use **Privy embedded wallet** integration through that shell,
- call a clean Godot-side API from gameplay code,
- avoid external wallet extension popups,
- optionally package the result as a PWA.

### Core architecture

- **Godot addon/plugin** = written in **GDScript**
- **Web shell** = written in **TypeScript**, compiled to JavaScript
- **Bridge** = Godot `JavaScriptBridge` on the Godot side, `window.glideWallet` on the JS side
- **Backend** = external system, not implemented in v1 of this product, but the product must support backend URLs and payload handoff

### Core principle

- **Godot = game runtime**
- **Web shell = auth + wallet + wrapper**
- **Backend = authority**

### Scope of v1

- Web export only
- Privy embedded wallet only
- No multi-provider abstraction
- No native mobile plugins
- One managed Web preset only
- Product must be usable early and improved through vertical slices

---

# Delivery Strategy

## Build methodology

Development must follow **vertical slices** and **very small work orders**.

Each slice must:

1. produce a real, installable addon state,
2. be manually imported into a local Godot test project,
3. be manually tested through the real user workflow,
4. end in a usable checkpoint.

No slice should be only “internal architecture” with no real testable outcome.

## Testing methodology

Manual testing is the primary workflow early on.

Required loop for every slice:

1. implement work orders for the slice
2. build/package the addon
3. import addon into a clean local Godot project
4. enable plugin
5. execute manual test script
6. record pass/fail
7. fix before moving forward

## Local iteration workflow

For this repository's current local development loop, every implementation iteration must also do the following before reporting test results:

1. replace the sample project addon folder:
   - `C:\Users\Paps\Documents\sample\addons\glide_web3`
   - with the current repo copy from:
   - `C:\Users\Paps\projects\glide\godot-addon\addons\glide_web3`
2. delete the sample project build folder:
   - `C:\Users\Paps\Documents\sample\build`
3. after deleting the build folder, run a fresh Godot build or export before checking build outputs
4. use the sample project at:
   - `C:\Users\Paps\Documents\sample`
5. run Godot verification/export commands with the verified executable:
   - `C:\Users\Paps\Desktop\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe`
6. after a successful Web build, serve the exported app over local HTTP before runtime testing:
   - working directory:
   - `C:\Users\Paps\Documents\sample\build\web`
   - example command:
   - `python -m http.server 8000`
   - example URL:
   - `http://127.0.0.1:8000/index.html`

### Notes

- Prefer the verified regular Godot executable above for automation.
- Do not rely on `Godot_v4.6.2-stable_win64_console.exe` for automation in this environment because it hit Windows elevation error `740`.
- Do not rely on opening exported Web builds with `file://` paths for runtime testing. Serve them over local HTTP.
- For any third-party dependency, SDK selection, install command, or integration detail, verify against the current official vendor documentation first before answering, implementing, or instructing installation.
- This local workflow is an implementation/testing convenience for this machine and does not change the product requirements for end users.

---

# Repository / Workspace Structure

Recommended repo layout:

```text
/glide-web3-toolkit
  /godot-addon
    /addons/glide_web3
      plugin.cfg
      plugin.gd
      /core
      /editor
      /runtime
      /export
      /ui
      /config
      /tests
  /web-shell
    package.json
    tsconfig.json
    index.html
    /src
      walletBridge.ts
      privy.ts
      godotBoot.ts
      env.ts
      types.ts
    /public
      manifest.webmanifest
      icons/
  /docs
    product-spec.md
    implementation-plan.md
    manual-test-scripts/
  /fixtures
    /godot-test-project
```

---

# Slice Map

## Slice 1 — Installable addon + managed wrapped Web export
**Outcome:** The product can already be imported into Godot, enabled, and used to export a Godot project to Web with the managed custom HTML shell.

## Slice 2 — Working Godot ↔ JS bridge with dummy methods
**Outcome:** Godot can call a JS method in the wrapper shell and receive a response.

## Slice 3 — Persistent plugin config + managed preset state
**Outcome:** Plugin settings persist and are used to control export behavior.

## Slice 4 — WalletService runtime API + mock end-to-end login flow
**Outcome:** Gameplay code can call a stable Godot API, backed by mock shell behavior.

## Slice 5 — Privy embedded login integration
**Outcome:** Real Privy embedded login flow can be triggered from the shell.

## Slice 6 — Wallet address/session state returned to Godot
**Outcome:** Godot runtime can receive real session state and address data.

## Slice 7 — Transaction handoff contract + mock transaction flow
**Outcome:** Godot can send a transaction payload to the shell and receive a structured result.

## Slice 8 — Backend-aware transaction preparation contract
**Outcome:** Product supports backend URL configuration and a documented handoff path for backend-prepared payloads.

## Slice 9 — PWA packaging layer
**Outcome:** Exported app is installable as a PWA.

## Slice 10 — Hardening, logging, diagnostics, and docs
**Outcome:** Product is usable by third parties with diagnostics and onboarding docs.

---

# Slice 1 — Installable addon + managed wrapped Web export

## Slice goal

Prove the product is real inside Godot.

By the end of this slice, a developer must be able to:

- copy the addon into a Godot project,
- enable the plugin,
- see a Glide Web3 panel/tool entry,
- click a build action,
- produce a Web export that uses the product’s custom shell.

## Work Order 1.1 — Create minimal addon skeleton

### Objective
Create an addon that Godot recognizes and enables.

### Instructions
- Create `addons/glide_web3/plugin.cfg`
- Create `addons/glide_web3/plugin.gd`
- Register as an `EditorPlugin`
- Ensure plugin appears in Project Settings > Plugins

### Deliverables
- plugin loads without error
- plugin can be enabled/disabled

### Acceptance criteria
- addon shows in plugin list
- enabling does not produce script/runtime errors

### Manual test
1. Open test Godot project
2. Copy addon into `/addons`
3. Open Godot editor
4. Verify plugin appears
5. Enable plugin
6. Confirm no errors in Output/Debugger

---

## Work Order 1.2 — Add visible editor entry point

### Objective
Give the user an obvious entry point for the product.

### Instructions
- Add a tool menu item or dock panel named `Glide Web3`
- Start with simple static UI
- Include placeholder buttons:
  - Validate Setup
  - Build Web

### Deliverables
- panel or tool menu action visible in editor

### Acceptance criteria
- user can open the product UI without touching code

### Manual test
1. Enable plugin
2. Open panel/menu
3. Confirm both buttons exist

---

## Work Order 1.3 — Create shell template folder in addon

### Objective
Ship a custom shell as part of the product.

### Instructions
- Add template files under addon package, e.g.:
  - `/addons/glide_web3/web_shell/index.html`
  - `/addons/glide_web3/web_shell/bridge.js`
- Keep JS minimal for now
- Shell must be a valid Godot custom Web HTML shell template
- Include visual marker text in the shell so it can be verified later

### Deliverables
- static shell files included in addon

### Acceptance criteria
- files exist and can be copied into a build path later

---

## Work Order 1.4 — Define managed Web preset name

### Objective
Lock the product to one preset for v1.

### Instructions
- Choose preset name: `GlideWeb`
- Create a constants file for preset name and default output path
- Do not support multiple presets in v1

### Deliverables
- single canonical preset name used throughout addon code

### Acceptance criteria
- no preset name duplication/hardcoding across files

---

## Work Order 1.5 — Add build output directory config

### Objective
Standardize build destination.

### Instructions
- Add a default build output path, such as:
  - `res://build/web/`
  - or a user-configurable path stored in plugin config
- For v1, keep it simple and deterministic

### Deliverables
- one default output directory constant or config field

### Acceptance criteria
- build output location is predictable

---

## Work Order 1.6 — Create export setup validator

### Objective
Check minimum export prerequisites before build.

### Instructions
- Implement a validator function that checks:
  - project has Web export templates installed or export can proceed
  - product shell files exist
  - output path is resolvable
- Return human-readable validation messages

### Deliverables
- validation routine callable from UI

### Acceptance criteria
- Validate Setup button reports meaningful result

---

## Work Order 1.7 — Wire Validate Setup button

### Objective
Make validation visible to the user.

### Instructions
- Connect Validate Setup UI action to validator
- Display result in:
  - panel label,
  - popup,
  - or editor console

### Deliverables
- visible validation response

### Acceptance criteria
- pressing Validate Setup yields useful output

---

## Work Order 1.8 — Create preset discovery logic

### Objective
Determine whether `GlideWeb` exists.

### Instructions
- Implement preset lookup logic
- If preset does not exist, report it clearly
- Do not auto-create preset yet if API path is uncertain; first detect

### Deliverables
- function `has_glide_web_preset()` or equivalent

### Acceptance criteria
- plugin can distinguish present vs missing preset

---

## Work Order 1.9 — Add build button stub

### Objective
Create end-user build flow scaffold.

### Instructions
- Wire Build Web button to:
  - validate setup,
  - check preset presence,
  - log intended build action
- No real export yet

### Deliverables
- end-to-end click path exists

### Acceptance criteria
- clicking button runs through validation and logs next action

---

## Work Order 1.10 — Implement export invocation path

### Objective
Perform a real Web export using the managed preset.

### Instructions
- Implement the actual export path using either:
  - editor-side export API, or
  - controlled Godot CLI invocation
- Use preset `GlideWeb`
- Output to the chosen build directory

### Deliverables
- real exported Web build

### Acceptance criteria
- build folder contains Godot web export artifacts

### Manual test
1. Ensure test project has `GlideWeb` preset
2. Click Build Web
3. Check output folder for `.html`, `.js`, `.wasm`, `.pck` or current Godot output set
4. Confirm build completes without editor crash

---

## Work Order 1.11 — Set custom shell path for export

### Objective
Ensure exported build uses the product’s wrapper shell.

### Instructions
- Update the managed preset or export flow so that custom HTML shell points to product shell template
- Ensure the shell is part of the export path

### Deliverables
- exported HTML reflects custom shell

### Acceptance criteria
- exported page contains the visual marker from custom shell

### Manual test
1. Build Web
2. Open generated HTML in browser
3. Inspect page source or rendered page
4. Confirm custom shell marker appears

---

## Work Order 1.12 — Slice 1 stabilization

### Objective
Close the slice cleanly.

### Instructions
- fix path issues
- ensure addon works in a clean project
- remove obvious hardcoded local-machine paths

### Slice 1 exit criteria
- addon installs cleanly
- panel/button visible
- Validate Setup works
- Build Web produces wrapped export
- test project can open exported build in browser

---

# Slice 2 — Working Godot ↔ JS bridge with dummy methods

## Slice goal

Prove bidirectional contract viability before wallet integration.

## Work Order 2.1 — Create bridge interface spec

### Objective
Freeze the initial shell API shape.

### Instructions
Define global object:

```ts
window.glideWallet = {
  ping: async () => ({ ok: true, source: "shell" })
}
```

Also define the Godot-side expected return structure.

### Deliverables
- bridge contract doc
- minimal TypeScript or JS implementation

---

## Work Order 2.2 — Add bridge script to custom shell

### Objective
Load bridge before Godot boot.

### Instructions
- Ensure `bridge.js` or compiled `bridge.bundle.js` is loaded by shell
- Confirm `window.glideWallet` exists before Godot attempts to use it

### Acceptance criteria
- shell loads with global bridge object defined

---

## Work Order 2.3 — Create Godot bridge helper class

### Objective
Centralize JS bridge calls.

### Instructions
- Create `runtime/js_bridge.gd`
- Add helper method such as `call_async(method_name: String, payload := {})`
- Do not scatter JavaScriptBridge usage across the addon

### Deliverables
- one reusable Godot bridge helper

---

## Work Order 2.4 — Call dummy bridge method from plugin UI

### Objective
Prove the plugin can talk to wrapper JS.

### Instructions
- Add test button `Ping Shell`
- Call `window.glideWallet.ping()`
- Surface result in UI or logs

### Acceptance criteria
- result is visible and structured

### Manual test
1. Build Web
2. Open exported app
3. Trigger ping path
4. Confirm shell response reaches Godot

---

## Work Order 2.5 — Handle bridge failure path

### Objective
Add first error handling path.

### Instructions
- If bridge object or method is absent, return structured error
- Expose error in human-readable way

### Acceptance criteria
- missing bridge does not crash runtime

---

## Work Order 2.6 — Slice 2 stabilization

### Exit criteria
- Godot can call JS bridge successfully
- missing bridge is handled gracefully
- bridge helper exists as single integration point

---

# Slice 3 — Persistent plugin config + managed preset state

## Slice goal

Move from hardcoded behavior to controlled product configuration.

## Work Order 3.1 — Create plugin config resource/file

### Objective
Persist settings.

### Instructions
Support fields:
- backend_url
- output_dir
- pwa_enabled
- app_title
- preset_name (fixed to `GlideWeb` by default, editable only if intentionally allowed later)

### Acceptance criteria
- config survives editor restart

---

## Work Order 3.2 — Bind config to editor UI

### Objective
Make settings editable.

### Instructions
- add editable fields in plugin panel
- add Save / Apply action if needed

### Acceptance criteria
- user edits persist correctly

---

## Work Order 3.3 — Load config on plugin startup

### Objective
Ensure plugin rehydrates state.

### Instructions
- plugin loads config in `_enter_tree()`
- UI reflects loaded values

---

## Work Order 3.4 — Use config during build

### Objective
Make build path driven by config.

### Instructions
- output dir and app title should come from config
- shell generation should consume config as needed

---

## Work Order 3.5 — Preset status display

### Objective
Make preset management visible.

### Instructions
- show whether `GlideWeb` exists
- show current output path
- show current shell path

---

## Work Order 3.6 — Slice 3 stabilization

### Exit criteria
- config persists
- panel is usable
- build uses persisted values

---

# Slice 4 — WalletService runtime API + mock login flow

## Slice goal

Freeze the Godot-side runtime API before real embedded-provider integration.

## Work Order 4.1 — Create `WalletService` interface

### Objective
Define the API gameplay code will use.

### Instructions
Methods:
- `login()`
- `logout()`
- `is_logged_in()`
- `get_wallet_address()`
- `sign_and_send_transaction(payload)`

Signals:
- `login_success`
- `login_failed`
- `logout_success`
- `tx_success`
- `tx_failed`

---

## Work Order 4.2 — Create `WebWalletService`

### Objective
Implement WalletService for web using bridge helper.

### Instructions
- route calls through `js_bridge.gd`
- keep provider-specific logic out of this layer as much as possible

---

## Work Order 4.3 — Create shell mock login method

### Objective
Return fake session for end-to-end test.

### Instructions
Implement shell methods:
- `login() => { ok: true, address: "MOCK_ADDRESS_001" }`
- `isLoggedIn() => true`
- `getWalletAddress() => "MOCK_ADDRESS_001"`

---

## Work Order 4.4 — Add demo scene in test project

### Objective
Give a minimal runtime test surface.

### Instructions
- create simple Godot scene with:
  - Login button
  - status label
  - address label

### Acceptance criteria
- scene exercises WalletService only, not direct bridge calls

---

## Work Order 4.5 — Wire login flow to mock shell

### Objective
Prove product can be used from game code.

### Manual test
1. Open demo scene
2. Click Login
3. Confirm `login_success` fires
4. Confirm address appears in UI

---

## Work Order 4.6 — Slice 4 stabilization

### Exit criteria
- gameplay code uses WalletService
- mock end-to-end login works

---

# Slice 5 — Privy embedded login integration

## Slice goal

Replace mock login with real Privy embedded auth.

## Work Order 5.1 — Add web shell environment/config structure

### Objective
Prepare shell for real provider config.

### Instructions
Support:
- Privy app/client config
- redirect/origin config if needed
- dev vs prod mode

---

## Work Order 5.2 — Install Privy shell dependencies

### Objective
Integrate actual provider SDK in web shell project.

### Instructions
- add Privy embedded auth dependencies
- build minimal provider wrapper module, e.g. `privy.ts`

---

## Work Order 5.3 — Create provider wrapper boundary

### Objective
Prevent Privy SDK from leaking across shell.

### Instructions
- create shell-local wrapper:
  - `privyLogin()`
  - `privyLogout()`
  - `privyGetAddress()`

### Acceptance criteria
- `walletBridge.ts` talks to `privy.ts`, not raw SDK calls all over the shell

---

## Work Order 5.4 — Replace mock login implementation

### Objective
Use real Privy embedded flow.

### Acceptance criteria
- shell login method now delegates to Privy embedded login
- mock code removed or gated behind debug mode

---

## Work Order 5.5 — Manual Privy login test

### Manual test
1. Build product
2. Import into Godot test project
3. Export
4. Open app in supported browser
5. Trigger login from demo scene
6. Complete Privy embedded flow
7. Confirm no extension popup dependency
8. Confirm login completes

---

## Work Order 5.6 — Handle cancel/error cases

### Objective
Normalize real auth errors.

### Instructions
Return structured errors:
- cancelled
- unavailable
- misconfigured
- unknown

### Exit criteria
- failed login does not leave UI stuck

---

# Slice 6 — Wallet address/session state returned to Godot

## Slice goal

After real login, Godot sees real session state.

## Work Order 6.1 — Implement `isLoggedIn()` in shell

## Work Order 6.2 — Implement `getWalletAddress()` in shell

## Work Order 6.3 — Map results into WalletService signals/state

## Work Order 6.4 — Add session refresh action to demo UI

## Work Order 6.5 — Add startup session check on scene load

### Manual test
1. Login once
2. Reload app if supported
3. Trigger session refresh
4. Confirm address/session state behaves correctly

### Exit criteria
- runtime can retrieve actual wallet address

---

# Slice 7 — Transaction handoff contract + mock transaction flow

## Slice goal

Define and test the transaction path before backend integration is finalized.

## Work Order 7.1 — Define transaction payload schema

### Instructions
Define minimal schema:
- `kind`
- `serialized_tx` or equivalent payload field
- `chain`
- `request_id`
- optional metadata

---

## Work Order 7.2 — Add `signAndSendTransaction()` to shell bridge

## Work Order 7.3 — Add mock tx implementation

### Objective
Return fake tx result first.

---

## Work Order 7.4 — Add demo transaction scene/control

### Objective
Test runtime tx path via WalletService.

---

## Work Order 7.5 — Manual transaction mock test

### Acceptance criteria
- Godot sends payload
- shell returns structured result
- Godot receives tx success signal

---

# Slice 8 — Backend-aware transaction preparation contract

## Slice goal

Add the backend-facing configuration and documented handoff needed for real game flows.

## Work Order 8.1 — Add backend URL config to plugin UI and shell build config

## Work Order 8.2 — Define backend request/response contract doc

### Must describe
- how game asks backend for tx payload
- what payload shape shell expects
- what backend verifies after tx

---

## Work Order 8.3 — Add optional fetch helper in shell

### Objective
Keep backend comms in shell layer if needed for product demos/tools

---

## Work Order 8.4 — Add demo backend integration mode flag

### Objective
Allow mock vs backend-driven mode

---

## Work Order 8.5 — Manual backend contract test

### Acceptance criteria
- app can consume backend-provided tx payload in a controlled test setup

---

# Slice 9 — PWA packaging layer

## Slice goal

Make output installable and app-like.

## Work Order 9.1 — Add manifest template

## Work Order 9.2 — Add icon pipeline or required icon placeholders

## Work Order 9.3 — Add PWA toggle to plugin config

## Work Order 9.4 — Ensure build copies manifest/icons to output

## Work Order 9.5 — Add optional service worker support

## Work Order 9.6 — Manual PWA test

### Manual test
1. Build PWA
2. Serve build locally or deploy to test host
3. Open in supported browser
4. Confirm installability
5. Launch from installed icon
6. Verify app opens in standalone mode

---

# Slice 10 — Hardening, diagnostics, docs

## Slice goal

Make the product understandable and supportable.

## Work Order 10.1 — Add structured logging in addon

## Work Order 10.2 — Add structured logging in shell

## Work Order 10.3 — Add diagnostics panel section
Show:
- preset state
- shell path
- build output path
- bridge availability
- runtime mode
- provider mode

## Work Order 10.4 — Add installer/setup guide

## Work Order 10.5 — Add “first project” quickstart

## Work Order 10.6 — Add demo project packaging

## Work Order 10.7 — Add error code reference

## Work Order 10.8 — Final manual QA pass across clean project setup

---

# Cross-Slice Rules

## Rule 1 — No direct gameplay dependence on provider SDKs
Gameplay code must call `WalletService`, never provider SDK APIs or raw bridge functions.

## Rule 2 — No scattered JavaScriptBridge calls
All JS interop must go through one Godot bridge helper and/or WebWalletService.

## Rule 3 — No unmanaged preset sprawl
v1 supports one preset only: `GlideWeb`.

## Rule 4 — No hidden environment assumptions
Every path, config item, and dependency needed by end users must be visible in docs or diagnostics.

## Rule 5 — Every slice must be demoable
If a slice cannot be shown working inside a real Godot project, it is too abstract.

---

# Manual Test Matrix

## Test Project Types

Maintain at least two local Godot test projects:

### A. Minimal blank project
Used to test installation and export behavior.

### B. Demo runtime project
Used to test runtime WalletService and login/tx flows.

## Required recurring tests

After each slice:

1. clean import test
2. plugin enable test
3. panel visibility test
4. build test
5. exported page opens
6. relevant runtime flow test for current slice

---

# Work Order Template

Use this exact format for every future work order.

## Title
Short, specific, single-purpose.

## Objective
What this work order achieves.

## Scope
What is included.

## Out of Scope
What must not be touched.

## Files likely affected
List expected files/directories.

## Instructions
Concrete implementation steps.

## Deliverables
Exact expected outputs.

## Acceptance Criteria
Binary pass/fail outcomes.

## Manual Test
Exact local test procedure.

## Notes
Risks, assumptions, follow-up dependencies.

---

# Recommended Initial Execution Order

1. 1.1 addon skeleton
2. 1.2 editor entry point
3. 1.3 shell template
4. 1.4 managed preset constant
5. 1.5 output dir
6. 1.6 validator
7. 1.7 validate button
8. 1.8 preset discovery
9. 1.9 build stub
10. 1.10 real export
11. 1.11 custom shell path
12. 1.12 stabilize

Then continue slice by slice in order.

---

# Definition of Done for v1

v1 is done when a third-party Godot developer can:

1. install the addon,
2. enable the plugin,
3. configure Privy + output settings,
4. click Build Web or Build PWA,
5. run the exported app,
6. trigger Privy embedded login from inside the game through WalletService,
7. receive wallet address/session state in Godot,
8. use the documented transaction handoff path,
9. do all of the above without manually wiring the HTML shell or JS bridge themselves.
