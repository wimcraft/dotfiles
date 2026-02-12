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
		"epwalsh/obsidian.nvim",
		version = "*", -- recommended, use latest release instead of latest commit
		cond = has_obsidian_vault,
		lazy = true,
		ft = "markdown",
		-- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
		-- event = {
		--   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
		--   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
		--   -- refer to `:h file-pattern` for more examples
		--   "BufReadPre path/to/my-vault/*.md",
		--   "BufNewFile path/to/my-vault/*.md",
		-- },
		dependencies = {
			-- Required.
			"nvim-lua/plenary.nvim",

			-- see below for full list of optional dependencies 👇
		},
		opts = {
			workspaces = {
				{
					name = "personal",
					path = obsidian_vault_path,
				},
			},
			completion = { nvim_cmp = true },

			daily_notes = {
				-- Optional, if you keep daily notes in a separate directory.
				folder = "Daily",
				-- Optional, if you want to change the date format for the ID of daily notes.
				-- date_format = "%Y-%m-%d",
				date_format = "%Y/%m-%B/%Y-%m-%d-%A", -- will create subfolders automatically
				-- Optional, if you want to change the date format of the default alias of daily notes.
				alias_format = "%B %-d, %Y",
				-- Optional, default tags to add to each new daily note created.
				-- default_tags = { "daily-notes" },
				-- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
				template = "Daily-note-template.md",
			},

			-- Optional, for templates (see below).
			templates = {
				folder = "Resources/Templates",
				-- date_format = "%Y-%m-%d",
				-- time_format = "%H:%M",
				-- A map for custom variables, the key should be the variable and the value a function
				-- substitutions = {},
			},

			-- see below for full list of options 👇
			disable_frontmatter = true,
			ui = {
				enable = false,
			},
		},
	},
}
