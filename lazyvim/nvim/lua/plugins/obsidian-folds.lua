return {
	{
		"LazyVim/LazyVim",
		opts = {},
		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "markdown",
				callback = function()
					vim.wo.foldmethod = "marker"
					vim.wo.foldlevel = 0
				end,
			})
		end,
	},
}
