-- Tree layout for AeroSpace's tiles, accordion, and join-with commands.
-- No compositor calls here: geometry and tree operations can be tested directly.
local M = {}

function M.new(load_orientation, save_orientation, load_tree, save_tree)
  local states = {}
  local function copy(node)
    local result = { id = node.id, orientation = node.orientation, mode = node.mode, weight = node.weight }
    if node.children then
      result.children = {}
      for _, child in ipairs(node.children) do result.children[#result.children + 1] = copy(child) end
    end
    return result
  end
  local function save(state)
    if save_tree and not state.restoring then save_tree(state.id, copy(state.root)) end
  end
  local function axis(direction) return (direction == "l" or direction == "r") and "horizontal" or "vertical" end
  local function step(direction) return (direction == "l" or direction == "u") and -1 or 1 end
  local function opposite(value) return value == "horizontal" and "vertical" or "horizontal" end
  local function container(orientation, children)
    return { orientation = orientation, mode = "tiles", children = children or {}, weight = 1 }
  end
  local function find(node, id, path)
    path = path or {}
    if node.id == id then return node, path end
    for i, child in ipairs(node.children or {}) do
      path[#path + 1] = { node = node, index = i }
      local found, result = find(child, id, path)
      if found then return found, result end
      path[#path] = nil
    end
  end
  local function leaves(node, result)
    result = result or {}
    if node.id then result[#result + 1] = node
    else for _, child in ipairs(node.children) do leaves(child, result) end end
    return result
  end
  local function normalize(node, present, root)
    if node.id then return present[node.id] and node or nil end
    local children = {}
    for _, child in ipairs(node.children) do
      child = normalize(child, present, false)
      if child then
        if child.children and child.orientation == node.orientation and child.mode == node.mode then
          local total = 0
          for _, grandchild in ipairs(child.children) do total = total + grandchild.weight end
          for _, grandchild in ipairs(child.children) do
            grandchild.weight = child.weight * grandchild.weight / total
            children[#children + 1] = grandchild
          end
        else children[#children + 1] = child end
      end
    end
    node.children = children
    if not root and #children == 0 then return nil end
    if not root and #children == 1 then children[1].weight = node.weight; return children[1] end
    return node
  end
  local function orientation(node, area)
    if node.orientation ~= "auto" then return node.orientation end
    return area.w >= area.h and "horizontal" or "vertical"
  end
  local function state_for(ctx)
    local window = ctx.targets[1] and ctx.targets[1].window
    if not window or not window.workspace then return end
    local id = window.workspace.id
    local state = states[id]
    if not state then
      local restored = load_tree and load_tree(id)
      state = { root = container(load_orientation(id)), id = id, restoring = restored }
      states[id] = state
    end
    -- Hyprland adds existing windows one at a time during reload. Project the
    -- saved tree onto the targets seen so far without erasing later targets.
    if state.restoring then state.root = copy(state.restoring) end
    local present, targets, active = {}, {}, nil
    for _, target in ipairs(ctx.targets) do
      local wid = target.window.stable_id
      present[wid], targets[wid] = true, target
      if target.window.active then active = wid end
    end
    local old_count = #leaves(state.root)
    normalize(state.root, present, true)
    local changed = old_count ~= #leaves(state.root)
    for _, target in ipairs(ctx.targets) do
      local wid = target.window.stable_id
      if not find(state.root, wid) then
        local _, path = find(state.root, state.active)
        local entry = path and path[#path]
        local parent = entry and entry.node or state.root
        table.insert(parent.children, entry and entry.index + 1 or #parent.children + 1, { id = wid, weight = 1 })
        changed = true
      end
    end
    if changed and not state.restoring then
      -- Match AeroSpace's equal shares after a window enters or leaves.
      local function balance(node)
        for _, child in ipairs(node.children or {}) do child.weight = 1; balance(child) end
      end
      balance(state.root)
    end
    state.active = active or (present[state.active] and state.active) or (ctx.targets[1] and ctx.targets[1].window.stable_id)
    state.targets, state.area = targets, ctx.area
    if changed then save(state) end
    return state
  end
  local function place(node, area, state)
    node.box = area
    if node.id then state.targets[node.id]:place(area); return end
    local horizontal = orientation(node, area) == "horizontal"
    local total, offset, count = 0, 0, #node.children
    for _, child in ipairs(node.children) do total = total + child.weight end
    local padding = math.min(10, (horizontal and area.w or area.h) / math.max(1, 2 * count))
    for i, child in ipairs(node.children) do
      local extent = horizontal and area.w or area.h
      local size = node.mode == "accordion" and extent - padding * (count - 1) or extent * child.weight / total
      local start = node.mode == "accordion" and padding * (i - 1) or offset
      place(child, {
        x = area.x + (horizontal and start or 0), y = area.y + (horizontal and 0 or start),
        w = horizontal and size or area.w, h = horizontal and area.h or size,
      }, state)
      offset = offset + size
    end
  end
  local function sibling(state, direction)
    local leaf, path = find(state.root, state.active)
    if not leaf then return end
    for level = #path, 1, -1 do
      local entry = path[level]
      if orientation(entry.node, entry.node.box or state.area) == axis(direction) then
        local index = entry.index + step(direction)
        if entry.node.children[index] then return leaf, path, entry.node, entry.index, index end
      end
    end
    return leaf, path
  end
  local function detach(state, leaf, path)
    local entry = path[#path]
    table.remove(entry.node.children, entry.index)
  end
  local function selected_leaf(node, state)
    local candidates = leaves(node)
    local best = candidates[1]
    for _, candidate in ipairs(candidates) do
      local window = state.targets[candidate.id].window
      if (window.focus_history_id or 99999) < (state.targets[best.id].window.focus_history_id or 99999) then best = candidate end
    end
    return best
  end
  local provider = {}
  function provider.recalculate(ctx)
    local state = state_for(ctx)
    if state then place(state.root, ctx.area, state) end
  end
  function provider.layout_msg(ctx, msg)
    local state = state_for(ctx)
    if not state then return true end
    state.restoring = nil
    place(state.root, ctx.area, state)
    local leaf, path = find(state.root, state.active)
    local parent = path and path[#path] and path[#path].node or state.root
    if msg == "toggle" or msg == "accordion" then
      local mode = msg == "toggle" and "tiles" or "accordion"
      parent.orientation = parent.mode == mode and opposite(orientation(parent, parent.box)) or "horizontal"
      parent.mode = mode
      if parent == state.root then save_orientation(state.id, parent.orientation) end
    elseif msg == "flatten" then
      state.root = container(state.root.orientation, leaves(state.root))
      for _, child in ipairs(state.root.children) do child.weight = 1 end
    else
      local delta = tonumber(msg:match("^resize (%-?%d+)$"))
      local action, direction = msg:match("^(%a+) ([lrud])$")
      if delta and leaf and #parent.children > 1 and parent.mode == "tiles" then
        local index = path[#path].index
        local neighbor = index < #parent.children and index + 1 or index - 1
        local a, b = parent.children[index], parent.children[neighbor]
        local total = 0
        for _, child in ipairs(parent.children) do total = total + child.weight end
        local extent = orientation(parent, parent.box) == "horizontal" and parent.box.w or parent.box.h
        local minimum = math.min(100 / extent * total, (a.weight + b.weight) / 4)
        local change = math.max(minimum - a.weight, math.min(delta / extent * total, b.weight - minimum))
        a.weight, b.weight = a.weight + change, b.weight - change
      elseif action == "move" or action == "join" then
        local current, current_path, ancestor, from, to = sibling(state, direction)
        if not ancestor and action == "move" and current and #leaves(state.root) > 1
            and orientation(state.root, state.area) ~= axis(direction) then
          -- Moving past an orthogonal root creates a new outer split.
          detach(state, current, current_path)
          local present = {}
          for id in pairs(state.targets) do present[id] = true end
          local remaining = normalize(state.root, present, false)
          current.weight, remaining.weight = 1, 1
          state.root = container(axis(direction), step(direction) < 0 and { current, remaining } or { remaining, current })
          save_orientation(state.id, state.root.orientation)
        elseif ancestor then
          local neighbor = ancestor.children[to]
          if action == "move" and parent == ancestor then
            ancestor.children[from], ancestor.children[to] = ancestor.children[to], ancestor.children[from]
          else
            detach(state, current, current_path)
            -- Find the neighbor again after removal shifts its index.
            local index
            for i, child in ipairs(ancestor.children) do if child == neighbor then index = i end end
            if action == "join" then
              if neighbor.children and orientation(neighbor, neighbor.box) == opposite(axis(direction)) then
                table.insert(neighbor.children, step(direction) > 0 and 1 or #neighbor.children + 1, current)
              else
                local group = container(opposite(axis(direction)), step(direction) > 0 and { current, neighbor } or { neighbor, current })
                group.weight, neighbor.weight, current.weight = neighbor.weight, 1, 1
                ancestor.children[index] = group
              end
            else
              current.weight = 1
              table.insert(ancestor.children, index + (step(direction) > 0 and 1 or 0), current)
            end
            local present = {}
            for id in pairs(state.targets) do present[id] = true end
            normalize(state.root, present, true)
          end
        end
      elseif not delta then return "Unknown AeroSpace layout command: " .. msg end
    end
    place(state.root, ctx.area, state)
    save(state)
    return true
  end
  function provider.neighbor(workspace, direction)
    local state = states[workspace]
    if not state then return end
    local _, _, ancestor, _, to = sibling(state, direction)
    if ancestor then
      local leaf = selected_leaf(ancestor.children[to], state)
      return state.targets[leaf.id].window
    end
  end
  function provider.activate(window)
    local state = window and window.workspace and states[window.workspace.id]
    if state and find(state.root, window.stable_id) then state.active = window.stable_id end
  end
  function provider.is_accordion(window)
    local state = window and window.workspace and states[window.workspace.id]
    if not state then return false end
    local _, path = find(state.root, window.stable_id)
    for _, entry in ipairs(path or {}) do
      if entry.node.mode == "accordion" then return true end
    end
    return false
  end
  function provider.finish_restore()
    for _, state in pairs(states) do
      state.restoring = nil
      save(state)
    end
  end
  return provider
end

return M
