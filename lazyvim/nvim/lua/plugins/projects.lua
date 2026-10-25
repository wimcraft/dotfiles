-- Project switcher on <leader>pp (like Doom Emacs), using snacks' built-in
-- projects picker instead of the util.project extra, which only supports
-- telescope/fzf-lua. The dashboard's own "p" key opens the same picker.
--
-- Projects come from the git roots of files you've opened, so opening a repo once
-- adds it. `dev` scanning of parent folders is switched off, and extra directories
-- can go in `projects` below if a project should always be listed.
return {
	"folke/snacks.nvim",
	keys = {
		{ "<leader>p", group = "project" },
		{
			"<leader>pp",
			function()
				Snacks.picker.projects()
			end,
			desc = "Projects",
		},
	},
	opts = {
		picker = {
			sources = {
				projects = {
					dev = {},
					-- projects = { "~/dotfiles" },
				},
			},
		},
	},
}
