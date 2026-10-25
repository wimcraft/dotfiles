return {
  {
    "danymat/neogen",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    cmd = "Neogen",
    keys = {
      {
        "<leader>cn",
        function()
          require("neogen").generate()
        end,
        desc = "Generate Annotations",
      },
    },
    opts = {
      snippet_engine = "nvim",
      languages = {
        lua = { template = { annotation_convention = "emmylua" } },
      },
    },
  },
}
