# Glide

Glide is a toolkit for building wallet-enabled web games for the Godot game engine.

Current status:

- active Web auth provider is Privy
- active shell bundle is built from `web-shell/` into `godot-addon/addons/glide_web3/web_shell/bridge.js`
- the Godot plugin now manages Privy app/client/origin/callback config and injects it into the exported shell at build time
- legacy Phantom code is archived under `legacy/phantom/`

Current developer flow:

1. copy `godot-addon/addons/glide_web3` into a Godot project
2. enable `Glide Web3`
3. configure Privy fields in the bottom panel
4. save config
5. validate setup
6. build Web
7. serve the build over HTTP

Main docs:

- user guide: `docs/glide_user_guide.md`
- implementation plan: `docs/bootstrap/glide_implementation_plan.md`
- bridge spec: `docs/glide_bridge_interface_spec.md`
