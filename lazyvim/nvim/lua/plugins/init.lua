local obsidian_vault_path = os.getenv("OBSIDIAN_VAULT_PATH")
local has_obsidian_vault = obsidian_vault_path ~= nil and obsidian_vault_path:match("%S") ~= nil

return {
	-- add tmux integration
	{ "christoomey/vim-tmux-navigator" },
	-- add ukrainian language support
	{ "vim-scripts/ukrainian-enhanced.vim" },
	-- pairs of handy bracket mappings
	{ "tpope/vim-unimpaired" },
	--  helpers for UNIX
	{ "tpope/vim-eunuch" },
	-- zen mode
	{ "folke/zen-mode.nvim" },
	-- todo.txt mode
	{
		"freitass/todo.txt-vim",
		ft = "todo", -- Lazy-loads the plugin only when opening a todo.txt file
	},
	-- tmux navigation
	{
		"alexghergh/nvim-tmux-navigation",
		config = function()
			require("nvim-tmux-navigation").setup({
				disable_when_zoomed = true, -- defaults to false
				keybindings = {
					left = "<C-h>",
					down = "<C-j>",
					up = "<C-k>",
					right = "<C-l>",
					last_active = "<C-\\>",
					next = "<C-Space>",
				},
			})
		end,
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" }, -- if you use the mini.nvim suite
		-- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
		-- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
		---@module 'render-markdown'
		---@type render.md.UserConfig
		opts = {},
	},
	{
		-- Harpoon plugin configuration
		{
			"ThePrimeagen/harpoon",
			branch = "harpoon2",
			lazy = false,
			requires = { "nvim-lua/plenary.nvim" }, -- if harpoon requires this
			config = function()
				require("harpoon").setup({})

				local function toggle_telescope_with_harpoon(harpoon_files)
					local file_paths = {}
					for _, item in ipairs(harpoon_files.items) do
						table.insert(file_paths, item.value)
					end

					require("telescope.pickers")
						.new({}, {
							prompt_title = "Harpoon",
							finder = require("telescope.finders").new_table({
								results = file_paths,
							}),
							previewer = require("telescope.config").values.file_previewer({}),
							sorter = require("telescope.config").values.generic_sorter({}),
						})
						:find()
				end
				vim.keymap.set("n", "<leader>a", function()
					local harpoon = require("harpoon")
					toggle_telescope_with_harpoon(harpoon:list())
				end, { desc = "Open harpoon window" })
			end,
			keys = {
				{
					"<leader>A",
					function()
						require("harpoon"):list():append()
					end,
					desc = "harpoon file",
				},
				{
					"<C-b>",
					function()
						local harpoon = require("harpoon")
						harpoon.ui:toggle_quick_menu(harpoon:list())
					end,
					desc = "harpoon quick menu",
				},
				{
					"<leader>1",
					function()
						require("harpoon"):list():select(1)
					end,
					desc = "harpoon to file 1",
				},
				{
					"<leader>2",
					function()
						require("harpoon"):list():select(2)
					end,
					desc = "harpoon to file 2",
				},
				{
					"<leader>3",
					function()
						require("harpoon"):list():select(3)
					end,
					desc = "harpoon to file 3",
				},
			},
		},
	},
	{
		"obsidian-nvim/obsidian.nvim",
		version = "*",
		cond = has_obsidian_vault,
		lazy = true,
		ft = "markdown",
		keys = {
			{ "<leader>oo", "<cmd>Obsidian<cr>", desc = "Obsidian" },
			{ "<leader>ot", "<cmd>Obsidian today<cr>", desc = "Obsidian today" },
			{ "<leader>oy", "<cmd>Obsidian yesterday<cr>", desc = "Obsidian yesterday" },
			{ "<leader>on", "<cmd>Obsidian new<cr>", desc = "Obsidian new note" },
			{ "<leader>os", "<cmd>Obsidian search<cr>", desc = "Obsidian search" },
			{ "<leader>oq", "<cmd>Obsidian quick_switch<cr>", desc = "Obsidian quick switch" },
		},
		opts = {
			legacy_commands = false,
			workspaces = {
				{
					name = "personal",
					path = obsidian_vault_path,
				},
			},
			completion = { nvim_cmp = true },

			daily_notes = {
				folder = "Daily",
				-- date_format uses moment.js syntax (YYYY/MM/DD), not strftime (%Y/%m/%d)
				date_format = "YYYY/MM-MMMM/YYYY-MM-DD-dddd", -- will create subfolders automatically
				alias_format = "MMMM D, YYYY",
				template = "Daily-note-template.md",
			},

			templates = {
				folder = "Resources/Templates",
			},

			frontmatter = { enabled = false },
			ui = {
				enable = false,
			},
		},
	},
}
