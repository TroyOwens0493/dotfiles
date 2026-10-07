# AeroSpace-style window management

`aerospace.lua` is loaded by `hyprland.lua`. It uses Hyprland's built-in Lua
layout API; no compositor plugin is needed.

- Alt+1–9 selects numbered workspaces. Alt+letter selects independent letter
  workspaces. H/J/K/L are reserved for navigation, as in the macOS config.
- Add Shift to a workspace shortcut to send the focused window there.
- Alt+H/J/K/L focuses left/down/up/right. Add Shift to reorder tiled windows.
- New tiled windows share the available space equally. Wide work areas start
  with a horizontal row; tall work areas start with a vertical column.
- Alt+/ toggles horizontal/vertical tiles, or returns from another layout.
- Alt+Shift+- and Alt+Shift+= resize along the current tiling direction.
- Alt+, retains the existing monocle approximation of overlapping windows.

Numbers use workspace IDs 1–9. Letters use IDs 10–31 with letter names, so
Omarchy's existing Super+number shortcuts also address the numbered workspaces.
Mouse hover does not change keyboard focus.

Tile orientation is saved per workspace in
`$XDG_STATE_HOME/omarchy/workspace-layouts/<id>.orientation` (default state home:
`~/.local/state`). Adding/removing windows resets their sizes to equal shares.
Resized proportions are held in memory and reset on config reload.

This implements flat root tiles. It does not reproduce AeroSpace's nested
containers, join-with commands, or accordion layout. Hyprland 0.56.2's Lua
layout API does not forward mouse resize deltas to the provider; use the resize
shortcuts for tiled windows. Floating windows retain native resizing.

Run `lua omarchy/tests/aerospace-layout.lua` from the repository root for the
layout and binding checks. Live three-window checks also covered horizontal
and vertical arrangement, orientation persistence across reload, and separate
numbered/letter workspaces. Live focus checks were blocked by the locked session.
