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
