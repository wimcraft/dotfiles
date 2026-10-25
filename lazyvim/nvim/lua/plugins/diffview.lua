-- diffview.nvim — full-window git diffs, file history, and a 3-way merge tool.
--
-- Complements what LazyVim already ships rather than replacing it:
--   * gitsigns  -> per-hunk inline diff (<leader>gh*), single buffer
--   * lazygit   -> staging / committing / branch work (<leader>gg)
--   * diffview  -> "show me the whole change" across every touched file, plus
--                  per-file/per-line history and conflict resolution.
--
-- All bindings live under <leader>gv (git → view). Every other <leader>g* slot
-- in LazyVim is taken; gv is free, so diffview gets its own subgroup.

-- Toggle: if any diffview tab is open, close it; otherwise run `cmd`. Without
-- this, hitting the open key twice stacks duplicate diffview tabs.
local function toggle(cmd)
	return function()
		local lib = require("diffview.lib")
		if lib.get_current_view() then
			vim.cmd("DiffviewClose")
		else
			vim.cmd(cmd)
		end
	end
end

-- Diff the working tree against where the current branch forked off the trunk,
-- i.e. "everything my branch changed" without the noise of trunk commits landed
-- since. Trunk name is detected (main vs master) instead of hardcoded.
local function diff_against_trunk()
	local function has_branch(name)
		return vim.fn.system({ "git", "rev-parse", "--verify", "--quiet", name }) ~= ""
	end
	local trunk = has_branch("main") and "main" or (has_branch("master") and "master" or nil)
	if not trunk then
		vim.notify("diffview: no main/master branch found", vim.log.levels.WARN)
		return
	end
	-- Triple-dot = merge-base diff (same semantics as a GitHub PR view).
	vim.cmd("DiffviewOpen " .. trunk .. "...HEAD --imply-local")
end

