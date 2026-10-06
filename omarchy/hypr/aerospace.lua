-- AeroSpace-style navigation. H/J/K/L are reserved for windows.
local letters = "ABCDEFGIMNOPQRSTUVWXYZ"
local M = {}
local layout_rules = {}
local state_home = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")

for id = 1, #letters do
  local letter = letters:sub(id, id)
  local workspace = tostring(id)
  hl.workspace_rule({ workspace = workspace, default_name = letter })
  o.bind("ALT + " .. letter, "Switch to workspace " .. letter,
    hl.dsp.focus({ workspace = workspace }))
  -- Alt+Shift+D previously downloaded a video from a web app.
  if letter == "D" then hl.unbind("ALT + SHIFT + D") end
  o.bind("ALT + SHIFT + " .. letter, "Move window to workspace " .. letter,
    hl.dsp.window.move({ workspace = workspace, follow = false }))
end

-- Relabel existing numbered workspaces without moving their windows.
hl.on("config.reloaded", function()
  for _, ws in ipairs(hl.get_workspaces()) do
    if ws.id >= 1 and ws.id <= #letters and ws.name == tostring(ws.id) then
      hl.dispatch(hl.dsp.workspace.rename({
        workspace = tostring(ws.id), name = letters:sub(ws.id, ws.id),
      }))
    end
  end
end)

function M.focus(direction)
  local window = hl.get_active_window()
  local ws = hl.get_active_special_workspace() or hl.get_active_workspace()
  local backward = direction == "l" or direction == "u"
  if ws and ws.tiled_layout == "monocle" and (not window or not window.floating) then
    hl.dispatch(hl.dsp.layout(backward and "cycleprev" or "cyclenext"))
  elseif window and window.group and window.group.size > 1 and (direction == "l" or direction == "r") then
    hl.dispatch(backward and hl.dsp.group.prev() or hl.dsp.group.next())
  else
    hl.dispatch(hl.dsp.focus({ direction = direction }))
  end
end

for key, direction in pairs({ H = "l", J = "d", K = "u", L = "r" }) do
  o.bind("ALT + " .. key, "Focus window " .. direction, function() M.focus(direction) end,
    { repeating = true })
  -- Alt+Shift+L previously copied a web app's URL.
  if key == "L" then hl.unbind("ALT + SHIFT + L") end
  o.bind("ALT + SHIFT + " .. key, "Move window " .. direction,
    hl.dsp.window.move({ direction = direction, group_aware = true }), { repeating = true })
end

function M.set_layout(layout)
  local ws = hl.get_active_special_workspace() or hl.get_active_workspace()
  if not ws then return end
  local selector = ws.config_name
  if layout_rules[ws.id] then layout_rules[ws.id]:set_enabled(false) end
  layout_rules[ws.id] = hl.workspace_rule({ workspace = selector, layout = layout })
  -- Use Omarchy's existing per-workspace layout storage so reloads preserve it.
  local path = state_home .. "/omarchy/workspace-layouts/" .. ws.id .. ".lua"
  local file, err = io.open(path, "w")
  if file then
    file:write(string.format("hl.workspace_rule({ workspace = %q, layout = %q })\n", selector, layout))
    file:close()
  else
    hl.notification.create({ text = "Could not save workspace layout: " .. tostring(err), icon = "error" })
  end
end

o.bind("ALT + COMMA", "Overlap windows (monocle)", function() M.set_layout("monocle") end)
o.bind("ALT + SLASH", "Tile windows / change split orientation", function()
  local ws = hl.get_active_special_workspace() or hl.get_active_workspace()
  if ws and ws.tiled_layout == "dwindle" then
    hl.dispatch(hl.dsp.layout("togglesplit"))
  else
    M.set_layout("dwindle")
  end
end)

-- Numeric shortcuts refer to the existing numbered/lettered workspaces.
for id = 1, 9 do
  hl.unbind("ALT + " .. id)
  hl.unbind("ALT + SHIFT + " .. id)
  o.bind("ALT + " .. id, "Switch to workspace " .. id,
    hl.dsp.focus({ workspace = tostring(id) }))
  o.bind("ALT + SHIFT + " .. id, "Move window to workspace " .. id,
    hl.dsp.window.move({ workspace = tostring(id), follow = false }))
end

-- Replace Omarchy's next/previous-window shortcuts with AeroSpace behavior.
hl.unbind("ALT + TAB")
hl.unbind("ALT + SHIFT + TAB")
o.bind("ALT + TAB", "Previous workspace",
  hl.dsp.focus({ workspace = "previous" }))
o.bind("ALT + SHIFT + TAB", "Move workspace to next monitor",
  hl.dsp.workspace.move({ monitor = "+1" }))
o.bind("ALT + SHIFT + MINUS", "Shrink window by 50 pixels",
  hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
o.bind("ALT + SHIFT + EQUAL", "Expand window by 50 pixels",
  hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })

return M
