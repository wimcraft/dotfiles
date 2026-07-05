return {
	{
		"folke/lazy.nvim",
		opts = {
			checker = {
				enabled = false,
				notify = false,
			},
		},
	},
	-- change trouble config
	{
		"nvim-telescope/telescope.nvim",
		keys = {
			-- disable the keymap to grep files
			{ "<leader>,", false },
			-- disable the keymap for line diagnostics
			{ "<leader>cd", vim.NIL },
		},
		opts = {
			defaults = {
				file_ignore_patterns = { "node_modules", ".git" },
			},
		},
	},
	{
		"ibhagwan/fzf-lua",
		keys = {
			-- disable the keymap for buffer navigation
			{ "<leader>,", false },
		},
	},
	-- Override copilot config to disable for markdown files
	--     {
	--       "zbirenbaum/copilot.lua",
	--       opts = {
	--         filetypes = {
	--           markdown = false,
	--           -- you can disable for other filetypes here as well
	--         },
	--       },
	--     },

	{
		"folke/snacks.nvim",
		opts = {
			image = {
				doc = {
					float = false,
				},
				resolve = function(path, src)
					if vim.startswith(src, "http://") or vim.startswith(src, "https://") then
						return src
					end
					local api = require("obsidian.api")
					if not api.path_is_note(path) then
						return
					end
					local client = require("obsidian").get_client()
					if not client then
						return
					end
					local vault = tostring(Obsidian.workspace.path)
					local matches = vim.fn.glob(vault .. "/**/" .. src, false, true)
					if #matches > 0 then
						return matches[1]
					end
				end,
			},
		},
	},

	-- Disable markdown lin
	{
		"mfussenegger/nvim-lint",
		opts = {
			linters_by_ft = {
				markdown = {}, -- Empty table disables linters for markdown
			},
		},
	},
}
