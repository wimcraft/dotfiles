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
              file_ignore_patterns = { 'node_modules', '.git'},
            },
          },
  },
  {
      "ibhagwan/fzf-lua",
      keys = {
        -- disable the keymap for buffer navigation
         { "<leader>,", false }
      }
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
