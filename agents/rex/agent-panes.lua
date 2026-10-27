-- Keep the Rex layout of a coding agent. agent-panes runs this script with
-- "rex do" at each hook event, with the wanted state in rex.args:
--
--   block    the block of the agent
--   harness  claude or codex
--   viewer   the agent-panes command, to show a subagent transcript
--   cwd      the working directory of the agent
--   home     $HOME, shown as ~ in the labels
--   repos    the repositories, first write first: { root, workspaces }. The
--            root is the main checkout, the workspaces are the workspace
--            roots that the agent wrote into, first write first
--   written  the workspace roots that this hook event wrote into
--   agents   the running subagents: { id, type, transcript }
--   removed  the labels of the subagents that stopped
--
-- The labels are the keys. A subagent pane is "<type> <id>". The panes of a
-- repository are "logwatch <root>" and a "shell <workspace>" for each
-- workspace. The workspaces of a repository share the one logwatch, because
-- the log shows all of them. The script touches only
-- blocks with these labels. All other blocks are the blocks of the user: it
-- never closes, moves, resizes, or relabels them.

-- A window is wide when its width / height is this value or more.
-- 16:9 is 1.78, 21:9 is 2.33.
local WIDE = 2.0

local terminal = "com.superlogical.terminal"
local shell = "com.superlogical.terminal.shell"
local args = rex.args

local function call(method, params)
  params.session_id = rex.session_id
  local r, err = rex.call(method, params)
  if err ~= nil then error(err, 0) end
  return r
end

local function view_call(fn, params)
  local r, err = fn(params)
  if err ~= nil then error(err, 0) end
  return r
end

