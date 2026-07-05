local obsidian_vault_path = os.getenv("OBSIDIAN_VAULT_PATH")
local obsidian_work_vault_path = os.getenv("OBSIDIAN_WORK_VAULT_PATH")
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
				vim.keymap.set("n", "<leader>ha", function()
					local harpoon = require("harpoon")
					toggle_telescope_with_harpoon(harpoon:list())
				end, { desc = "Open harpoon window" })
			end,
			keys = {
				{
					"<leader>hA",
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
			{ "<leader>op", "<cmd>Obsidian new_from_template pion.nvim.t.md<cr>", desc = "New Pion" },
			{ "<leader>os", "<cmd>Obsidian search<cr>", desc = "Obsidian search" },
			{ "<leader>oq", "<cmd>Obsidian quick_switch<cr>", desc = "Obsidian quick switch" },
			{ "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Obsidian backlinks" },
		},
		opts = {
			legacy_commands = false,
			workspaces = {
				{
					name = "personal",
					path = obsidian_vault_path,
				},
				{
					name = "work",
					path = obsidian_work_vault_path,
				},
			},
			new_notes_location = "notes_subdir",
			notes_subdir = "Atrium",

			note_id_func = function(title)
				if title == nil then
					return tostring(os.time())
				end
				return title:lower():gsub("%s+", "-"):gsub("[^%w%-]", "")
			end,

			daily_notes = {
				folder = "Daily",
				-- date_format uses moment.js syntax (YYYY/MM/DD), not strftime (%Y/%m/%d)
				date_format = "YYYY/MM-MMMM/YYYY-MM-DD-dddd", -- will create subfolders automatically
				alias_format = "MMMM D, YYYY",
				template = "daily.nvim.t.md",
			},

			templates = {
				folder = "Zulo/templates",
				substitutions = {
					created = function()
						return os.date("%Y-%m-%d,%H:%M")
					end,
					daily_heading = function()
						return os.date("%A, %B %d, %Y")
					end,
					daily_carpe = function()
						return os.date("%B %d")
					end,
				},
				customizations = {
					["pion.nvim.t"] = {
						notes_subdir = "Engrams/Pions",
						note_id_func = function(title)
							if title == nil then
								return tostring(os.time())
							end
							return title:lower():gsub("%s+", "-"):gsub("[^%w%-]", "")
						end,
					},
				},
			},

			frontmatter = { enabled = false },
			ui = {
				enable = false,
			},
		},
	},
	{
		"tiagovla/scope.nvim",
		config = true,
	},
	{
		"michaelb/sniprun",
		build = "sh install.sh",
		cmd = { "SnipRun", "SnipClose", "SnipReset", "SnipReplMode" },
		keys = {
			{ "<leader>Sr", "<Plug>SnipRun", mode = "n", desc = "Sniprun line" },
			{ "<leader>Sr", "<Plug>SnipRun", mode = "v", desc = "Sniprun selection" },
			{ "<leader>SR", "<Plug>SnipRunOperator", mode = "n", desc = "Sniprun operator" },
			{ "<leader>Sc", "<cmd>SnipClose<cr>", mode = "n", desc = "Sniprun close" },
			{ "<leader>Sx", "<cmd>SnipReset<cr>", mode = "n", desc = "Sniprun reset" },
		},
		opts = {
			-- VirtualText: inline result at end of line (always visible, never clips
			-- off-screen like the cursor-anchored floating window did near EOF).
			-- Terminal: persistent right split with full output + errors + scrollback.
			display = { "VirtualTextOk", "VirtualTextErr", "Terminal" },
			live_mode_toggle = "off",
		},
	},
	{
		"coder/claudecode.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
		opts = {
			terminal = {
				provider = "snacks",
				split_side = "right",
				split_width_percentage = 0.40,
				snacks_win_opts = {
					-- no `position` key -> snacks uses split_side (a real split, not a float)
					keys = {
						claude_hide = {
							"<C-,>",
							function(self)
								self:hide()
							end,
							mode = "t",
							desc = "Hide Claude",
						},
						-- escape terminal mode back to normal mode
						claude_normal = {
							"<C-q>",
							"<C-\\><C-n>",
							mode = "t",
							desc = "Terminal normal mode",
						},
						-- <C-h/j/k/l> window nav in terminal mode is provided by
						-- snacks' own defaults; don't redefine here (Snacks warns
						-- on duplicate keymaps).
					},
				},
			},
			diff_opts = {
				layout = "vertical",
				open_in_new_tab = false,
				keep_terminal_focus = false,
			},
		},
		keys = {
			{ "<C-,>", "<cmd>ClaudeCodeFocus<cr>", desc = "Toggle Claude", mode = { "n", "x" } },
			{ "<leader>a", "<cmd>ClaudeCodeFocus<cr>", desc = "Toggle Claude" },
			{ "<leader>ac", "<cmd>ClaudeCodeChat<cr>", desc = "Claude new chat" },
			{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
			{ "<leader>aa", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add file to Claude" },
			{ "<leader>ay", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Claude diff" },
			{ "<leader>an", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny Claude diff" },
		},
	},
	{
		"stevearc/oil.nvim",
		---@module 'oil'
		---@type oil.SetupOpts
		opts = {},
		-- Optional dependencies
		dependencies = { { "nvim-mini/mini.icons", opts = {} } },
		-- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
		-- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
		lazy = false,
	},
	-- obsidian-various-complements style completion for markdown:
	--   * cmp-rg        -> autocomplete any word that appears anywhere in the vault
	--   * cmp-dictionary -> autocomplete from custom word-list files in nvim/dict/*.dict
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"lukas-reineke/cmp-rg",
			{
				"uga-rosa/cmp-dictionary",
				config = function()
					require("cmp_dictionary").setup({
						paths = vim.fn.split(vim.fn.glob(vim.fn.stdpath("config") .. "/dict/*.dict"), "\n"),
						exact_length = 2,
						first_case_insensitive = true,
					})
				end,
			},
		},
		opts = function(_, opts)
			local cmp = require("cmp")

			-- Resolve which vault the current note lives in so ripgrep searches the
			-- right tree (cmp-rg's cwd is fixed per source config, hence per-buffer).
			local function vault_for(path)
				for _, v in ipairs({ obsidian_vault_path, obsidian_work_vault_path }) do
					if v and v:match("%S") and path:sub(1, #v) == v then
						return v
					end
				end
				return vim.fn.getcwd()
			end

			local function setup_md_buffer(buf)
				local vault = vault_for(vim.api.nvim_buf_get_name(buf))
				local sources = vim.deepcopy(opts.sources or {})
				table.insert(sources, {
					name = "rg",
					keyword_length = 3,
					group_index = 1,
					option = {
						cwd = vault,
						additional_arguments = "--glob '*.md' --max-depth 8",
					},
				})
				table.insert(sources, {
					name = "dictionary",
					keyword_length = 2,
					group_index = 1,
				})
				vim.api.nvim_buf_call(buf, function()
					cmp.setup.buffer({ sources = sources })
				end)
			end

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "markdown",
				callback = function(ev)
					setup_md_buffer(ev.buf)
				end,
			})

			-- nvim-cmp loads lazily (InsertEnter), so a markdown buffer opened before
			-- the first insert already fired FileType — apply sources to it now too.
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "markdown" then
					setup_md_buffer(buf)
				end
			end

			return opts
		end,
	},
	-- ltex-ls (LanguageTool) code actions that actually work in Neovim:
	-- "Add to dictionary" / "Hide false positive" / "Disable rule" are client-side
	-- commands vanilla nvim ignores; ltex_extra implements them and persists picks
	-- to files under nvim/ltex/ so they survive restarts.
	{
		"neovim/nvim-lspconfig",
		dependencies = { "barreiroleo/ltex_extra.nvim" },
		opts = {
			servers = {
				ltex = {
					on_attach = function(_, _)
						require("ltex_extra").setup({
							load_langs = { "en-US", "de-DE" },
							init_check = true,
							path = vim.fn.stdpath("config") .. "/ltex",
							log_level = "none",
						})
					end,
					settings = {
						ltex = {
							-- Default language. Override per note (or per section) with a
							-- magic comment placed BEFORE the text it applies to:
							--   German block:   <!-- LTeX: language=de-DE -->
							--   English block:  <!-- LTeX: language=en-US -->
							--   Disable a note: <!-- LTeX: enabled=false -->
							-- Multiple comments in one file switch language per section.
							language = "en-US",
							-- Native language -> false-friend detection (English-interference
							-- errors when writing German). Diagnostic messages stay in the
							-- checked language; LTeX has no setting to translate them.
							additionalRules = {
								motherTongue = "en-US",
							},
						},
					},
				},
			},
		},
	},
	{ "wakatime/vim-wakatime", lazy = false },
}
