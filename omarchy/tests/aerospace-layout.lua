-- Run from the repository root: lua omarchy/tests/aerospace-layout.lua
package.path = './omarchy/?.lua;' .. package.path
local providers, bindings, submaps, files, events, pointer_bindings = {}, {}, {}, {}, {}, {}
local active, workspace, dispatched, scope
local dispatches = {}
local function command(kind)
  return function(args) return { kind = kind, args = args } end
end
hl = {
  layout = { register = function(name, provider) providers[name] = provider end },
  config = function() end,
  bind = function(key, action, options) pointer_bindings[key] = { action = action, options = options } end,
  on = function(name, fn) events[name] = fn end,
  unbind = function() end,
  define_submap = function(name, reset, fn)
    assert(reset == 'reset'); submaps[name] = {}; scope = submaps[name]; fn(); scope = nil
  end,
  workspace_rule = function() return { set_enabled = function() end } end,
  get_active_window = function() return active end,
  get_active_workspace = function() return workspace end,
  get_active_special_workspace = function() end,
  dispatch = function(cmd) dispatched = cmd; dispatches[#dispatches + 1] = cmd end,
  notification = { create = function() error('Unexpected save failure') end },
  dsp = {
    focus = command('focus'), layout = command('layout'), submap = command('submap'),
    window = { move = command('move'), resize = command('resize'), close = command('close'),
      float = command('float'), bring_to_top = command('raise'), alter_zorder = command('zorder') },
    workspace = { rename = command('rename'), move = command('move-workspace') },
    group = { prev = command('group-prev'), next = command('group-next') },
    cursor = { move = command('cursor') },
  },
}
o = { bind = function(key, _, action) (scope or bindings)[key] = action end }
io.open = function(path, mode)
  if mode == 'r' and not files[path] then return nil end
  return {
    read = function(_, format) return format == '*l' and files[path]:match('[^\n]*') or files[path] end,
    write = function(_, ...) files[path] = table.concat({...}) end,
    close = function() end,
  }
end
local M = dofile('omarchy/hypr/aerospace.lua')
local provider = providers.aerospace
local function context(id, width, height, count)
  local ws = { id = id, config_name = tostring(id), tiled_layout = 'lua:aerospace' }
  local ctx = { area = { x = 10, y = 20, w = width, h = height }, targets = {} }
  for i = 1, count do
    ctx.targets[i] = {
      window = { stable_id = id * 100 + i, address = tostring(id * 100 + i),
        workspace = ws, active = i == 1, focus_history_id = i },
      place = function(self, box) self.box = box end,
    }
  end
  return ctx
end
local function near(a, b) assert(math.abs(a - b) < .001, tostring(a) .. ' != ' .. tostring(b)) end
local function focus(ctx, index)
  for i, t in ipairs(ctx.targets) do t.window.active = i == index end
  active = ctx.targets[index].window; workspace = active.workspace
  provider.activate(active)
end
local ctx = context(9001, 1200, 900, 3)
provider.recalculate(ctx)
for i, target in ipairs(ctx.targets) do
  near(target.box.w, 400); near(target.box.x, 10 + (i - 1) * 400); near(target.box.h, 900)
end
provider.layout_msg(ctx, 'resize 50'); provider.recalculate(ctx)
near(ctx.targets[1].box.w, 450); near(ctx.targets[2].box.w, 350)
provider.layout_msg(ctx, 'resize -5000')
assert(ctx.targets[1].box.w >= 99.99)
near(ctx.targets[1].box.w + ctx.targets[2].box.w + ctx.targets[3].box.w, 1200)
-- Removing a window rebalances. Keyboard reordering preserves each weight.
table.remove(ctx.targets, 3); provider.recalculate(ctx)
near(ctx.targets[1].box.w, 600); near(ctx.targets[2].box.w, 600)
provider.layout_msg(ctx, 'resize 50')
provider.layout_msg(ctx, 'move r')
near(ctx.targets[1].box.w, 650); near(ctx.targets[1].box.x, 560)
near(ctx.targets[2].box.w, 550); near(ctx.targets[2].box.x, 10)
provider.layout_msg(ctx, 'toggle')
local before = ctx.targets[1].box.h
provider.layout_msg(ctx, 'resize 50')
near(ctx.targets[1].box.h, before + 50); near(ctx.targets[1].box.w, 1200)
local other = context(9002, 1200, 900, 3)
provider.recalculate(other); near(other.targets[1].box.w, 400)
local portrait = context(9003, 600, 900, 3)
provider.recalculate(portrait); near(portrait.targets[1].box.h, 300)
provider.recalculate({ area = ctx.area, targets = {} })
-- Accordion retains 10-pixel strips and has direction-aware focus.
provider.layout_msg(other, 'accordion')
for i, target in ipairs(other.targets) do
  near(target.box.w, 1180); near(target.box.x, 10 + (i - 1) * 10)
end
focus(other, 2)
assert(provider.neighbor(9002, 'l') == other.targets[1].window)
assert(provider.neighbor(9002, 'r') == other.targets[3].window)
assert(provider.neighbor(9002, 'd') == nil)
provider.layout_msg(other, 'accordion')
near(other.targets[2].box.y, 30); near(other.targets[2].box.h, 880)
provider.layout_msg(other, 'toggle') -- Switching layout starts horizontal.
near(other.targets[2].box.w, 400)
-- Join-with creates an opposite-axis container; focus respects the tree.
focus(other, 2); provider.layout_msg(other, 'join l')
near(other.targets[1].box.w, 600); near(other.targets[1].box.h, 450)
near(other.targets[2].box.x, 10); near(other.targets[2].box.y, 470)
near(other.targets[3].box.x, 610); near(other.targets[3].box.h, 900)
assert(provider.neighbor(9002, 'u') == other.targets[1].window)
assert(provider.neighbor(9002, 'r') == other.targets[3].window)
provider.layout_msg(other, 'resize 50')
near(other.targets[2].box.h, 500); near(other.targets[1].box.h, 400)
provider.layout_msg(other, 'move r') -- Leave a nested container.
near(other.targets[2].box.x, 810); near(other.targets[2].box.h, 900)
provider.layout_msg(other, 'move u') -- Split outside an orthogonal root.
near(other.targets[2].box.w, 1200); near(other.targets[2].box.y, 20)
near(other.targets[1].box.y, 470)
provider.layout_msg(other, 'flatten')
for _, t in ipairs(other.targets) do near(t.box.h, 300); near(t.box.w, 1200) end
-- Membership cleanup collapses empty/single-child containers.
local joined = context(9004, 1200, 900, 3)
provider.recalculate(joined); focus(joined, 2); provider.layout_msg(joined, 'join l')
table.remove(joined.targets, 2); provider.recalculate(joined)
for _, t in ipairs(joined.targets) do near(t.box.w, 600); near(t.box.h, 900) end
local right_join = context(9006, 1200, 900, 3)
provider.recalculate(right_join); focus(right_join, 2); provider.layout_msg(right_join, 'join r')
near(right_join.targets[2].box.y, 20); near(right_join.targets[3].box.y, 470)
-- Reload restores geometry, including nested accordion containers. The
-- compositor adds its existing targets incrementally to the new provider.
local restored = context(9005, 1200, 900, 3)
provider.recalculate(restored); focus(restored, 2)
provider.layout_msg(restored, 'join l'); provider.layout_msg(restored, 'accordion')
local expected = {}
for i, target in ipairs(restored.targets) do expected[i] = target.box end
local ctx_height = ctx.targets[1].box.h
M = dofile('omarchy/hypr/aerospace.lua'); provider = providers.aerospace
provider.recalculate({ area = restored.area, targets = { restored.targets[1] } })
provider.recalculate({ area = restored.area, targets = { restored.targets[1], restored.targets[2] } })
provider.recalculate(restored)
provider.finish_restore()
for i, target in ipairs(restored.targets) do
  for _, key in ipairs({ 'x', 'y', 'w', 'h' }) do near(target.box[key], expected[i][key]) end
end
assert(provider.is_accordion(restored.targets[2].window))
-- Model native click handling: hit-test tiles bottom-first, then raise the
-- clicked window. Each repeated click must still reach the visible window.
local clicks = context(9007, 1200, 900, 4)
provider.recalculate(clicks); provider.layout_msg(clicks, 'accordion')
local stack, cursor = {}, { x = 600, y = 400 }
for _, target in ipairs(clicks.targets) do
  local window, box = target.window, target.box
  window.mapped, window.accepts_input, window.fullscreen = true, true, 0
  window.at, window.size = { x = box.x, y = box.y }, { x = box.w, y = box.h }
  stack[#stack + 1] = window
end
hl.get_cursor_pos = function() return cursor end
hl.get_monitor_at = function() return { active_workspace = clicks.targets[1].window.workspace } end
hl.get_windows = function() return stack end
local normal_dispatch = hl.dispatch
hl.dispatch = function(cmd)
  normal_dispatch(cmd)
  if cmd.kind == 'zorder' then
    assert(cmd.args.mode == 'bottom')
    for i, window in ipairs(stack) do
      if cmd.args.window == 'address:' .. window.address then
        table.insert(stack, 1, table.remove(stack, i)); break
      end
    end
  end
end
local click_binding = pointer_bindings['mouse:272']
assert(click_binding.options.non_consuming and click_binding.options.ignore_mods
  and click_binding.options.submap_universal)
local function click_visible(expected)
  click_binding.action()
  local hit
  for i, window in ipairs(stack) do
    if cursor.x >= window.at.x and cursor.x < window.at.x + window.size.x
        and cursor.y >= window.at.y and cursor.y < window.at.y + window.size.y then
      hit = window; table.insert(stack, table.remove(stack, i)); break
    end
  end
  assert(hit == expected, 'Click reached an obscured accordion window')
  active = hit
end
for index = 1, 4 do
  focus(clicks, index)
  for _ = 1, 3 do click_visible(active) end
end
-- A visible strip must select its own window, including strips where several
-- background tiles overlap. The renderer paints later stack entries on top.
focus(clicks, 1); cursor.x = 1205
local expected = stack[#stack]
click_visible(expected)
click_visible(expected)
-- Native floating windows and fullscreen windows need no adjustment.
local floating = { mapped = true, accepts_input = true, fullscreen = 0, floating = true,
  at = { x = 0, y = 0 }, size = { x = 2000, y = 2000 } }
stack[#stack + 1] = floating
dispatches = {}; click_binding.action(); assert(#dispatches == 0)
table.remove(stack); stack[1].fullscreen = 1
click_binding.action(); assert(#dispatches == 0)
hl.dispatch = normal_dispatch
provider.recalculate(ctx)
near(ctx.targets[1].box.w, 1200); near(ctx.targets[1].box.h, ctx_height)
assert(bindings['ALT + A'].args.workspace == '10')
assert(bindings['ALT + 1'].args.workspace == '1')
assert(bindings['ALT + Z'].args.workspace == '31')
assert(bindings['ALT + SHIFT + A'].args.follow == false)
assert(bindings['ALT + SHIFT + 1'].args.workspace == '1')
focus(ctx, 1)
bindings['ALT + K']()
assert(dispatches[#dispatches - 1].kind == 'focus')
assert(dispatches[#dispatches - 1].args.window == 'address:' .. ctx.targets[2].window.address)
bindings['ALT + SHIFT + L']()
assert(dispatched.kind == 'layout' and dispatched.args == 'move r')
bindings['ALT + SHIFT + equal']()
assert(dispatched.kind == 'layout' and dispatched.args == 'resize 50')
active.floating = true; bindings['ALT + SHIFT + minus']()
assert(dispatched.kind == 'resize' and dispatched.args.x == -50)
assert(bindings['ALT + SHIFT + semicolon'].args == 'aerospace-service')
local service = submaps['aerospace-service']
assert(service.Escape == 'hyprctl reload')
assert(service.F.kind == 'float')
service['ALT + SHIFT + H']()
assert(dispatched.args == 'join l')
local preserved, closed, elsewhere = { stable_id = 8, address = 'keep' }, { stable_id = 9, address = 'close' }, { stable_id = 10, address = 'elsewhere' }
active = preserved
workspace = { get_windows = function() return { preserved, closed } end }
dispatches = {}; service.BackSpace()
assert(#dispatches == 1 and dispatches[1].args.window == 'address:close')
-- Monitor focus only warps a cursor that is outside its logical bounds.
hl.get_cursor_pos = function() return { x = 100, y = 100 } end
dispatches = {}; events['monitor.focused']({ x = 0, y = 0, width = 1920, height = 1080, scale = 1.6 })
assert(#dispatches == 0)
events['monitor.focused']({ x = 1200, y = 0, width = 1920, height = 1080, scale = 1.6 })
assert(dispatched.kind == 'cursor'); near(dispatched.args.x, 1800)
print('PASS: tiles, portrait, resize bounds, reorder, accordion, repeated/strip clicks, floating/fullscreen click bypass, nested join/focus/move, flatten, cleanup, orientation reload, workspaces, service mode, and monitor cursor')