-- The blocks of a layout node, in layout order.
local function walk(node, out)
  out = out or {}
  if not node then return out end
  if node.block_id then
    out[#out + 1] = node.block_id
  elseif node.split then
    walk(node.split.before, out)
    walk(node.split.after, out)
  end
  return out
end

-- The window that holds the agent block: its tiled layout, the blocks of each
-- label, and the place of each block in layout order.
local function snapshot()
  local view = view_call(rex.session.view, {})
  for _, w in ipairs(view.windows or {}) do
    local found, layout = false, nil
    local labels, all = {}, {}
    for _, layer in ipairs(w.layers or {}) do
      if layer.kind == "tiled" then layout = layer.layout end
      for _, b in ipairs(layer.blocks or {}) do
        if b.block_id == args.block then found = true end
        labels[b.label or ""] = labels[b.label or ""] or {}
        table.insert(labels[b.label or ""], b.block_id)
        all[#all + 1] = b.block_id
      end
    end
    if found then
      local order = {}
      for i, id in ipairs(walk(layout)) do order[id] = i end
      for _, id in ipairs(all) do order[id] = order[id] or #all + 1000 end
      return { window = w, layout = layout, labels = labels, order = order }
    end
  end
  error("agent block not in a window: " .. tostring(args.block), 0)
end

local function first(snap, label)
  local ids = snap.labels[label]
  return ids and ids[1] or nil
end

-- The anchor for a new column at the far right: the root split, or the
-- single block when the layout has no split.
local function root_anchor(snap)
  local root = snap.layout
  if root.split then return root.split.split_id end
  return root.block_id
end

-- The top-level columns from left to right. While a node is a horizontal
-- split, its after node is a column.
local function columns(layout)
  local cols = {}
  local node = layout
  while node.split and node.split.direction == "horizontal" do
    table.insert(cols, 1, node.split.after)
    node = node.split.before
  end
  table.insert(cols, 1, node)
  return cols
end

local function display(root)
  local home = args.home or ""
  if home ~= "" then
    if root == home then return "~" end
    if root:sub(1, #home + 1) == home .. "/" then return "~" .. root:sub(#home + 1) end
  end
  return root
end

local function logwatch_label(root) return "logwatch " .. display(root) end
local function shell_label(root) return "shell " .. display(root) end

local function logwatch_block(root)
  return rex.layout.block{
    flavor = shell,
    label = logwatch_label(root),
    options = { cwd = root, command = { "jj", "logwatch" } },
  }
end

local function shell_block(root)
  return rex.layout.block{ flavor = shell, label = shell_label(root), options = { cwd = root } }
end

local function new_split(anchor, direction, side, ratio, layout)
  return view_call(rex.session.new_split, {
    anchor_id = anchor,
    direction = direction,
    side = side,
    ratio = ratio,
    focus = false,
    layout = layout,
  })
end

local function move(block, anchor, side)
  view_call(rex.session.move_block, {
    block_id = block,
    anchor_block_id = anchor,
    direction = "vertical",
    side = side,
  })
end

local snap = snapshot()

-- 1. Close the panes of the subagents that stopped.
for _, label in ipairs(args.removed or {}) do
  for _, id in ipairs(snap.labels[label] or {}) do
    call("block.close", { block_id = id })
  end
end
if #(args.removed or {}) > 0 then snap = snapshot() end

-- 2. Open a pane for each running subagent that has none. The first one makes
-- a column right of the agent. The others stack below the last one.
for _, agent in ipairs(args.agents or {}) do
  local label = agent.type .. " " .. agent.id
  if not first(snap, label) then
    local last
    for _, other in ipairs(args.agents) do
      local id = first(snap, other.type .. " " .. other.id)
      if id and (not last or snap.order[id] > snap.order[last]) then last = id end
    end
    local block = rex.layout.block{
      flavor = shell,
      label = label,
      options = {
        cwd = args.cwd,
        command = { args.viewer, "view", args.harness, agent.transcript },
      },
    }
    if last then
      new_split(last, "vertical", "after", 0.5, block)
    else
      new_split(args.block, "horizontal", "after", 0.5, block)
    end
    snap = snapshot()
  end
end

local repos = args.repos or {}
if #repos == 0 then return end

-- The repository and role of each repository pane in the window.
local function repo_panes(s)
  local owned = {}
  for i, repo in ipairs(repos) do
    for _, id in ipairs(s.labels[logwatch_label(repo.root)] or {}) do owned[id] = { repo = i, role = 1 } end
    for _, ws in ipairs(repo.workspaces) do
      for _, id in ipairs(s.labels[shell_label(ws)] or {}) do owned[id] = { repo = i, role = 2 } end
    end
  end
  return owned
end

-- The panes of a repository that are in the window: the logwatch, then the
-- shells in workspace order.
local function group(s, repo)
  local list = { first(s, logwatch_label(repo.root)) }
  for _, ws in ipairs(repo.workspaces) do
    list[#list + 1] = first(s, shell_label(ws))
  end
  return list
end

-- 3. The shape of the window, from the pixel size of its terminal blocks.
-- The size of a terminal is the size of the client that owns the block
-- ("owner" in the result). So a reconcile after the user moves to another
-- device gives the layout of that device. A block without an owner has a
-- default size, and a client that did not report pixels gives 0. Such a
-- block has no size.
local function measure(node)
  if node.block_id then
    local s = rex.block.call(terminal, "size", { block_id = node.block_id })
    if not s or s.owner == nil or (s.columns or 0) == 0 or (s.rows or 0) == 0
        or (s.cell_width_px or 0) == 0 or (s.cell_height_px or 0) == 0 then
      return nil
    end
    return s.columns * s.cell_width_px, s.rows * s.cell_height_px
  end
  local sp = node.split
  local bw, bh = measure(sp.before)
  local aw, ah = measure(sp.after)
  if not bw then return aw, ah end
  if not aw then return bw, bh end
  if sp.direction == "vertical" then return math.max(bw, aw), bh + ah end
  return bw + aw, math.max(bh, ah)
end

local width, height = measure(snap.layout)
local mode, known
if width and height then
  known = true
  mode = width / height >= WIDE and "wide" or "regular"
else
  -- The size is not known: keep the shape that the repository panes have.
  -- Repository panes in more than one column are wide. Else regular.
  known = false
  mode = "regular"
  local owned, used = repo_panes(snap), 0
  for _, col in ipairs(columns(snap.layout)) do
    for _, id in ipairs(walk(col)) do
      if owned[id] then used = used + 1 break end
    end
  end
  if used > 1 then mode = "wide" end
end

-- 4. Open the missing panes of the workspaces that this event wrote into: the
-- logwatch of the repository and the shell of the workspace. Do not open the
-- panes of other workspaces again, because the user closes the panes of a
-- workspace when the work there is done. A pair is the logwatch above a
-- shell. The other shells of the repository go below.
local function last_repo_pane(s)
  local owned, last = repo_panes(s), nil
  for id in pairs(owned) do
    if not last or s.order[id] > s.order[last] then last = id end
  end
  return last
end

local written = {}
for _, ws in ipairs(args.written or {}) do written[ws] = true end

for _, repo in ipairs(repos) do
  for _, ws in ipairs(repo.workspaces) do
    if written[ws] then
      local list = group(snap, repo)
      if #list == 0 then
        local pair = rex.layout.vertical(0.5, logwatch_block(repo.root), shell_block(ws))
        local last = mode == "regular" and last_repo_pane(snap) or nil
        if last then
          new_split(last, "vertical", "after", 0.5, pair)
        else
          new_split(root_anchor(snap), "horizontal", "after", 0.75, pair)
        end
        snap = snapshot()
      else
        if not first(snap, logwatch_label(repo.root)) then
          new_split(list[1], "vertical", "before", 0.5, logwatch_block(repo.root))
          snap = snapshot()
        end
        if not first(snap, shell_label(ws)) then
          list = group(snap, repo)
          new_split(list[#list], "vertical", "after", 0.5, shell_block(ws))
          snap = snapshot()
        end
      end
    end
  end
end

-- 5. Make sure that the repository columns are the rightmost columns, in the
-- layout of the mode. A pane of the user inside a repository column is fine.
-- Do not move panes when the size of the window is not known.
if not known then return end

local function same(a, b)
  if #a ~= #b then return false end
  for i = 1, #a do
    if a[i] ~= b[i] then return false end
  end
  return true
end

-- The repository panes in each repository, logwatch first.
local owned = repo_panes(snap)
local present, panes = {}, {}
for i, repo in ipairs(repos) do
  local list = group(snap, repo)
  if #list > 0 then
    present[#present + 1] = i
    panes[i] = list
  end
end
if #present == 0 then return end

local function repo_seq(node)
  local seq = {}
  for _, id in ipairs(walk(node)) do
    if owned[id] then seq[#seq + 1] = id end
  end
  return seq
end

local cols = columns(snap.layout)
local ok = true
if mode == "wide" then
  local k = #present
  if #cols < k then
    ok = false
  else
    for j = 1, k do
      if not same(repo_seq(cols[#cols - k + j]), panes[present[j]]) then ok = false end
    end
  end
else
  local want = {}
  for _, i in ipairs(present) do
    for _, id in ipairs(panes[i]) do want[#want + 1] = id end
  end
  ok = same(repo_seq(cols[#cols]), want)
end
if ok then return end

-- Put a block in a new column at the far right. move_block takes only a
-- block as the anchor, so a placeholder block makes the column first. The
-- swap keeps the program of the moved block running.
local function place_right(block)
  local s = snapshot()
  local r = new_split(root_anchor(s), "horizontal", "after", 0.75, rex.layout.block{
    flavor = shell,
    label = "agent-panes placeholder",
    options = { shell = "none", command = { "sleep", "60" } },
  })
  local placeholder = r.block_ids[1]
  view_call(rex.session.swap_blocks, { block_id = block, other_block_id = placeholder })
  call("block.close", { block_id = placeholder })
end

-- Build the repository columns again, in repository order.
local prev
for n, i in ipairs(present) do
  local list = panes[i]
  if n == 1 or mode == "wide" then
    place_right(list[1])
  else
    move(list[1], prev, "after")
  end
  for k = 2, #list do move(list[k], list[k - 1], "after") end
  prev = list[#list]
end
