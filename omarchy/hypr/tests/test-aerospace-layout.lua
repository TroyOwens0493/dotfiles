-- Run from any directory: lua /path/to/tests/test-aerospace-layout.lua
local source = debug.getinfo(1, "S").source:sub(2)
local layout = dofile(source:match("^(.*)/") .. "/../aerospace-layout.lua")
local steps, current = 0, ""
local function scenario(seed)
  math.randomseed(seed)
  local saved, windows, placed = nil, {}, {}
  local function clone(node)
    if type(node) ~= "table" then return node end
    local result = {}; for k, v in pairs(node) do result[k] = clone(v) end; return result
  end
  local function provider()
    return layout.new(function() return "auto" end, function() end,
      function() return clone(saved) end, function(_, root) saved = clone(root) end)
  end
  local p = provider()
  local ctx = { area = { x = 0, y = 0, w = 1600, h = 900 }, targets = {} }
  local next_id, checking = 0, false
  local function recalc()
    ctx.targets, placed, checking = {}, {}, true
    for _, window in ipairs(windows) do
      ctx.targets[#ctx.targets + 1] = { window = window, place = function(_, box)
        if checking then assert(not placed[window.stable_id], "window placed twice") end
        for _, key in ipairs({"x", "y", "w", "h"}) do
          assert(type(box[key]) == "number" and box[key] == box[key] and math.abs(box[key]) < 1e7, "invalid geometry")
        end
        assert(box.w > 0 and box.h > 0, "nonpositive geometry")
        placed[window.stable_id] = box
      end }
    end
    p.recalculate(ctx)
    for _, w in ipairs(windows) do assert(placed[w.stable_id], "window not placed") end
    checking = false
  end
  local function activate(index)
    for i, w in ipairs(windows) do w.active = i == index end
    if windows[index] then p.activate(windows[index]) end
  end
  for i = 1, 1000 do
    steps = steps + 1
    local action = math.random(1, 12)
    current = string.format("seed=%d step=%d action=%d windows=%d", seed, i, action, #windows)
    if action <= 2 or #windows == 0 then
      if #windows < 12 then
        next_id = next_id + 1
        windows[#windows + 1] = { stable_id = next_id, workspace = { id = 1 }, focus_history_id = next_id }
        activate(#windows)
      end
    elseif action == 3 then table.remove(windows, math.random(#windows)); activate(1)
    elseif action == 4 then activate(math.random(#windows))
    elseif action == 5 then
      p = provider()
      local all = windows; windows = {}
      for _, w in ipairs(all) do windows[#windows + 1] = w; recalc() end
      p.finish_restore()
    else
      local command = ({"toggle", "accordion", "flatten", "resize 50", "resize -50", "move ", "join "})[action - 5]
      if action >= 11 then command = command .. ({"l", "r", "u", "d"})[math.random(4)] end
      current = current .. " command=" .. command
      p.layout_msg(ctx, command)
    end
    recalc()
    for _, direction in ipairs({"l", "r", "u", "d"}) do
      local neighbor = p.neighbor(1, direction)
      if neighbor then assert(placed[neighbor.stable_id], "neighbor is missing") end
    end
  end
end
local ok, err = xpcall(function() for seed = 1, 100 do scenario(seed) end end, debug.traceback)
if not ok then io.stderr:write(current .. "\n" .. err .. "\n"); os.exit(1) end
print("PASS: " .. steps .. " layout operations across 100 deterministic seeds")
