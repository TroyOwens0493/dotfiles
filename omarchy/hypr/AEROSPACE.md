# AeroSpace controls on Hyprland

The settings follow `macos/aerospace/aerospace.toml`. The active files in
`~/.config/hypr/` link to this directory.

## Keyboard

This keyboard sends PC key signals but has Mac keycaps. The key check found:

| Keycap | Signal from keyboard | Function after remap |
| --- | --- | --- |
| Option | Super / Windows | Option (`ALT` in Hyprland) |
| Command, beside Space | Alt | Command (`SUPER` in Hyprland) |
| Caps Lock | Caps Lock | Control |
| Left Control | Control | Caps Lock |

`input.lua` sets `ctrl:swapcaps,altwin:swap_alt_win,shift:both_capslock_cancel`.
The Caps Lock / Control swap is retained. The Alt / Super swap applies on both
sides of the keyboard. If a future keyboard sends Mac key signals, remove
`altwin:swap_alt_win` before using it.

## Window controls

| Shortcut | Action |
| --- | --- |
| Option+Space | Open the launcher; same physical keys as before |
| Option+H/J/K/L | Focus left/down/up/right |
| Option+Shift+H/J/K/L | Move the window left/down/up/right |
| Option+1–9 | Select a numbered workspace |
| Option+A–Z, except H/J/K/L | Select a letter workspace |
| Add Shift to a workspace shortcut | Send the window there; keep the current workspace |
| Option+Tab | Return to the previous workspace |
| Option+Shift+Tab | Move this workspace to the next monitor |
| Option+/ | Select tiles, or toggle horizontal/vertical tiles |
| Option+, | Select accordion, or toggle horizontal/vertical accordion |
| Option+Shift+- / Option+Shift+= | Reduce/increase size by 50 pixels |
| Option+Shift+; | Enter service mode |

Service mode accepts one command, then returns to normal mode:

| Key in service mode | Action |
| --- | --- |
| Escape | Reload the config |
| R | Flatten and balance the workspace tree |
| F | Toggle floating/tiling |
| Backspace | Close other windows on the current workspace |
| Option+Shift+H/J/K/L | Join this window with the node in that direction |

New workspaces use a horizontal row on wide work areas and a vertical column
on tall work areas. Joined containers use the opposite orientation. Accordion
uses a 10-pixel layout offset; Hyprland also applies window borders and gaps.
Mouse hover does not change window focus. Monitor focus moves the cursor to
the monitor center only when the cursor is outside that monitor.

Accordion clicks follow the visible window, including exposed background
strips. Hyprland 0.56 checks tiled windows from bottom to top even though it
draws the focused tile on top. Non-consuming mouse bindings correct that order
before each click; the app receives the original button event and modifiers.

Numbers use workspace IDs 1–9. Letter workspaces use IDs 10–31. Tree structure,
orientation, accordion mode, and resized proportions are saved under
`~/.local/state/omarchy/workspace-layouts/` (or `$XDG_STATE_HOME`). They survive
config reloads for windows that remain open. New windows reset size proportions.

## App shortcuts

`macos-keys.lua` maps common Command shortcuts to each Linux app's shortcuts.
Command+C/V/X/Z, Shift+Command+Z, Command+T/W/N, Command+S/F/L, tab numbers,
zoom, and Command+arrow text movement are included. Option+arrows moves by
word. Add Shift to select text. Command+Tab switches apps across workspaces;
Command+grave switches windows of the same app. Control+Command+F toggles
full screen. Command+Q sends normal close requests to this app's windows.

Terminals use Control+Insert for copy and Shift+Insert for paste. In Ghostty,
Command+T/W/N sends Control+Shift+T/W/N. Foot and Alacritty have no tabs, so
Command+T/N opens a terminal and Command+W closes its window.

These bindings replace conflicting Omarchy window controls, workspace controls,
and app launch shortcuts. Examples: Command+T was floating/tiling, Command+F
was full screen, Command+L changed layout, Command+K opened keybinding help,
and Command+number selected a workspace. Command+, now requests app preferences;
Command+/ sends the app's comment shortcut. The Omarchy system menu remains
on Command+Escape. Command+Control shortcuts retain most system controls.

App support can differ. The bridge does not add macOS menus, app hiding, or
minimization. Hyprland's Lua layout API does not pass mouse resize deltas to
this layout; use the resize keys for tiled windows. Floating windows retain
native mouse resizing. Native Hyprland groups remain separate from the tree.

## Reload

After a config change:

```sh
hyprctl reload
hyprctl configerrors
```

The change was checked with temporary live windows for tiles, nested joins,
focus, accordion, resize, and layout persistence across reloads. The temporary
windows were closed after the checks.
