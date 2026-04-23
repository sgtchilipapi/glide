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
- `Validate Setup`
- `Build Web`

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
- creates `res://build/web/` if needed
- calls the Godot editor executable in headless mode
- runs `--export-release GlideWeb`

Current target output file:

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

Current active editor logic:
- `addons/glide_web3/plugin.gd`

Shell files:
- `addons/glide_web3/web_shell/index.html`
- `addons/glide_web3/web_shell/bridge.js`

## Current Development Status

Completed up to:
- 1.12 Slice 1 stabilization

Next planned item:
- Slice 2.1 bridge interface and shell ping path
