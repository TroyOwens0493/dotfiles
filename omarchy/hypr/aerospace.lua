-- AeroSpace-style navigation. H/J/K/L are reserved for windows.
local letters = "ABCDEFGIMNOPQRSTUVWXYZ"
local M = {}
local layout_rules = {}
local state_home = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")

-- Flat AeroSpace tiles: every window shares the row/column. Unlike dwindle,
-- opening a third window does not split just one of the existing windows.
-- This implements root tiles, not AeroSpace's nested containers or accordion.
local tile_states = {}
local function tile_state(ctx)
  local window = ctx.targets[1] and ctx.targets[1].window
  local ws = window and window.workspace
  if not ws then return end
  local state = tile_states[ws.id]
  if not state then
    local file = io.open(state_home .. "/omarchy/workspace-layouts/" .. ws.id .. ".orientation", "r")
    local orientation = file and file:read("*l") or "auto"
    if file then file:close() end
    if orientation ~= "horizontal" and orientation ~= "vertical" then orientation = "auto" end
    state = { weights = {}, orientation = orientation, workspace = ws.id }
  end
  tile_states[ws.id] = state
  local present, changed = {}, false
  for _, target in ipairs(ctx.targets) do
    local id = target.window.stable_id
    present[id] = true
    if not state.weights[id] then changed = true end
  end
  for id in pairs(state.weights) do
    if not present[id] then changed = true end
  end
  -- Rebalance when windows enter/leave; preserve sizes when merely reordered.
  if changed then
    state.weights = {}
    for id in pairs(present) do state.weights[id] = 1 end
  end
  return state
end

do
  local function horizontal(ctx)
    local orientation = tile_state(ctx).orientation
    return orientation == "horizontal" or (orientation == "auto" and ctx.area.w >= ctx.area.h)
  end
  hl.layout.register("aerospace", {
    recalculate = function(ctx)
      local state = tile_state(ctx)
      if not state then return end
      local total, offset = 0, 0
      for _, target in ipairs(ctx.targets) do total = total + state.weights[target.window.stable_id] end
      for _, target in ipairs(ctx.targets) do
        local fraction = state.weights[target.window.stable_id] / total
        local a = ctx.area
        if horizontal(ctx) then
          target:place({ x = a.x + offset * a.w, y = a.y, w = fraction * a.w, h = a.h })
        else
          target:place({ x = a.x, y = a.y + offset * a.h, w = a.w, h = fraction * a.h })
        end
        offset = offset + fraction
      end
    end,
    layout_msg = function(ctx, msg)
      local state = tile_state(ctx)
      if not state then return true end
      if msg == "toggle" then
        state.orientation = horizontal(ctx) and "vertical" or "horizontal"
        local path = state_home .. "/omarchy/workspace-layouts/" .. state.workspace .. ".orientation"
        local file, err = io.open(path, "w")
        if file then
          file:write(state.orientation, "\n")
          file:close()
        else
          hl.notification.create({ text = "Could not save tile orientation: " .. tostring(err), icon = "error" })
        end
        return true
      end
      local delta = tonumber(msg:match("^resize (%-?%d+)$"))
      if not delta then return "Expected toggle or resize <pixels>" end
      if #ctx.targets < 2 then return true end
      local total, active = 0, nil
      for i, target in ipairs(ctx.targets) do
        total = total + state.weights[target.window.stable_id]
        if target.window.active then active = i end
      end
      if not active then return true end
      local neighbor = active < #ctx.targets and active + 1 or active - 1
      local a = ctx.targets[active].window.stable_id
      local b = ctx.targets[neighbor].window.stable_id
      local extent = horizontal(ctx) and ctx.area.w or ctx.area.h
      local minimum = math.min(100 / extent * total, (state.weights[a] + state.weights[b]) / 4)
      local change = math.max(minimum - state.weights[a], math.min(delta / extent * total, state.weights[b] - minimum))
      state.weights[a], state.weights[b] = state.weights[a] + change, state.weights[b] - change
      return true
    end,
  })
end

hl.config({ general = { layout = "lua:aerospace" }, input = { follow_mouse = 0 } })

-- Keep real numbered workspaces 1-9; letters occupy IDs 10-31.
for id = 1, #letters do
  local letter = letters:sub(id, id)
  local workspace = tostring(id + 9)
  hl.workspace_rule({ workspace = workspace, default_name = letter })
  o.bind("ALT + " .. letter, "Switch to workspace " .. letter,
    hl.dsp.focus({ workspace = workspace }))
  -- Alt+Shift+D previously downloaded a video from a web app.
  if letter == "D" then hl.unbind("ALT + SHIFT + D") end
  o.bind("ALT + SHIFT + " .. letter, "Move window to workspace " .. letter,
    hl.dsp.window.move({ workspace = workspace, follow = false }))
end

-- Existing workspaces retain their names across reloads and ID changes.
hl.on("config.reloaded", function()
  for _, ws in ipairs(hl.get_workspaces()) do
    local letter = ws.id >= 10 and ws.id <= 9 + #letters and letters:sub(ws.id - 9, ws.id - 9)
    if letter and ws.name == tostring(ws.id) then
      hl.dispatch(hl.dsp.workspace.rename({ workspace = tostring(ws.id), name = letter }))
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

-- Punctuation keysyms are case-sensitive: COMMA does not match comma.
hl.unbind("ALT + COMMA")
o.bind("ALT + comma", "Overlap windows (monocle)", function() M.set_layout("monocle") end)
function M.toggle_tiles()
  local ws = hl.get_active_special_workspace() or hl.get_active_workspace()
  if not ws then return end
  if ws.tiled_layout == "lua:aerospace" then
    hl.dispatch(hl.dsp.layout("toggle"))
  else
    M.set_layout("lua:aerospace")
  end
end
hl.unbind("ALT + SLASH")
o.bind("ALT + slash", "Tile windows / toggle horizontal and vertical", M.toggle_tiles)

-- Numbers and letters are independent, matching the macOS config.
for id = 1, 9 do
  hl.workspace_rule({ workspace = tostring(id), default_name = tostring(id) })
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
function M.resize(delta)
  local window = hl.get_active_window()
  local ws = hl.get_active_special_workspace() or hl.get_active_workspace()
  if window and not window.floating and ws and ws.tiled_layout == "lua:aerospace" then
    hl.dispatch(hl.dsp.layout("resize " .. delta))
  else
    hl.dispatch(hl.dsp.window.resize({ x = delta, y = 0, relative = true }))
  end
end
hl.unbind("ALT + SHIFT + MINUS")
hl.unbind("ALT + SHIFT + EQUAL")
o.bind("ALT + SHIFT + minus", "Shrink window by 50 pixels", function() M.resize(-50) end, { repeating = true })
o.bind("ALT + SHIFT + equal", "Expand window by 50 pixels", function() M.resize(50) end, { repeating = true })

return M
