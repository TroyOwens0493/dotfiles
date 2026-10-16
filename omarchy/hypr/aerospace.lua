-- AeroSpace-style navigation. H/J/K/L are reserved for windows.
local letters = "ABCDEFGIMNOPQRSTUVWXYZ"
local M = {}
local layout_rules = {}
local state_home = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")

-- Layout geometry is kept separate from compositor commands.
local layouts_dir = state_home .. "/omarchy/workspace-layouts"
local function tree_file(id) return layouts_dir .. "/" .. id .. ".tree" end
local function encode(node)
  if node.id then return string.format("{id=%d,weight=%.17g}", node.id, node.weight) end
  local children = {}
  for _, child in ipairs(node.children) do children[#children + 1] = encode(child) end
  return string.format("{orientation=%q,mode=%q,weight=%.17g,children={%s}}",
    node.orientation, node.mode, node.weight, table.concat(children, ","))
end
local function load_tree(id)
  local file = io.open(tree_file(id), "r")
  if not file then return end
  local data = file:read(262145); file:close()
  if not data or #data > 262144 then return end
  -- The format contains data only. Reject code before loading in an empty env.
  if data:find("[^%w%s{}=,%.%+%-\"_]") then return end
  local chunk = load("return " .. data, tree_file(id), "t", {})
  if not chunk then return end
  local ok, root = pcall(chunk)
  if not ok then return end
  local seen, count = {}, 0
  local function valid(node, depth)
    count = count + 1
    if type(node) ~= "table" or depth > 64 or count > 1024 or type(node.weight) ~= "number"
        or node.weight <= 0 or node.weight > 1e12 then return false end
    if node.id then
      if type(node.id) ~= "number" or node.id % 1 ~= 0 or seen[node.id] then return false end
      seen[node.id] = true; return true
    end
    if node.orientation ~= "auto" and node.orientation ~= "horizontal" and node.orientation ~= "vertical" then return false end
    if node.mode ~= "tiles" and node.mode ~= "accordion" or type(node.children) ~= "table" then return false end
    for _, child in ipairs(node.children) do if not valid(child, depth + 1) then return false end end
    return true
  end
  if valid(root, 1) and root.children then return root end
end
local function save_tree(id, root)
  local file = io.open(tree_file(id), "w")
  if file then file:write(encode(root), "\n"); file:close() end
end
local provider = require("hypr.aerospace-layout").new(function(id)
  local file = io.open(layouts_dir .. "/" .. id .. ".orientation", "r")
  local value = file and file:read("*l") or "auto"
  if file then file:close() end
  return (value == "horizontal" or value == "vertical") and value or "auto"
end, function(id, orientation)
  local file, err = io.open(layouts_dir .. "/" .. id .. ".orientation", "w")
  if file then file:write(orientation, "\n"); file:close()
  else hl.notification.create({ text = "Could not save tile orientation: " .. tostring(err), icon = "error" }) end
end, load_tree, save_tree)
hl.layout.register("aerospace", provider)

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
  -- Run after the compositor has populated the replacement layout provider.
  hl.timer(provider.finish_restore, { timeout = 200, type = "oneshot" })
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
  if ws and ws.tiled_layout == "lua:aerospace" and window and not window.floating then
    provider.activate(window)
    local neighbor = provider.neighbor(ws.id, direction)
    if neighbor then
      hl.dispatch(hl.dsp.focus({ window = "address:" .. neighbor.address }))
      hl.dispatch(hl.dsp.window.bring_to_top())
    else
      -- At a tree edge, native focus can cross to the next monitor.
      hl.dispatch(hl.dsp.focus({ monitor = direction }))
    end
  elseif ws and ws.tiled_layout == "monocle" and (not window or not window.floating) then
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
    function() M.move(direction) end, { repeating = true })
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
o.bind("ALT + comma", "Accordion / toggle horizontal and vertical", function()
  local ws = hl.get_active_special_workspace() or hl.get_active_workspace()
  if ws and ws.tiled_layout ~= "lua:aerospace" then M.set_layout("lua:aerospace") end
  hl.dispatch(hl.dsp.layout("accordion"))
  hl.dispatch(hl.dsp.window.bring_to_top())
end)
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

