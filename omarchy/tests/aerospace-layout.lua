-- Run from the repository root: lua omarchy/tests/aerospace-layout.lua
-- Mock only compositor services; exercise the actual configured layout/bindings.
local providers, bindings, files = {}, {}, {}
local active, workspace, dispatched
local function command(kind)
  return function(args) return { kind = kind, args = args } end
end
hl = {
  layout = { register = function(name, provider) providers[name] = provider end },
  config = function() end,
  on = function() end,
  unbind = function() end,
  workspace_rule = function() return { set_enabled = function() end } end,
  get_active_window = function() return active end,
  get_active_workspace = function() return workspace end,
  get_active_special_workspace = function() end,
  dispatch = function(cmd) dispatched = cmd end,
  notification = { create = function() error("Unexpected save failure") end },
  dsp = {
    focus = command("focus"), layout = command("layout"),
    window = { move = command("move"), resize = command("resize") },
    workspace = { rename = command("rename"), move = command("move-workspace") },
    group = { prev = command("group-prev"), next = command("group-next") },
  },
}
o = { bind = function(key, _, action) bindings[key] = action end }
io.open = function(path, mode)
  if mode == "r" and not files[path] then return nil end
  return {
    read = function(_, format) return format == "*l" and files[path]:match("[^\n]*") or files[path] end,
    write = function(_, ...) files[path] = table.concat({...}) end,
    close = function() end,
  }
end
local M = dofile("omarchy/hypr/aerospace.lua")
local provider = providers.aerospace
local function context(id, width, height, count)
  local ws = { id = id, config_name = tostring(id), tiled_layout = "lua:aerospace" }
  local ctx = { area = { x = 10, y = 20, w = width, h = height }, targets = {} }
  for i = 1, count do
    ctx.targets[i] = {
      window = { stable_id = id * 100 + i, workspace = ws, active = i == 1 },
      place = function(self, box) self.box = box end,
    }
  end
  return ctx
end
local function near(a, b) assert(math.abs(a - b) < .001, tostring(a) .. " != " .. tostring(b)) end
local ctx = context(9001, 1200, 900, 3)
provider.recalculate(ctx)
for i, target in ipairs(ctx.targets) do
  near(target.box.w, 400); near(target.box.x, 10 + (i - 1) * 400)
  near(target.box.h, 900)
end
provider.layout_msg(ctx, "resize 50"); provider.recalculate(ctx)
near(ctx.targets[1].box.w, 450); near(ctx.targets[2].box.w, 350)
provider.layout_msg(ctx, "resize -5000"); provider.recalculate(ctx)
assert(ctx.targets[1].box.w >= 99.99)
near(ctx.targets[1].box.w + ctx.targets[2].box.w + ctx.targets[3].box.w, 1200)

-- Removing a window rebalances; engine reordering retains each window's size.
table.remove(ctx.targets, 3); provider.recalculate(ctx)
near(ctx.targets[1].box.w, 600); near(ctx.targets[2].box.w, 600)
provider.layout_msg(ctx, "resize 50"); provider.recalculate(ctx)
ctx.targets[1], ctx.targets[2] = ctx.targets[2], ctx.targets[1]
provider.recalculate(ctx)
near(ctx.targets[1].box.w, 550); near(ctx.targets[2].box.w, 650)

provider.layout_msg(ctx, "toggle"); provider.recalculate(ctx)
local before = ctx.targets[2].box.h
provider.layout_msg(ctx, "resize 50"); provider.recalculate(ctx)
near(ctx.targets[2].box.h, before + 50)
near(ctx.targets[1].box.w, 1200)
local other = context(9002, 1200, 900, 3)
provider.recalculate(other); near(other.targets[1].box.w, 400)
local portrait = context(9003, 600, 900, 3)
provider.recalculate(portrait); near(portrait.targets[1].box.h, 300)
provider.recalculate({ area = ctx.area, targets = {} })

-- Reload the module and check that the saved vertical orientation is restored.
M = dofile("omarchy/hypr/aerospace.lua")
providers.aerospace.recalculate(ctx)
near(ctx.targets[1].box.w, 1200); near(ctx.targets[1].box.h, 450)
assert(bindings["ALT + A"].args.workspace == "10")
assert(bindings["ALT + 1"].args.workspace == "1")
assert(bindings["ALT + Z"].args.workspace == "31")
assert(bindings["ALT + SHIFT + A"].args.workspace == "10")
assert(bindings["ALT + SHIFT + 1"].args.workspace == "1")
workspace = ctx.targets[1].window.workspace
active = ctx.targets[2].window
for key, direction in pairs({ H = "l", J = "d", K = "u", L = "r" }) do
  bindings["ALT + " .. key]()
  assert(dispatched.kind == "focus" and dispatched.args.direction == direction)
  assert(bindings["ALT + SHIFT + " .. key].args.direction == direction)
end
bindings["ALT + SHIFT + equal"]()
assert(dispatched.kind == "layout" and dispatched.args == "resize 50")
active.floating = true
bindings["ALT + SHIFT + minus"]()
assert(dispatched.kind == "resize" and dispatched.args.x == -50)
print("PASS: tiling, portrait orientation, smart resize, bounds, rebalance, reorder, workspace isolation, reload, and bindings")
