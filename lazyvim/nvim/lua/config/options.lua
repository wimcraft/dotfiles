local opt = vim.opt

opt.clipboard = ""
-- Disable spellchecking by default
vim.opt.spell = false
vim.opt.spelllang = { "en", "de", "pl", "uk" }

-- Neovide font configuration
vim.o.guifont = "JetBrainsMono Nerd Font Mono:h14"

-- Conjure is here only because of the lazyvim lang.clojure extra, but it claims
-- ~19 filetypes by default and auto-starts a REPL subprocess whenever one of them
-- loads — including javascript/typescript (node), python, ruby, sql. Two problems:
--
--   1. Opening any .js/.ts file silently spawns a node REPL nobody asked for.
--   2. It throws inside diffview. Conjure guards its auto-start with
--      `not vim.wo.diff` (conjure/client.lua:57), but reads that flag *before*
--      diffview turns diff on for the window, so the guard passes; it then
--      `vim.schedule`s on-load, which runs once the current buffer is a different
--      one (the diffview panel). The js client's repl_command_for_filetype() reads
--      `vim.bo.filetype` of whatever is current *then*, gets no match, returns nil,
--      and concatenating nil raises. Hence the error on <leader>gvH in a JS repo.
--
-- Restricting the list to the lisps conjure is actually wanted for fixes both: its
-- javascript client is never loaded, so there is nothing to misfire. Set here rather
-- than in a plugin spec because conjure reads this at `conjure.main.main()` time, and
-- overriding the spec's `init` would clobber LazyVim's (K/gd mappings, log autocmd).
-- Add a filetype back to this list to get conjure's REPL for it again.
vim.g["conjure#filetypes"] = { "clojure", "fennel" }

