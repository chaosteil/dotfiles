-- https://www.superlogical.com/rex/docs/customize/config
-- Appearance and remote hosts live in the Rex app, not here.

-- Split keys from the Ghostty config.
rex.bind("cmd+shift+\\", "pane.split.right")
rex.bind("cmd+shift+-", "pane.split.down")

rex.bind("cmd+shift+h", "pane.focus.left")
rex.bind("cmd+shift+j", "pane.focus.down")
rex.bind("cmd+shift+k", "pane.focus.up")
rex.bind("cmd+shift+l", "pane.focus.right")

rex.bind("cmd+shift+ctrl+h", "pane.resize", { direction = "left" })
rex.bind("cmd+shift+ctrl+j", "pane.resize", { direction = "down" })
rex.bind("cmd+shift+ctrl+k", "pane.resize", { direction = "up" })
rex.bind("cmd+shift+ctrl+l", "pane.resize", { direction = "right" })

rex.bind("cmd+shift+ctrl+=", "pane.balance")

local terminal = "com.superlogical.terminal"
local shell = "com.superlogical.terminal.shell"
local sessions_dir = os.getenv("HOME") .. "/.local/state/rex/sessions"

-- The working directory a terminal block last reported, as a plain path.
local function block_dir(block_id)
  local r = rex.block.call(terminal, "pwd", { block_id = block_id })
  if not r or not r.pwd or r.pwd == "" then return nil end
  local path = r.pwd:gsub("^file://[^/]*", "")
  return (path:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end

-- Serialize a table as Lua source, so a saved session loads with dofile.
local function dump(v, ind)
  ind = ind or ""
  if type(v) == "string" then return string.format("%q", v) end
  if type(v) ~= "table" then return tostring(v) end
  local keys = {}
  for k in pairs(v) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  local out = { "{" }
  for _, k in ipairs(keys) do
    local key = type(k) == "number" and "[" .. k .. "]" or string.format("[%q]", k)
    out[#out + 1] = ind .. "  " .. key .. " = " .. dump(v[k], ind .. "  ") .. ","
  end
  out[#out + 1] = ind .. "}"
  return table.concat(out, "\n")
end

-- Turn a layout node from session.view into a layout for new_window.
local function snapshot(node)
  if node.split then
    local s = node.split
    return { split = {
      direction = s.direction,
      ratio = s.ratio,
      before = snapshot(s.before),
      after = snapshot(s.after),
    } }
  end
  return rex.layout.block{ flavor = shell, options = { cwd = block_dir(node.block_id) } }
end

local function session_path(name)
  return sessions_dir .. "/" .. (name or "default"):gsub("[^%w_-]", "_") .. ".lua"
end

rex.action{
  name     = "session_save",
  title    = "Save Session",
  category = "Session",
  args     = { name = "string?" },
  run      = function(ctx, args)
    local view, err = rex.session.view{}
    if err ~= nil then error(err, 0) end
    local windows = {}
    for _, w in ipairs(view.windows or {}) do
      for _, layer in ipairs(w.layers or {}) do
        if layer.kind == "tiled" and layer.layout then
          windows[#windows + 1] = {
            -- Keep only labels you set, not the generated "Window 1a2b3c4d".
            label  = not w.label:match("^Window %x+$") and w.label or nil,
            layout = snapshot(layer.layout),
          }
        end
      end
    end
    os.execute(string.format("mkdir -p %q", sessions_dir))
    local path = session_path(args.name)
    local f = assert(io.open(path, "w"))
    f:write("return ", dump(windows), "\n")
    f:close()
    return { path = path, windows = #windows }
  end,
}

rex.action{
  name     = "session_restore",
  title    = "Restore Session",
  category = "Session",
  args     = { name = "string?" },
  run      = function(ctx, args)
    local path = session_path(args.name)
    local ok, windows = pcall(dofile, path)
    if not ok then error("cannot load " .. path .. ": " .. tostring(windows), 0) end
    for _, w in ipairs(windows) do
      local _, err = rex.session.new_window{ window_label = w.label, layout = w.layout }
      if err ~= nil then error(err, 0) end
    end
    return { windows = #windows }
  end,
}

-- 35% | 35% | 30% split top and bottom.
rex.action{
  name     = "dev_tab",
  title    = "Open Dev Tab",
  category = "Session",
  args     = { dir = "string?" },
  run      = function(ctx, args)
    local dir = args.dir or (ctx.block_id and block_dir(ctx.block_id))
    if dir then dir = dir:gsub("^~", os.getenv("HOME")) end
    local function term()
      return rex.layout.block{ flavor = shell, options = { cwd = dir } }
    end
    local w, err = rex.session.new_window{
      layout = rex.layout.horizontal(0.35, term(),
        rex.layout.horizontal(0.35 / 0.65, term(),
          rex.layout.vertical(0.5, term(), term()))),
    }
    if err ~= nil then error(err, 0) end
    return { window_id = w.window_id, dir = dir }
  end,
}