function M.move(direction)
  local window = hl.get_active_window()
  local ws = hl.get_active_special_workspace() or hl.get_active_workspace()
  if window and not window.floating and ws and ws.tiled_layout == "lua:aerospace" then
    hl.dispatch(hl.dsp.layout("move " .. direction))
  else
    hl.dispatch(hl.dsp.window.move({ direction = direction, group_aware = true }))
  end
end

function M.flatten()
  local ws = hl.get_active_special_workspace() or hl.get_active_workspace()
  if ws and ws.tiled_layout ~= "lua:aerospace" then M.set_layout("lua:aerospace") end
  hl.dispatch(hl.dsp.layout("flatten"))
end

function M.close_others()
  local current = hl.get_active_window()
  local ws = hl.get_active_special_workspace() or hl.get_active_workspace()
  if not current or not ws then return end
  for _, window in ipairs(ws:get_windows()) do
    if window.stable_id ~= current.stable_id then
      hl.dispatch(hl.dsp.window.close({ window = "address:" .. window.address }))
    end
  end
end

-- AeroSpace service mode: every command returns to normal mode.
o.bind("ALT + SHIFT + semicolon", "AeroSpace service mode", hl.dsp.submap("aerospace-service"))
hl.define_submap("aerospace-service", "reset", function()
  o.bind("Escape", "Reload config and leave service mode", "hyprctl reload")
  o.bind("R", "Flatten workspace tree", M.flatten)
  o.bind("F", "Toggle floating/tiling", hl.dsp.window.float({ action = "toggle" }))
  o.bind("BackSpace", "Close other windows on this workspace", M.close_others)
  for key, direction in pairs({ H = "l", J = "d", K = "u", L = "r" }) do
    o.bind("ALT + SHIFT + " .. key, "Join with window " .. direction, function()
      hl.dispatch(hl.dsp.layout("join " .. direction))
    end)
  end
end)

-- Match monitor-lazy-center: move the cursor only if it is outside the monitor.
hl.on("monitor.focused", function(monitor)
  if not monitor then return end
  local cursor = hl.get_cursor_pos()
  local width, height = monitor.width / monitor.scale, monitor.height / monitor.scale
  if cursor and (cursor.x < monitor.x or cursor.y < monitor.y or cursor.x >= monitor.x + width or cursor.y >= monitor.y + height) then
    hl.dispatch(hl.dsp.cursor.move({ x = monitor.x + width / 2, y = monitor.y + height / 2 }))
  end
end)
hl.on("window.active", function(window)
  provider.activate(window)
  if window and provider.is_accordion(window) then
    hl.dispatch(hl.dsp.window.bring_to_top({ window = "address:" .. window.address }))
  end
end)

-- Hyprland 0.56 draws the active tile last, but hit-tests tiles from bottom
-- to top. Before native click handling, put the visible accordion tile first
-- in that hit-test order. Native handling then delivers the original click
-- and raises the window again, so this must run on every button press.
function M.prepare_pointer_click()
  local cursor = hl.get_cursor_pos()
  local monitor = cursor and hl.get_monitor_at(cursor)
  local ws = monitor and (monitor.active_special_workspace or monitor.active_workspace)
  if not ws or ws.tiled_layout ~= "lua:aerospace" then return end
  local windows = hl.get_windows({ workspace = ws })
  local function contains(window)
    if not window.mapped or window.hidden or not window.accepts_input then return false end
    local at, size = window.at, window.size
    return cursor.x >= at.x and cursor.y >= at.y
      and cursor.x < at.x + size.x and cursor.y < at.y + size.y
  end
  local active, top = hl.get_active_window(), nil
  for i = #windows, 1, -1 do
    local window = windows[i]
    if window.fullscreen ~= 0 then return end
    if contains(window) then
      if window.floating then return end -- Native floating hit-testing is correct.
      if not top then top = window end
      if active and window.address == active.address then top = window end
    end
  end
  if top and provider.is_accordion(top) then
    hl.dispatch(hl.dsp.window.alter_zorder({ mode = "bottom", window = "address:" .. top.address }))
  end
end
for button = 272, 279 do
  hl.bind("mouse:" .. button, M.prepare_pointer_click, {
    description = "AeroSpace: click the visible accordion window",
    non_consuming = true, ignore_mods = true, submap_universal = true,
  })
end

return M
