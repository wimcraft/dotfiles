-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
vim.keymap.del("n",  "<leader>cd")
vim.keymap.set("n", "<leader>cd", ":lcd %:p:h<CR>", { desc = "Change working directory" })

local nvim_tmux_nav = require('nvim-tmux-navigation')

nvim_tmux_nav.setup {
    disable_when_zoomed = true -- defaults to false
}

vim.keymap.set('n', "<C-h>", nvim_tmux_nav.NvimTmuxNavigateLeft)
vim.keymap.set('n', "<C-j>", nvim_tmux_nav.NvimTmuxNavigateDown)
vim.keymap.set('n', "<C-k>", nvim_tmux_nav.NvimTmuxNavigateUp)
vim.keymap.set('n', "<C-l>", nvim_tmux_nav.NvimTmuxNavigateRight)
vim.keymap.set('n', "<C-\\>", nvim_tmux_nav.NvimTmuxNavigateLastActive)
vim.keymap.set('n', "<C-Space>", nvim_tmux_nav.NvimTmuxNavigateNext)

-- Custom text objects for easier access to quotes, brackets, and words
-- quicker access to [m]assive word, [q]uote, [z]ingle quote, inline cod[e],
-- [r]ectangular bracket, and [c]urly braces
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Operator-pending mode (like 'd', 'c', 'y', 'v', etc.)
-- Massive word
keymap("o", "am", "aW", opts)
keymap("o", "im", "iW", opts)

-- Double quotes
keymap("o", "aq", 'a"', opts)
keymap("o", "iq", 'i"', opts)
keymap("o", "k", 'i"', opts) -- Shortcut for inner quote?

-- Single quotes
keymap("o", "az", "a'", opts)
keymap("o", "iz", "i'", opts)

-- Inline code (backticks)
keymap("o", "ae", "a`", opts)
keymap("o", "ie", "i`", opts)

-- Square brackets
keymap("o", "ar", "a[", opts)
keymap("o", "ir", "i[", opts)

-- Curly braces
keymap("o", "ac", "a{", opts)
keymap("o", "ic", "i{", opts)

-- Same for visual mode
keymap("x", "am", "aW", opts)
keymap("x", "im", "iW", opts)
keymap("x", "aq", 'a"', opts)
keymap("x", "iq", 'i"', opts)
keymap("x", "az", "a'", opts)
keymap("x", "iz", "i'", opts)
keymap("x", "ae", "a`", opts)
keymap("x", "ie", "i`", opts)
keymap("x", "ar", "a[", opts)
keymap("x", "ir", "i[", opts)
keymap("x", "ac", "a{", opts)
keymap("x", "ic", "i{", opts)

vim.keymap.set("n", "<leader>ip", function() Snacks.image.hover() end, { desc = "Image preview" })

-- Emacs-style M-x: fuzzy search all Ex commands
vim.keymap.set("n", "<leader>;", function() Snacks.picker.commands() end, { desc = "Commands (M-x)" })
vim.keymap.set({ "n", "i" }, "<M-x>", function() Snacks.picker.commands() end, { desc = "Commands (M-x)" })

-- Insert absolute file path(s) at the cursor.
-- Mainly for the Claude Code prompt buffer (ctrl+g opens it in $EDITOR), where
-- `@`-completion only reaches the session's working directories. The plain
-- mapping picks from the current root; the capitalized one asks for a directory
-- first, so files anywhere on disk are reachable. Multi-select (<Tab> in the
-- picker) inserts space-separated paths.
--
-- No alt mappings here: AeroSpace owns most alt keys globally (alt-f is
-- 'fullscreen'). Insert mode uses a <C-x> chord because every plain <C-…> key
-- worth having is already taken by cmp; plain "f" after <C-x> shadows no native
-- completion sequence, which only accepts control keys.
-- The target position must be captured before any floating window (picker or
-- directory prompt) steals focus, otherwise the paths land in the float.
local function capture_target()
  local win = vim.api.nvim_get_current_win()
  return {
    win = win,
    buf = vim.api.nvim_get_current_buf(),
    cursor = vim.api.nvim_win_get_cursor(win),
    insert = vim.api.nvim_get_mode().mode:sub(1, 1) == "i",
  }
end

