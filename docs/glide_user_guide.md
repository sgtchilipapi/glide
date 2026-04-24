# Glide User Guide

## Purpose

Glide is a Godot addon for building wallet-enabled Web exports.

Current implemented scope:
- install addon into a Godot project
- enable the plugin
- use the `Glide Web3` bottom panel
- validate setup
- detect managed Web export preset `GlideWeb`
- trigger a real Web export command using the managed preset
- configure the managed preset to use the Glide custom Web shell during build
- load the shell bridge before Godot boot and stop boot if the bridge is missing
- include a Godot-side JS bridge helper for future shell calls
- include a `Ping Shell` button in the plugin UI that checks bridge availability through the Godot JS bridge helper
- include a runtime demo scene for web builds:
  - `addons/glide_web3/tests/bridge_ping_demo.tscn`
- create a persistent plugin config file with default fields
- edit and save plugin config from the Glide panel
- reload saved config on plugin startup
- show preset, output path, and shell path in the panel
- use saved config values for managed build output path and app title

Not implemented yet:
- automatic preset creation
- Phantom login flow
- runtime wallet API
- PWA packaging

## Current Requirements

Before using Glide at this stage, the Godot project must have:

1. a Web export preset named exactly `GlideWeb`
2. Godot Web export templates installed for the exact Godot editor version in use
3. the Glide addon copied into the project under `addons/glide_web3`

If Web export templates are missing, Godot export will fail even if Glide is installed correctly.

## Install Glide Into a Project

Copy this folder:

```text
godot-addon/addons/glide_web3
```

Into your Godot project here:

```text
your-project/
  addons/
    glide_web3/
```

Expected project shape:

```text
your-project/
  project.godot
  export_presets.cfg
  addons/
    glide_web3/
      plugin.cfg
      plugin.gd
      config/
      editor/
      ui/
      web_shell/
```

## Enable the Plugin

In Godot:

1. open the project
2. go to `Project > Project Settings > Plugins`
3. enable `Glide Web3`

After enabling, a bottom panel tab named `Glide Web3` should appear.

## Open the Glide Panel

The Glide UI is in the Godot bottom panel area.

You should see:
- preset status
- output path
- shell path
- config fields
- `Save Config`
- `Validate Setup`
- `Build Web`
- `Ping Shell`

## Create the Managed Preset

At this stage, Glide does not auto-create the export preset.

You must create it manually:

1. open `Project > Export`
2. add a `Web` preset if one does not exist
3. set the preset name to exactly `GlideWeb`
4. save the preset

Glide checks for that exact preset name.

## Validate Setup

Click `Validate Setup` in the `Glide Web3` panel.

Current validation checks:
- shell HTML exists
- shell bridge exists
- output path resolves
- Web export platform exists in the editor
- required Web export templates exist for the current Godot editor version
- managed preset `GlideWeb` exists

Expected success output includes lines like:

```text
Validation passed.
OK: Web shell files found.
OK: Output path is resolvable.
OK: Web export platform is available in the editor.
OK: Web export templates found in: ...
OK: Managed preset found: GlideWeb
```

If the preset is missing, validation will warn:

```text
WARNING: Managed preset missing: GlideWeb
```

## Build Web

Click `Build Web` in the `Glide Web3` panel.

Current build behavior:
- runs validation
- checks that preset `GlideWeb` exists
- uses the saved `Output Dir` config value
- creates the configured output directory if needed
- calls the Godot editor executable in headless mode
- runs `--export-release GlideWeb`
- copies `bridge.js` into the output folder
- rewrites exported HTML title from saved `App Title`

Current default target output file:

```text
res://build/web/index.html
```

## Expected Build Output

If export works, Godot should place Web export files in:

```text
build/web/
```

Typical files:
- `index.html`
- `.js`
- `.wasm`
- `.pck`

Exact file set depends on Godot version and export settings.

## Custom Shell Behavior

During build, Glide now configures the managed preset to use:

```text
res://addons/glide_web3/web_shell/index.html
```

Glide also copies:

```text
addons/glide_web3/web_shell/bridge.js
```

into the export output folder so the exported HTML can load it.

Important:
- these post-export steps are part of Glide's managed `Build Web` flow
- a raw standalone Godot CLI export is not the same thing and will not, by itself, copy `bridge.js` or apply the saved app title

## Slice 2 Runtime Ping Test

For the real Godot-to-shell ping test, use this demo scene:

```text
addons/glide_web3/tests/bridge_ping_demo.tscn
```

Test flow:

1. open the demo scene in Godot
2. temporarily make it the main scene for a Web test build, or instance it into a test scene
3. build Web with Glide
4. open the exported app in a browser
5. click `Ping Shell`

Expected runtime result:

```text
JS bridge call succeeded.
Method: ping
Result: {"ok":true,"source":"shell"}
```

Important:
- the plugin panel `Ping Shell` button is only a bridge-availability check
- the real end-to-end ping must be tested in the exported Web app using the runtime demo scene

## Known Failure Case

If `Build Web` fails with missing export templates, install them in Godot:

1. open `Editor > Manage Export Templates`
2. install templates for the exact Godot version
3. run `Build Web` again

Example failure:

```text
ERROR: Missing required Web export templates for Godot <godot-version>
ERROR: Missing template: .../export_templates/<godot-version>/web_nothreads_release.zip
```

## Current Files Used by Glide

Main addon files:
- `addons/glide_web3/plugin.cfg`
- `addons/glide_web3/plugin.gd`

UI:
- `addons/glide_web3/plugin.gd`

Constants:
- `addons/glide_web3/config/glide_constants.gd`

Persistent plugin config:
- `addons/glide_web3/config/glide_plugin_config.gd`
- `glide/glide_plugin_config.cfg` after first plugin load

Current panel config controls:
- `Backend URL`
- `Output Dir`
- `App Title`
- `Enable PWA`
- `Save Config`

Current active editor logic:
- `addons/glide_web3/plugin.gd`

Runtime bridge helper:
- `addons/glide_web3/runtime/js_bridge.gd`

Runtime demo scene:
- `addons/glide_web3/tests/bridge_ping_demo.tscn`
- `addons/glide_web3/tests/bridge_ping_demo.gd`

Shell files:
- `addons/glide_web3/web_shell/index.html`
- `addons/glide_web3/web_shell/bridge.js`

## Current Development Status

Completed up to:
- Slice 3 complete

Next planned item:
- Slice 4.1 WalletService interface
