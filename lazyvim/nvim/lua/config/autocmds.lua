-- List callouts: color list items that start with a special symbol,
-- mirroring the "List callouts" Obsidian plugin.
--
-- Supported symbols:
--   !  warnings      red
--   $  good news     green
--   &  insights      purple
--   @  facts         blue
--   ~  feelings      pink
--   %  notes         yellow

local ns = vim.api.nvim_create_namespace("list_callouts")

local callouts = {
	["!"] = { line_hl = "ListCalloutWarningLine", sym_hl = "ListCalloutWarning" },
	["$"] = { line_hl = "ListCalloutGoodNewsLine", sym_hl = "ListCalloutGoodNews" },
	["&"] = { line_hl = "ListCalloutInsightLine", sym_hl = "ListCalloutInsight" },
	["@"] = { line_hl = "ListCalloutFactLine", sym_hl = "ListCalloutFact" },
	["~"] = { line_hl = "ListCalloutFeelingLine", sym_hl = "ListCalloutFeeling" },
	["%"] = { line_hl = "ListCalloutNoteLine", sym_hl = "ListCalloutNote" },
}

local function setup_highlights()
	vim.api.nvim_set_hl(0, "ListCalloutWarningLine", { bg = "#3d2020" })
	vim.api.nvim_set_hl(0, "ListCalloutWarning", { fg = "#f7768e", bold = true })
	vim.api.nvim_set_hl(0, "ListCalloutGoodNewsLine", { bg = "#1e3a2a" })
	vim.api.nvim_set_hl(0, "ListCalloutGoodNews", { fg = "#9ece6a", bold = true })
	vim.api.nvim_set_hl(0, "ListCalloutInsightLine", { bg = "#2e2a10" })
	vim.api.nvim_set_hl(0, "ListCalloutInsight", { fg = "#e0af68", bold = true })
	vim.api.nvim_set_hl(0, "ListCalloutFactLine", { bg = "#0f2d30" })
	vim.api.nvim_set_hl(0, "ListCalloutFact", { fg = "#56d4dd", bold = true })
	vim.api.nvim_set_hl(0, "ListCalloutFeelingLine", { bg = "#1a1a3d" })
	vim.api.nvim_set_hl(0, "ListCalloutFeeling", { fg = "#8087f5", bold = true })
	vim.api.nvim_set_hl(0, "ListCalloutNoteLine", { bg = "#252525" })
	vim.api.nvim_set_hl(0, "ListCalloutNote", { fg = "#9e9e9e", bold = true })
end

local function apply_callouts(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	for i, line in ipairs(lines) do
		for symbol, hl in pairs(callouts) do
			-- match: indent? list-marker space symbol space-or-end
			if line:match("^%s*[-*+]%s+" .. vim.pesc(symbol) .. "%s") then
				vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
					line_hl_group = hl.line_hl,
				})
				local col = line:find(vim.pesc(symbol), 1, true)
				if col then
					vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, col - 1, {
						end_col = col,
						hl_group = hl.sym_hl,
					})
				end
				break
			end
		end
	end
end

local timers = {}

local function apply_callouts_debounced(bufnr)
	if timers[bufnr] then
		timers[bufnr]:stop()
	end
	timers[bufnr] = vim.defer_fn(function()
		timers[bufnr] = nil
		if vim.api.nvim_buf_is_valid(bufnr) then
			apply_callouts(bufnr)
		end
	end, 150)
end

local group = vim.api.nvim_create_augroup("ListCallouts", { clear = true })

setup_highlights()

vim.api.nvim_create_autocmd("ColorScheme", {
	group = group,
	callback = setup_highlights,
})

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
	group = group,
	pattern = "*.md",
	callback = function(ev)
		apply_callouts(ev.buf)
	end,
})

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
	group = group,
	pattern = "*.md",
	callback = function(ev)
		apply_callouts_debounced(ev.buf)
	end,
})