local function insert_file_path(cwd, target)
  target = target or capture_target()
  local win, buf = target.win, target.buf
  local row, col = unpack(target.cursor)
  local was_insert = target.insert

  Snacks.picker.files({
    cwd = cwd,
    confirm = function(picker)
      local items = picker:selected({ fallback = true })
      picker:close()

      local paths = {}
      for _, item in ipairs(items) do
        local path = Snacks.picker.util.path(item)
        if path then
          table.insert(paths, path)
        end
      end
      if #paths == 0 then
        return
      end

      local text = table.concat(paths, " ")
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        vim.api.nvim_buf_set_text(buf, row - 1, col, row - 1, col, { text })
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_set_current_win(win)
          pcall(vim.api.nvim_win_set_cursor, win, { row, col + #text })
          if was_insert then
            vim.cmd("startinsert")
          end
        end
      end)
    end,
  })
end

local function insert_file_path_from_dir()
  local target = capture_target()
  vim.ui.input({ prompt = "Pick files from directory: ", default = "~/", completion = "dir" }, function(dir)
    if dir and dir ~= "" then
      insert_file_path(vim.fn.expand(dir), target)
    end
  end)
end

vim.keymap.set("n", "<leader>if", function() insert_file_path() end, { desc = "Insert file path" })
vim.keymap.set("n", "<leader>iF", insert_file_path_from_dir, { desc = "Insert file path (choose dir)" })
vim.keymap.set("i", "<C-x>f", function() insert_file_path() end, { desc = "Insert file path" })
vim.keymap.set("i", "<C-x>F", insert_file_path_from_dir, { desc = "Insert file path (choose dir)" })

-- Fast prose input for German and Polish without switching the Ukrainian keymap.
-- Scoped to prose buffers so code keeps plain ASCII insert behavior.
local prose_input_filetypes = { "markdown", "markdown.mdx", "mdx", "text", "txt", "asciidoc", "org" }
local prose_input_maps = {
  -- German
  { ";a", "ä", "German ä" },
  { ";A", "Ä", "German Ä" },
  { ";o", "ö", "German ö" },
  { ";O", "Ö", "German Ö" },
  { ";u", "ü", "German ü" },
  { ";U", "Ü", "German Ü" },
  { ";s", "ß", "German ß" },
  { ";S", "ẞ", "German ẞ" },
  { ";9", "„", "German opening quote" },
  { ";6", "“", "German closing quote" },

  -- Polish: keep a separate ;p prefix so German mappings stay unambiguous.
  { ";pa", "ą", "Polish ą" },
  { ";pA", "Ą", "Polish Ą" },
  { ";pc", "ć", "Polish ć" },
  { ";pC", "Ć", "Polish Ć" },
  { ";pe", "ę", "Polish ę" },
  { ";pE", "Ę", "Polish Ę" },
  { ";pl", "ł", "Polish ł" },
  { ";pL", "Ł", "Polish Ł" },
  { ";pn", "ń", "Polish ń" },
  { ";pN", "Ń", "Polish Ń" },
  { ";po", "ó", "Polish ó" },
  { ";pO", "Ó", "Polish Ó" },
  { ";ps", "ś", "Polish ś" },
  { ";pS", "Ś", "Polish Ś" },
  { ";px", "ź", "Polish ź" },
  { ";pX", "Ź", "Polish Ź" },
  { ";pz", "ż", "Polish ż" },
  { ";pZ", "Ż", "Polish Ż" },
}
for _, map in ipairs(prose_input_maps) do
  vim.keymap.set("i", map[1], map[2], {
    noremap = true,
    silent = true,
    desc = "Insert " .. map[3],
  })
end


-- Obsidian vault backup: save all buffers, stage *.md, commit with timestamp, push
vim.keymap.set("n", "<leader>oc", function()
  local vault = os.getenv("OBSIDIAN_VAULT_PATH")
  if not vault or vault:match("^%s*$") then
    vim.notify("OBSIDIAN_VAULT_PATH is not set", vim.log.levels.ERROR)
    return
  end
  vim.cmd("silent! wa")
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local msg = "obsidian.nvim vault backup: " .. timestamp
  vim.fn.system("git -C '" .. vault .. "' add -- '*.md'")
  local commit_out = vim.fn.system("git -C '" .. vault .. "' commit -m '" .. msg .. "'")
  if vim.v.shell_error ~= 0 then
    vim.notify("Nothing to commit\n" .. commit_out, vim.log.levels.WARN)
    return
  end
  vim.notify("Committed: " .. msg .. "\nPushing...", vim.log.levels.INFO)
  vim.fn.jobstart("git -C '" .. vault .. "' push", {
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 then
          vim.notify("Vault backup pushed", vim.log.levels.INFO)
        else
          vim.notify("Push failed (exit " .. code .. ")", vim.log.levels.ERROR)
        end
      end)
    end,
  })
end, { desc = "Obsidian vault backup" })

-- Markdown checklists: continue "- [ ] " on <CR> instead of retyping it.
-- Backspace on an empty marker exits the list. Works in any markdown
-- buffer, not just notes inside the Obsidian vault.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "markdown.mdx", "mdx" },
  callback = function(ev)
    vim.keymap.set("i", "<CR>", function()
      local indent, bullet = vim.api.nvim_get_current_line():match("^(%s*)([-*+]) %[.%] ")
      if not bullet then
        return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
      end
      return vim.api.nvim_replace_termcodes("<CR>" .. indent .. bullet .. " [ ] ", true, false, true)
    end, { buffer = ev.buf, expr = true, desc = "Continue markdown checklist" })
  end,
})
