-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Treesitter: Error during download, please verify your internet connection
-- https://github.com/nvim-treesitter/nvim-treesitter/issues/3232#issuecomment-1397556657
-- require("nvim-treesitter.install").prefer_git = true

vim.keymap.set("n", "<leader>,", ":qa!<CR>", { desc = "Quit without saving", noremap = true, silent = true })
vim.keymap.set(
	"n",
	"<leader>ba",
	":lua require('cmp').setup.buffer { enabled = false }<CR>",
	{ desc = "Disable autocomplete", noremap = true, silent = true }
)
vim.keymap.set("v", "<c-Y>", '"+y')
vim.keymap.set("i", "<c-l>", "<c-^>")
vim.keymap.set("n", "<leader>fu", "gr")
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true, desc = "Exit terminal mode" })
vim.opt.keymap = "ukrainian-enhanced"
vim.opt.iminsert = 0
vim.opt.imsearch = 0
vim.opt.lbr = true
-- default colorscheme
vim.cmd("colorscheme tokyonight-storm")

if vim.g.neovide then
	vim.keymap.set({ "n", "v" }, "<C-+>", ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1<CR>")
	vim.keymap.set({ "n", "v" }, "<C-->", ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1<CR>")
	vim.keymap.set({ "n", "v" }, "<C-0>", ":lua vim.g.neovide_scale_factor = 1<CR>")
end

-- vim.cmd("lmap F	А| lmap <	Б| lmap D	В|")

-- Desc: Configuration for lualine to show the current keymap in insert mode
-- https://github.com/nvim-lualine/lualine.nvim/issues/368
local function keymap()
	if vim.opt.iminsert:get() > 0 and vim.b.keymap_name then
		return vim.b.keymap_name
	end
	return ""
end
require("lualine").setup({
	sections = {
		lualine_a = { "mode", { keymap, icon = "⌨" } },
	},
})

-- Clipboard configuration: use OSC52 over SSH, system clipboard locally
if os.getenv("SSH_TTY") then
	vim.g.clipboard = {
		name = "OSC 52",
		copy = {
			["+"] = require("vim.ui.clipboard.osc52").copy("+"),
			["*"] = require("vim.ui.clipboard.osc52").copy("*"),
		},
		paste = {
			["+"] = require("vim.ui.clipboard.osc52").paste("+"),
			["*"] = require("vim.ui.clipboard.osc52").paste("*"),
		},
	}
end
