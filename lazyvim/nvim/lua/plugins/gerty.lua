-- K in prose buffers looks up the word under the cursor instead of LSP hover.
local prose = {
	markdown = true,
	["markdown.mdx"] = true,
	mdx = true,
	text = true,
	txt = true,
	asciidoc = true,
	org = true,
}

local function word_or_hover()
	if prose[vim.bo.filetype] then
		require("gerty").word()
	else
		vim.lsp.buf.hover()
	end
end

return {
	{
		-- `dev` runs the local checkout under `dev.path` (lua/config/lazy.lua)
		-- when it exists, and falls back to the published release otherwise.
		"wimcraft/gerty.nvim",
		dev = true,
		-- Prose buffers with no language server (plain .txt etc.): nothing else
		-- sets K there. `init` runs at startup; require() lazy-loads gerty.
		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = vim.tbl_keys(prose),
				callback = function(ev)
					vim.keymap.set("n", "K", word_or_hover, { buffer = ev.buf, desc = "Gerty: dictionary lookup" })
				end,
			})
		end,
		keys = {
			{
				"<leader>agr",
				function()
					require("gerty").replace()
				end,
				mode = "v",
				desc = "Gerty: replace selection",
			},
			{
				"<leader>age",
				function()
					require("gerty").explain()
				end,
				mode = "v",
				desc = "Gerty: explain selection",
			},
			{
				"<leader>agE",
				function()
					require("gerty").explain({ provider = "claude" })
				end,
				mode = "v",
				desc = "Gerty: explain selection (Claude CLI, reads the repo)",
			},
			{
				"<leader>aga",
				function()
					require("gerty").ask()
				end,
				mode = "n",
				desc = "Gerty: ask",
			},
			{
				"<leader>agx",
				function()
					require("gerty").cancel_all()
				end,
				mode = "n",
				desc = "Gerty: cancel all",
			},
			{
				"<leader>agm",
				function()
					require("gerty").select_model()
				end,
				mode = "n",
				desc = "Gerty: pick a model",
			},
			{
				"<leader>agR",
				function()
					-- pin the provider too: this model id only exists on `pi`,
					-- and would be handed straight to the claude CLI if `claude`
					-- happened to be the current default
					require("gerty").replace({ provider = "pi", model = "kilo/deepseek/deepseek-v4-pro" })
				end,
				mode = "v",
				desc = "Gerty: replace with a stronger model",
			},
			{
				"<leader>agt",
				function()
					require("gerty").translate()
				end,
				mode = "v",
				desc = "Gerty: translate selection",
			},
			{
				"<leader>agl",
				function()
					require("gerty").gloss()
				end,
				mode = "v",
				desc = "Gerty: gloss selection (blank = grammar/vocab, or type a question)",
			},
			{
				"<leader>agw",
				function()
					require("gerty").word()
				end,
				mode = "n",
				desc = "Gerty: dictionary lookup on word under cursor",
			},
			{
				"<leader>agL",
				function()
					require("gerty").select_language()
				end,
				mode = "n",
				desc = "Gerty: select language pair",
			},
			{
				"<leader>agh",
				function()
					require("gerty").history()
				end,
				mode = "n",
				desc = "Gerty: translation/gloss/word history",
			},
		},
		config = function(plugin)
			require("gerty").setup({
				-- Declare providers and the models each one can reach. That's it:
				-- there are no roles, and no model is "the translation one" —
				-- every model here can serve every op. `<leader>agm` points the
				-- default at any of them; `$alias` picks one for a single call.
				--
				-- The local models need no tuning here. gerty constrains an
				-- OpenAI-compatible endpoint to a JSON field named after the op
				-- doing the asking (translation / grammar_notes / answer /
				-- replacement), which is what keeps gemma from narrating its plan
				-- before answering — see the schema comment in transport.lua.
				providers = {
					-- `type` defaults to the alias, so `pi` and `claude` need
					-- nothing but their models.
					pi = {
						billing = "Codex subscription",
						model = "openai-codex/gpt-5.6-luna",
						models = {
							-- `openai-codex` is pi's name for the Codex
							-- subscription — confirmed via `pi --list-models codex`.
							-- Not a separate gerty provider: pi's `--model` takes
							-- "provider/id" for anything it knows about, same as
							-- the `kilo/...` ids below.
							{ id = "openai-codex/gpt-5.6-luna", name = "GPT-5.6 Luna" },
							{ id = "openai-codex/gpt-5.6-sol", name = "GPT-5.6 Sol" },
							{ id = "openai-codex/gpt-5.6-terra", name = "GPT-5.6 Terra" },
							{ id = "openai-codex/gpt-5.5", name = "GPT-5.5" },
							-- same CLI, different account paying — hence the
							-- per-model billing override
							{ id = "kilo/deepseek/deepseek-v4-flash", name = "DeepSeek V4 Flash", billing = "Kilo, pay-per-token" },
							{ id = "kilo/deepseek/deepseek-v4-pro", name = "DeepSeek V4 Pro", billing = "Kilo, pay-per-token" },
							{ id = "kilo/anthropic/claude-sonnet-5", name = "Claude Sonnet 5 (via Kilo)", billing = "Kilo, pay-per-token" },
							{ id = "kilo/anthropic/claude-opus-4.8", name = "Claude Opus 4.8 (via Kilo)", billing = "Kilo, pay-per-token" },
							{ id = "kilo/z-ai/glm-5.2", name = "GLM 5.2 (via Kilo)", billing = "Kilo, pay-per-token" },
							-- `ollama-cloud` is pi's built-in provider for the Ollama
							-- Cloud subscription (`pi --list-models ollama-cloud`)
							{ id = "ollama-cloud/deepseek-v4.1-flash", name = "DeepSeek V4.1 Flash (Ollama Cloud)", billing = "Ollama Cloud subscription" },
							{ id = "ollama-cloud/deepseek-v4-pro:0813", name = "DeepSeek V4 Pro (Ollama Cloud)", billing = "Ollama Cloud subscription" },
						},
					},
					-- experiment: the same CLI stripped of everything a one-shot
					-- doesn't need (extensions, MCP servers, skills, AGENTS.md /
					-- CLAUDE.md) to see how much startup latency that saves. Pick
					-- it with `$pi-lean` or `<leader>agm`.
					["pi-lean"] = {
						type = "pi",
						billing = "Ollama Cloud subscription",
						extra_args = { "--no-extensions", "--no-mcp", "--no-skills", "--no-context-files" },
						models = {
							{ id = "ollama-cloud/deepseek-v4.1-flash", name = "DeepSeek V4.1 Flash (lean pi)" },
						},
					},
					-- the real Claude Code CLI, which brings its own repo tools,
					-- CLAUDE.md and MCP servers — worth it when the answer
					-- depends on reading half the repository
					claude = {
						billing = "Claude subscription",
						models = {
							{ id = "claude-sonnet-5", name = "Claude Sonnet 5" },
							{ id = "claude-opus-5", name = "Claude Opus 5 (hardest tasks)" },
							{ id = "claude-haiku-4-5-20251001", name = "Claude Haiku 4.5 (fastest)" },
						},
					},
					-- chat-only: no tools, so `ask` refuses it. Everything else
					-- adapts — `replace` gets the code back directly instead of
					-- through a temp file, `explain` answers from the selection.
					["local"] = {
						type = "lmstudio", -- localhost:1234; `endpoint =` overrides
						billing = "local, free",
						models = {
							{ id = "google/gemma-4-e4b", name = "Gemma 4 E4B" },
							{ id = "qwen/qwen3-1.7b", name = "Qwen3 1.7B" },
						},
					},
				},
				default = "pi",
				-- the only routing worth stating: reading a novel shouldn't go
				-- through a paid API. Everything else follows `default`.
				op_defaults = {
					translate = "local",
					gloss = "local",
				},
				language = {
					source = "de",
					target = "en",
					context_lines = 5,
					learner_level = "intermediate",
				},
				language_presets = {
					{ source = "de", target = "en" },
					{ source = "pl", target = "en" },
				},
				dictionary = {
					command = { "trans", "-b" },
				},
				-- deslop / grammar live in the plugin checkout, not here
				skills = {
					plugin.dir .. "/skills/",
				},
			})
		end,
	},
	-- LSP-attached prose buffers (marksman, ltex): LazyVim maps K to hover on
	-- attach, which would beat the FileType mapping above. Append to
	-- servers["*"].keys with an opts FUNCTION — lazy replaces lists on table
	-- merge, which would wipe LazyVim's gd/gr — and duplicate lhs resolve
	-- last-wins, so this K overrides the default.
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.servers = opts.servers or {}
			opts.servers["*"] = opts.servers["*"] or {}
			local keys = opts.servers["*"].keys or {}
			keys[#keys + 1] = { "K", word_or_hover, desc = "Hover / Gerty dictionary lookup (prose)" }
			opts.servers["*"].keys = keys
		end,
	},
}
