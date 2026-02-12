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
