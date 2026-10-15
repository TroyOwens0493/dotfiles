-- SUPER is the key labelled Command; ALT is the key labelled Option.
-- Keep CTRL separate so terminal Ctrl+C/Ctrl+Z still work normally.
local M = {}
-- The key labelled Option was PC Super before the modifier swap. Preserve
-- its existing Option+Space launcher shortcut in physical keyboard terms.
hl.unbind("ALT + SPACE")
o.bind("ALT + SPACE", "Option: launcher", "omarchy-menu toggle")

local function terminal()
  local window = hl.get_active_window()
  for _, tag in ipairs(window and window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then return true end
  end
  return false
end

-- Use Omarchy's down/up workaround to avoid stuck synthetic modifiers.
local function send(mods, key)
  hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
  end, { timeout = 50, type = "oneshot" })
end

function M.shortcut(key, shifted)
  local is_terminal = terminal()
  if is_terminal and not shifted and key == "C" then send("CTRL", "Insert")
  elseif is_terminal and not shifted and key == "V" then send("SHIFT", "Insert")
  elseif is_terminal and (key == "T" or key == "W" or key == "N") then
    local window = hl.get_active_window()
    -- Foot and Alacritty have no tabs; use a new terminal or close its window.
    if window.class == "foot" or window.class == "org.codeberg.dnkl.foot" or window.class == "Alacritty" then
      if key == "W" then hl.dispatch(hl.dsp.window.close())
      else hl.exec_cmd("omarchy-launch-terminal") end
    else send("CTRL SHIFT", key) end
  else send(shifted and "CTRL SHIFT" or "CTRL", key) end
end

-- Override only the chords needed by applications; retain Omarchy's system
-- menu, media keys, and Ctrl+Command system shortcuts.
local names = {
  A = "Select all", B = "Bold / bookmarks", C = "Copy", D = "Bookmark",
  E = "App shortcut", F = "Find", G = "Find next", I = "Italic / app shortcut",
  J = "Downloads / app shortcut", K = "App shortcut", L = "Address bar",
  N = "New window", O = "Open", P = "Print", R = "Reload", S = "Save",
  T = "New tab", U = "App shortcut", V = "Paste", W = "Close tab",
  X = "Cut", Y = "Redo / app shortcut", Z = "Undo",
}
for key, description in pairs(names) do
  for _, shifted in ipairs({ false, true }) do
    local chord = "SUPER + " .. (shifted and "SHIFT + " or "") .. key
    hl.unbind(chord)
    o.bind(chord, "Command: " .. description .. (shifted and " (Shift)" or ""), function() M.shortcut(key, shifted) end)
  end
end

-- Native Omarchy binds numbers by physical keycode, so remove those too.
for number = 0, 9 do
  local code = number == 0 and 19 or number + 9
  for _, shift in ipairs({ "", "SHIFT + " }) do
    hl.unbind("SUPER + " .. shift .. "code:" .. code)
    hl.unbind("SUPER + " .. shift .. number)
    o.bind("SUPER + " .. shift .. number, "Command: select tab " .. number, function()
      send(shift == "" and "CTRL" or "CTRL SHIFT", tostring(number))
    end)
  end
end
for _, key in ipairs({ "minus", "equal" }) do
  local code = key == "minus" and 20 or 21
  for _, shift in ipairs({ "", "SHIFT + " }) do
    hl.unbind("SUPER + " .. shift .. "code:" .. code)
    hl.unbind("SUPER + " .. shift .. key)
    o.bind("SUPER + " .. shift .. key, "Command: zoom", function()
      send(shift == "" and "CTRL" or "CTRL SHIFT", key)
    end, { repeating = true })
  end
end

for chord, shortcut in pairs({
  ["SUPER + slash"] = { "CTRL", "slash", "Comment selection" },
  ["SUPER + comma"] = { "CTRL", "comma", "App preferences" },
  ["SUPER + bracketleft"] = { "ALT", "Left", "Back" },
  ["SUPER + bracketright"] = { "ALT", "Right", "Forward" },
  ["SUPER + SHIFT + bracketleft"] = { "CTRL SHIFT", "Tab", "Previous tab" },
  ["SUPER + SHIFT + bracketright"] = { "CTRL", "Tab", "Next tab" },
  ["SUPER + ALT + Left"] = { "CTRL", "Page_Up", "Previous tab" },
  ["SUPER + ALT + Right"] = { "CTRL", "Page_Down", "Next tab" },
}) do
  -- Default slash/arrow bindings use uppercase keysyms.
  hl.unbind(chord:gsub("slash", "SLASH"):gsub("Left", "LEFT"):gsub("Right", "RIGHT"))
  hl.unbind(chord)
  o.bind(chord, "Command: " .. shortcut[3], function() send(shortcut[1], shortcut[2]) end)