return {
	"sindrets/diffview.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	cmd = {
		"DiffviewOpen",
		"DiffviewClose",
		"DiffviewToggleFiles",
		"DiffviewFocusFiles",
		"DiffviewFileHistory",
		"DiffviewRefresh",
	},
	keys = {
		{ "<leader>gv", group = "diffview" },
		{ "<leader>gvv", toggle("DiffviewOpen"), desc = "Diffview: working tree" },
		{ "<leader>gvs", toggle("DiffviewOpen --cached"), desc = "Diffview: staged changes" },
		{ "<leader>gvH", toggle("DiffviewOpen HEAD~1"), desc = "Diffview: last commit" },
		{ "<leader>gvm", diff_against_trunk, desc = "Diffview: branch vs main (merge-base)" },
		{ "<leader>gvh", toggle("DiffviewFileHistory"), desc = "Diffview: repo history" },
		{ "<leader>gvf", toggle("DiffviewFileHistory %"), desc = "Diffview: current file history" },
		{ "<leader>gvl", ":DiffviewFileHistory<CR>", mode = "v", desc = "Diffview: history of selection" },
		{ "<leader>gvc", "<cmd>DiffviewClose<cr>", desc = "Diffview: close" },
		{ "<leader>gvt", "<cmd>DiffviewToggleFiles<cr>", desc = "Diffview: toggle file panel" },
		{ "<leader>gvr", "<cmd>DiffviewRefresh<cr>", desc = "Diffview: refresh" },
	},
	opts = function()
		local actions = require("diffview.actions")

		return {
			-- Highlight *within* changed lines (word-level), not just whole-line.
			enhanced_diff_hl = true,
			-- Show which file/rev each window holds — easy to lose track in 3-way merges.
			view = {
				default = { winbar_info = true },
				file_history = { winbar_info = true },
				merge_tool = {
					-- diff3_mixed: OURS | BASE+result | THEIRS. Seeing BASE is what makes
					-- a conflict resolvable; the default 3-way layout hides it.
					layout = "diff3_mixed",
					disable_diagnostics = true, -- LSP errors on conflict markers are noise
					winbar_info = true,
				},
			},
			file_panel = {
				listing_style = "tree",
				tree_options = { flatten_dirs = true, folder_statuses = "only_folded" },
				win_config = { position = "left", width = 32 },
			},
			file_history_panel = {
				win_config = { position = "bottom", height = 16 },
			},
			-- <C-h/j/k/l> are owned by nvim-tmux-navigation (see plugins/init.lua), so
			-- diffview's panel nav uses explicit keys instead of relying on those.
			keymaps = {
				view = {
					{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
					{ "n", "<leader>gvt", actions.toggle_files, { desc = "Toggle file panel" } },
					-- Conflict navigation + resolution (merge tool).
					{ "n", "]x", actions.next_conflict, { desc = "Next conflict" } },
					{ "n", "[x", actions.prev_conflict, { desc = "Prev conflict" } },
					{ "n", "<leader>co", actions.conflict_choose("ours"), { desc = "Conflict: take ours" } },
					{ "n", "<leader>ct", actions.conflict_choose("theirs"), { desc = "Conflict: take theirs" } },
					{ "n", "<leader>cb", actions.conflict_choose("base"), { desc = "Conflict: take base" } },
					{ "n", "<leader>ca", actions.conflict_choose("all"), { desc = "Conflict: take all" } },
					{ "n", "<leader>cx", actions.conflict_choose("none"), { desc = "Conflict: delete region" } },
				},
				file_panel = {
					{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
					{ "n", "<cr>", actions.focus_entry, { desc = "Open and focus the diff" } },
				},
				file_history_panel = {
					{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
					{ "n", "<cr>", actions.focus_entry, { desc = "Open and focus the diff" } },
					-- Review a whole commit from the history list, exactly like <leader>gvH
					-- does for HEAD~1. diffview binds this to <C-A-d> by default, which
					-- macOS terminals usually swallow (Option is Meta), so alias it to `O`.
					{ "n", "O", actions.open_in_diffview, { desc = "Review this commit (all files)" } },
				},
			},
			hooks = {
				-- focus.nvim auto-resize fights diffview's own pane layout (panel blows up,
				-- diff panes collapse to minwidth). Suspend it while a diffview tab is
				-- active and put back whatever state it had when we leave.
				view_enter = function()
					vim.t.focus_was_disabled = vim.g.focus_disable
					vim.g.focus_disable = true
				end,
				view_leave = function()
					vim.g.focus_disable = vim.t.focus_was_disabled
				end,
				diff_buf_read = function(bufnr)
					vim.b[bufnr].minianimate_disable = true
				end,
				-- Window options must be set here, not in diff_buf_read: that hook fires
				-- when the buffer is *created*, which is not necessarily inside the window
				-- it ends up displayed in, so `opt_local` lands on the wrong window.
				-- diff_buf_win_enter gets the actual winid.
				diff_buf_win_enter = function(_, winid)
					-- Wrapping and folds desync the two panes line-for-line.
					vim.wo[winid].wrap = false
					vim.wo[winid].foldenable = false
					vim.wo[winid].list = false
					-- Absolute numbers: relative ones are meaningless when comparing two
					-- files side by side.
					vim.wo[winid].relativenumber = false
					-- render-markdown/obsidian conceal hides characters, so the same line
					-- renders at different widths in each pane.
					vim.wo[winid].conceallevel = 0
				end,
			},
		}
	end,
	config = function(_, opts)
		require("diffview").setup(opts)
		-- linematch aligns changed lines inside a hunk instead of dumping them as one
		-- block. Neovim already defaults to linematch:40; bump the budget so bigger
		-- hunks (long functions, reflowed prose) still get aligned. Must *replace*
		-- the existing entry — appending leaves two linematch values in diffopt.
		local diffopt = vim.tbl_filter(function(v)
			return not v:match("^linematch:")
		end, vim.opt.diffopt:get())
		table.insert(diffopt, "linematch:60")
		vim.opt.diffopt = diffopt
	end,
}
