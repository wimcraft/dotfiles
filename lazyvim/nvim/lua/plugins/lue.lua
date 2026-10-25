-- Read text aloud with lue: a .md/.txt buffer from the cursor, or the last
-- response in a CodeCompanion chat.
--
-- lue has no "start at position" flag, so `lue-at` seeds lue's progress file
-- (chapter/paragraph/sentence) before exec'ing lue. Both .md and .txt parse to
-- a single chapter, so only the paragraph index needs computing.

local DEFAULT_ARGS = { "-t", "kokoro", "-v", "am_michael" }
local CODE_MARKER = "Code block omitted."

---Open lue in a float, positioned at `line` of `file`.
local function launch(file, line, opts)
  local cmd = { "lue-at", file, tostring(line), "--" }
  vim.list_extend(cmd, opts.lue_args or vim.g.lue_args or DEFAULT_ARGS)

  Snacks.terminal.open(cmd, {
    interactive = true,
    win = {
      position = "float",
      width = 0.9,
      height = 0.9,
      border = "rounded",
      title = " lue — " .. (opts.title or vim.fn.fnamemodify(file, ":t")) .. " ",
      title_pos = "center",
    },
    env = { HF_HUB_OFFLINE = "1" }, -- weights are cached; skips the HF warning
  })
end

--------------------------------------------------------------------------- file

local function read_from_cursor(opts)
  opts = opts or {}

  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("lue: buffer has no file on disk", vim.log.levels.WARN)
    return
  end
  if not file:lower():match("%.md$") and not file:lower():match("%.txt$") then
    vim.notify("lue: only .md and .txt are supported", vim.log.levels.WARN)
    return
  end
  if vim.bo.modified then
    vim.cmd("write")
  end

  local line = opts.from_top and 1 or vim.api.nvim_win_get_cursor(0)[1]
  opts.title = vim.fn.fnamemodify(file, ":t") .. " @ line " .. line
  launch(file, line, opts)
end

------------------------------------------------------------------- codecompanion

---The chat buffer is a scratch buffer (nvim_create_buf(_, true)), so it has no
---path on disk. Find it: current buffer, else a visible one, else any loaded one.
local function find_chat_buf()
  if vim.bo.filetype == "codecompanion" then
    return vim.api.nvim_get_current_buf()
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "codecompanion" then
      return buf
    end
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "codecompanion" then
      return buf
    end
  end
  return nil
end

---Role headers render as "## <role>" (chat/ui/init.lua:307). Fence-aware, so a
---markdown heading inside a code block is not mistaken for one - same approach
---as chat_input_start() in codecompanion.lua.
---@return { line: integer, role: string }[]
local function chat_headers(lines)
  local fence, out = nil, {}
  for i, line in ipairs(lines) do
    local ticks = line:match("^%s*(```+)")
    if ticks then
      if not fence then
        fence = #ticks
      elseif #ticks >= fence then
        fence = nil
      end
    elseif not fence then
      local role = line:match("^##%s+(.+)$")
      if role then
        table.insert(out, { line = i, role = vim.trim(role) })
      end
    end
  end
  return out
end

local function user_role()
  local ok, cc = pcall(require, "codecompanion.config")
  if ok then
    local role = vim.tbl_get(cc, "interactions", "chat", "roles", "user")
    if type(role) == "string" then
      return role
    end
  end
  return "Me" -- upstream default
end

---lue reads fenced code verbatim, line by line (clean_visual_text passes
---__CODE_BLOCK__ lines through untouched), which is unlistenable in a coding
---transcript. Replace each block with a spoken marker instead.
local function strip_code(lines)
  local out, fence = {}, nil
  for _, line in ipairs(lines) do
    local ticks = line:match("^%s*(```+)")
    if ticks then
      if not fence then
        fence = #ticks
        table.insert(out, CODE_MARKER)
      elseif #ticks >= fence then
        fence = nil
      end
    elseif not fence then
      -- `> Context:` lines are chat plumbing, not prose.
      if not line:match("^>%s") then
        table.insert(out, line)
      end
    end
  end
  return out
end

local function read_chat(opts)
  opts = opts or {}

  local buf = find_chat_buf()
  if not buf then
    vim.notify("lue: no CodeCompanion chat buffer found", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local headers = chat_headers(lines)
  local slice, what

  if opts.whole then
    slice, what = lines, "whole chat"
  else
    -- Last LLM turn: the last header that is not yours. CodeCompanion appends a
    -- fresh "## Me" after each reply, so that is usually the second-to-last.
    local me = user_role()
    local start_idx, stop_idx = nil, #lines
    for i = #headers, 1, -1 do
      if headers[i].role ~= me then
        start_idx = headers[i].line + 1
        stop_idx = headers[i + 1] and (headers[i + 1].line - 1) or #lines
        break
      end
    end
    if not start_idx then
      vim.notify("lue: no LLM response in this chat yet", vim.log.levels.WARN)
      return
    end
    slice, what = vim.list_slice(lines, start_idx, stop_idx), "last reply"
  end

  local body = strip_code(slice)
  -- A reply that is nothing but code leaves only the markers behind; opening a
  -- TTS window to say "Code block omitted." is not worth it.
  local prose = vim.tbl_filter(function(l)
    return vim.trim(l) ~= "" and vim.trim(l) ~= CODE_MARKER
  end, body)
  if #prose == 0 then
    vim.notify("lue: nothing to read there (code only)", vim.log.levels.WARN)
    return
  end

  -- Stable path, so lue keeps one progress file rather than accumulating one
  -- per chat. lue-at reseeds the position on every launch anyway.
  local path = vim.fn.stdpath("cache") .. "/lue-codecompanion.md"
  vim.fn.writefile(body, path)

  opts.title = "CodeCompanion — " .. what
  launch(path, 1, opts)
end

------------------------------------------------------------------------ commands

vim.api.nvim_create_user_command("LueHere", function()
  read_from_cursor()
end, { desc = "Read aloud from cursor" })

vim.api.nvim_create_user_command("LueTop", function()
  read_from_cursor({ from_top = true })
end, { desc = "Read aloud from the top" })

vim.api.nvim_create_user_command("LueGerman", function()
  read_from_cursor({ lue_args = { "-t", "edge", "-v", "de-DE-ConradNeural" } })
end, { desc = "Read aloud in German (edge TTS)" })

vim.api.nvim_create_user_command("LueChat", function()
  read_chat()
end, { desc = "Read the last CodeCompanion reply aloud" })

vim.api.nvim_create_user_command("LueChatAll", function()
  read_chat({ whole = true })
end, { desc = "Read the whole CodeCompanion chat aloud" })

return {
  "folke/snacks.nvim",
  keys = {
    { "<leader>rr", "<cmd>LueHere<cr>",    desc = "Read aloud from cursor", ft = { "markdown", "text" } },
    { "<leader>rt", "<cmd>LueTop<cr>",     desc = "Read aloud from top",    ft = { "markdown", "text" } },
    { "<leader>rd", "<cmd>LueGerman<cr>",  desc = "Read aloud (German)",    ft = { "markdown", "text" } },
    { "<leader>rc", "<cmd>LueChat<cr>",    desc = "Read last CodeCompanion reply" },
    { "<leader>rC", "<cmd>LueChatAll<cr>", desc = "Read whole CodeCompanion chat" },
  },
}
