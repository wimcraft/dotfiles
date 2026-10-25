-- tabout.nvim — jump past the closing bracket/quote with <Tab> instead of
-- typing or arrowing over it. Loads on InsertEnter, same trigger nvim-cmp
-- uses, since tabout only matters once you're inside a completion/insert
-- session with delimiters already on the line.

return {
	"abecodes/tabout.nvim",
	event = "InsertEnter",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"hrsh7th/nvim-cmp", -- tabout needs to know about cmp to not conflict with it
	},
	opts = {
		tabkey = "<Tab>",
		backwards_tabkey = "<S-Tab>",
		act_as_tab = true,
		act_as_shift_tab = false,
		enable_backwards = true,
		completion = true, -- if a completion menu is open, tab still confirms/navigates it first
		ignore_beginning = true,
		exclude = {},
	},
}
