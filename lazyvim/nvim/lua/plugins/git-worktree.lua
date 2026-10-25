return {
  {
    "ThePrimeagen/git-worktree.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("git-worktree").setup({
        -- Use :cd so the selected worktree becomes Neovim's active cwd.
        change_directory_command = "cd",
      })
      require("telescope").load_extension("git_worktree")
    end,
    keys = {
      {
        "<leader>gw",
        "<cmd>Telescope git_worktree git_worktrees<cr>",
        desc = "Switch Git Worktree",
      },
      {
        "<leader>gW",
        "<cmd>Telescope git_worktree create_git_worktree<cr>",
        desc = "Create Git Worktree",
      },
    },
  },
}
