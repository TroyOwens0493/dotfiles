-- Run from the repository root: lua omarchy/tests/macos-keys.lua
local bindings, unbound, events, sent, pending, actions = {}, {}, {}, {}, {}, {}
local active = { class = 'browser', tags = {}, address = '1', focus_history_id = 0 }
local windows = {}
local function command(kind)
  return function(args) return { kind = kind, args = args } end
end
hl = {
  get_active_window = function() return active end,
  get_windows = function() return windows end,
  get_window = function(selector)
    for _, window in ipairs(windows) do if selector == 'address:' .. window.address then return window end end
  end,
  unbind = function(key) unbound[key] = true end,
  timer = function(fn) pending[#pending + 1] = fn end,
  on = function(event, fn) events[event] = fn end,
  exec_cmd = function(cmd) actions[#actions + 1] = { kind = 'exec', args = cmd } end,
  dispatch = function(cmd)
    if cmd.kind == 'send' then sent[#sent + 1] = cmd.args
    else actions[#actions + 1] = cmd end
  end,
  dsp = {
    send_key_state = command('send'), focus = command('focus'),
    window = { close = command('close'), fullscreen = command('fullscreen'), bring_to_top = command('raise') },
  },
}
o = { bind = function(chord, _, action) bindings[chord] = action end }
local M = dofile('omarchy/hypr/macos-keys.lua')
local function flush()
  while #pending > 0 do table.remove(pending, 1)() end
end
local function check(chord, mods, key)
  sent = {}; bindings[chord](); flush()
  assert(#sent == 2, chord .. ': expected down/up')
  assert(sent[1].mods == mods and sent[1].key == key and sent[1].state == 'down', chord)
  assert(sent[2].mods == mods and sent[2].key == key and sent[2].state == 'up', chord)
end
check('SUPER + C', 'CTRL', 'C')
check('SUPER + V', 'CTRL', 'V')
check('SUPER + T', 'CTRL', 'T')
check('SUPER + W', 'CTRL', 'W')
check('SUPER + SHIFT + Z', 'CTRL SHIFT', 'Z')
check('SUPER + SHIFT + T', 'CTRL SHIFT', 'T')
check('SUPER + 2', 'CTRL', '2')
check('SUPER + 9', 'CTRL', '9')
check('SUPER + Left', '', 'Home')
check('SUPER + SHIFT + Down', 'CTRL SHIFT', 'End')
check('ALT + Left', 'CTRL', 'Left')
check('ALT + SHIFT + Right', 'CTRL SHIFT', 'Right')
check('SUPER + equal', 'CTRL', 'equal')
check('SUPER + SHIFT + minus', 'CTRL SHIFT', 'minus')
check('SUPER + slash', 'CTRL', 'slash')
check('SUPER + comma', 'CTRL', 'comma')
check('SUPER + bracketleft', 'ALT', 'Left')
check('SUPER + SHIFT + bracketright', 'CTRL', 'Tab')
assert(unbound['SUPER + code:11'] and unbound['SUPER + SHIFT + code:18'])
assert(unbound['SUPER + T'] and unbound['SUPER + W'] and unbound['SUPER + SHIFT + W'])
assert(bindings['ALT + SPACE'] == 'omarchy-menu toggle')
assert(not unbound['SUPER + SPACE'])
assert(not bindings['CTRL + C'])
active = { class = 'com.mitchellh.ghostty', tags = { 'terminal*' }, address = 'terminal' }
check('SUPER + C', 'CTRL', 'Insert')
check('SUPER + V', 'SHIFT', 'Insert')
check('SUPER + T', 'CTRL SHIFT', 'T')
check('SUPER + W', 'CTRL SHIFT', 'W')
check('ALT + BackSpace', 'CTRL', 'W')
check('SUPER + BackSpace', 'CTRL', 'U')
active.class = 'foot'; actions = {}; bindings['SUPER + T']()
assert(actions[1].kind == 'exec' and actions[1].args == 'omarchy-launch-terminal')
actions = {}; bindings['SUPER + W'](); assert(actions[1].kind == 'close')
active = { class = 'browser', tags = {}, address = '1', focus_history_id = 0 }
windows = { active, { class = 'editor', address = '2', focus_history_id = 1 },
  { class = 'browser', address = '3', focus_history_id = 2 },
  { class = 'terminal', address = '4', focus_history_id = 3 } }
actions = {}; bindings['SUPER + TAB']()
assert(actions[1].args.window == 'address:2')
actions = {}; bindings['SUPER + TAB']()
assert(actions[1].args.window == 'address:4')
events['input.keyboard.key'](64, 0, 0)
actions = {}; bindings['SUPER + grave']()
assert(actions[1].args.window == 'address:3')
actions = {}; M.quit()
assert(#actions == 2 and actions[1].args.window == 'address:1' and actions[2].args.window == 'address:3')
print('PASS: Command app keys, terminal copy/paste/tabs, arrows, zoom, physical keycode conflicts, app/window switch, graceful app close, preserved physical Option+Space, and separate Control')
