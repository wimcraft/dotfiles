-- focus.nvim — auto-resize whichever split you're working in.
--
-- On every WinEnter the active window grows toward a golden-ratio share of the
-- screen and its neighbours shrink; move back and the sizes swap. So a vertical
-- split stops meaning "two half-width windows forever" — the one under the
-- cursor always gets room to work in.
--
-- Only the resizing half of the plugin is used. focus.nvim can also toggle
-- per-window UI (number, cursorline, signcolumn…) as focus moves; that's all
-- left off here so it never fights LazyVim's own UI or the per-window tweaks in
-- diffview / render-markdown.
--
-- Keys hang off LazyVim's window group <leader>w:
--   <leader>wf  toggle auto-resize for the session
--   <leader>wF  maximise the current window / restore equal splits

-- Windows and buffers that must keep the width LazyVim (or the plugin itself)
-- handed them: the file tree, terminals, and assorted fixed side panels.
-- Current focus.nvim has no built-in exclude option, so this uses the autocmd
-- pattern from its README to set the per-window / per-buffer opt-out flag.
local ignore_filetypes = {
	"neo-tree",
	"snacks_dashboard",
	"lazy",
	"mason",
	"help",
	"qf",
	"trouble",
	"oil",
	"aerial",
	"Outline",
	"DiffviewFiles",
	"DiffviewFileHistory",
	"snacks_terminal",
}
local ignore_buftypes = { "nofile", "prompt", "popup", "terminal" }

return {
	"nvim-focus/focus.nvim",
	event = "VeryLazy",
	opts = {
		-- Grow the active window, but never squeeze a neighbour past these so the
		-- window you just left stays usable instead of collapsing to a sliver.
		autoresize = {
			minwidth = 20,
			minheight = 5,
			height_quickfix = 12,
		},
		-- Autoresize only — leave every per-window display option untouched.
		ui = {
			number = false,
			relativenumber = false,
			hybridnumber = false,
			absolutenumber_unfocussed = false,
			cursorline = false,
			cursorcolumn = false,
			signcolumn = false,
			colorcolumn = { enable = false },
			winhighlight = false,
		},
	},
	keys = {
		{ "<leader>wf", "<cmd>FocusToggle<cr>", desc = "Focus: toggle auto-resize" },
		{ "<leader>wF", "<cmd>FocusMaxOrEqual<cr>", desc = "Focus: maximise / equalise" },
	},
	config = function(_, opts)
		-- Autocmds on the same event run in definition order, so the opt-out flags
		-- below MUST be registered before focus.setup(). Otherwise focus's own
		-- WinEnter resizes a window first and the flag only lands afterwards —
		-- which is how the Claude terminal and diffview's file panel got blown up
		-- to golden-ratio width on first entry.
		local augroup = vim.api.nvim_create_augroup("FocusDisable", { clear = true })

		-- Buffer-level flag, so a window is protected as a *neighbour* too (focus
		-- restores flagged windows' sizes after growing the current one), not just
		-- once you've entered it.
		local function flag_buffer(buf)
			if not vim.api.nvim_buf_is_valid(buf) then
				return
			end
			local bo = vim.bo[buf]
			if vim.tbl_contains(ignore_buftypes, bo.buftype) or vim.tbl_contains(ignore_filetypes, bo.filetype) then
				vim.b[buf].focus_disable = true
			end
		end

		vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "FileType", "TermOpen" }, {
			group = augroup,
			callback = function(ev)
				flag_buffer(ev.buf)
			end,
			desc = "Disable focus auto-resize for ignored buftypes/filetypes",
		})

		-- buftype is often set after the buffer is already shown (snacks terminal,
		-- diffview panels), so catch the change itself as well.
		vim.api.nvim_create_autocmd("OptionSet", {
			group = augroup,
			pattern = "buftype",
			callback = function()
				flag_buffer(vim.api.nvim_get_current_buf())
			end,
			desc = "Disable focus auto-resize when buftype changes to an ignored one",
		})

		-- Diff mode (diffview, :diffthis) sizes its panes itself; auto-resize on
		-- top of that desyncs them. Follow the window's diff flag as it flips.
		vim.api.nvim_create_autocmd("OptionSet", {
			group = augroup,
			pattern = "diff",
			callback = function()
				vim.w.focus_disable = vim.wo.diff
			end,
			desc = "Disable focus auto-resize in diff mode",
		})

		require("focus").setup(opts)
	end,
}
