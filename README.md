# Glide

Glide is a toolkit for building wallet-enabled web games for the Godot game engine.

Current status: Glide now has explicit product-managed Phantom config fields in the plugin for App ID, Origin URL, and Callback URL, and the build path injects those values into the shell env while generating a callback page target.

Next checkpoint: enter real Phantom app configuration in Glide, rebuild with the managed build flow, and run the manual embedded-login validation.