end

for _, shifted in ipairs({ false, true }) do
  local prefix = "SUPER + " .. (shifted and "SHIFT + " or "")
  for key, target in pairs({ Left = "Home", Right = "End", Up = "Home", Down = "End" }) do
    hl.unbind(prefix .. key:upper())
    local vertical = key == "Up" or key == "Down"
    o.bind(prefix .. key, "Command: move/select to " .. key:lower() .. " edge", function()
      local mods = vertical and "CTRL" or ""
      if shifted then mods = mods == "" and "SHIFT" or mods .. " SHIFT" end
      send(mods, target)
    end, { repeating = true })
  end
end
hl.unbind("SUPER + BACKSPACE")
o.bind("SUPER + BackSpace", "Command: delete to start of line", function()
  if terminal() then send("CTRL", "U")
  else
    -- Select first, then delete after the synthetic Shift key is released.
    send("SHIFT", "Home")
    hl.timer(function() send("", "BackSpace") end, { timeout = 65, type = "oneshot" })
  end
end, { repeating = true })

-- Keep Option word navigation available; AeroSpace reserves Option+letters.
for _, shifted in ipairs({ false, true }) do
  for _, key in ipairs({ "Left", "Right", "BackSpace", "Delete" }) do
    local chord = "ALT + " .. (shifted and "SHIFT + " or "") .. key
    hl.unbind(chord)
    o.bind(chord, "Option: word navigation/delete", function()
      if terminal() and key == "BackSpace" then send("CTRL", "W")
      else send(shifted and "CTRL SHIFT" or "CTRL", key) end
    end, { repeating = true })
  end
end

function M.quit()
  local current = hl.get_active_window()
  if not current or current.class == "" then return end
  for _, window in ipairs(hl.get_windows({ mapped = true })) do
    if window.class == current.class then
      hl.dispatch(hl.dsp.window.close({ window = "address:" .. window.address }))
    end
  end
end
hl.unbind("SUPER + Q")
o.bind("SUPER + Q", "Command: close this app's windows", M.quit)
-- macOS Control+Command+F toggles full screen.
hl.unbind("SUPER + CTRL + F")
o.bind("SUPER + CTRL + F", "Command: full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

local cycle
function M.switch_app(backward, same_app)
  local current = hl.get_active_window()
  if not cycle or cycle.same_app ~= same_app then
    local windows = hl.get_windows({ mapped = true })
    table.sort(windows, function(a, b) return a.focus_history_id < b.focus_history_id end)
    local seen = {}
    cycle = { windows = {}, index = 1, same_app = same_app }
    for _, window in ipairs(windows) do
      if (same_app and current and window.class == current.class) or (not same_app and not seen[window.class]) then
        cycle.windows[#cycle.windows + 1] = window.address
        seen[window.class] = true
      end
    end
  end
  local count = #cycle.windows
  if count == 0 then return end
  cycle.index = (cycle.index - 1 + (backward and -1 or 1)) % count + 1
  local window = hl.get_window("address:" .. cycle.windows[cycle.index])
  if window then
    hl.dispatch(hl.dsp.focus({ window = "address:" .. window.address }))
    hl.dispatch(hl.dsp.window.bring_to_top())
  end
end
for _, shifted in ipairs({ false, true }) do
  for _, key in ipairs({ "TAB", "grave" }) do
    local chord = "SUPER + " .. (shifted and "SHIFT + " or "") .. key
    hl.unbind(chord)
    o.bind(chord, key == "TAB" and "Command: switch apps" or "Command: switch this app's windows", function()
      M.switch_app(shifted, key == "grave")
    end)
  end
end
hl.on("input.keyboard.key", function(code, _, state)
  -- Physical Alt or Super can be Command, depending on the keyboard mode.
  if state == 0 and (code == 64 or code == 108 or code == 133 or code == 134) then cycle = nil end
end)

return M
