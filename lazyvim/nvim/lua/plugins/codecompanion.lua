-- CodeCompanion gives a Neovim-native chat buffer on top of the *same* Claude Code
-- agent that claudecode.nvim runs in a terminal split. It talks ACP (Agent Client
-- Protocol) to `claude-agent-acp`, which npm already installed alongside the
-- `claude` binary in ~/.local/bin -- so the chat runs on the existing subscription
-- login, no API key.
--
-- Two clients, separated only by CLAUDE_CONFIG_DIR (mirrors the `ccp` alias in
-- ~/.zshrc): work -> ~/.claude, personal -> ~/.claude-personal. Each config dir has
-- its own `Claude Code-credentials-<hash>` keychain entry, so no token juggling.
--
-- ACP adapters only serve the chat interaction; inline/cmd need an HTTP adapter,
-- hence `kilo` below.

---Build a claude_code ACP adapter pinned to a given CLAUDE_CONFIG_DIR.
---@param config_dir string|nil nil = inherit the default (~/.claude, i.e. work)
local function claude_code_adapter(config_dir)
  local adapter = require("codecompanion.adapters").extend("claude_code", {
    env = config_dir and { CLAUDE_CONFIG_DIR = config_dir } or {},
  })

  -- The stock adapter declares `env.CLAUDE_CODE_OAUTH_TOKEN = "CLAUDE_CODE_OAUTH_TOKEN"`,
  -- meaning "read that variable". When it is unset, get_env_vars falls through to
  -- treating the value as a literal, so the agent gets spawned with
  -- CLAUDE_CODE_OAUTH_TOKEN=CLAUDE_CODE_OAUTH_TOKEN -- a garbage token that beats the
  -- keychain login. Drop the key unless a real token is exported; `handlers.auth`
  -- then returns false and the agent authenticates itself from CLAUDE_CONFIG_DIR.
  if not os.getenv("CLAUDE_CODE_OAUTH_TOKEN") then
    adapter.env.CLAUDE_CODE_OAUTH_TOKEN = nil
  end

  return adapter
end

---Line number of the last chat header, i.e. the start of the editable input region.
---Only text BELOW this line is parsed and sent (chat/parser.lua `M.messages` reads
---from `chat.header_line` to the end); anything above it is inert display text.
---Fence-aware, so a markdown heading inside a code block is not mistaken for one.
---@param buf integer
---@return integer  0 when no header exists yet
local function chat_input_start(buf)
  local fence = nil
  local header = 0
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local ticks = line:match("^%s*(```+)")
    if ticks then
      if not fence then
        fence = #ticks
      elseif #ticks >= fence then
        fence = nil
      end
    elseif not fence and line:match("^##%s") then
      header = i
    end
  end
  return header
end

---Insert-entry keys, redirected to the input region when pressed above it.
---Typing above the last header is always a mistake: it is not sent, and it used to
---submit an empty turn that killed the chat (see fyi.md 2026-08-27). Below the
---header these behave exactly as normal.
local function chat_safe_insert_keys(buf)
  for _, key in ipairs({ "i", "I", "a", "A", "o", "O" }) do
    vim.keymap.set("n", key, function()
      local header = chat_input_start(buf)
      if header > 0 and vim.api.nvim_win_get_cursor(0)[1] <= header then
        return "Go"
      end
      return key
    end, { buffer = buf, expr = true, desc = "Insert (redirected to the chat input region)" })
  end
end

return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("codecompanion_safe_insert", { clear = true }),
        pattern = "codecompanion",
        callback = function(args)
          chat_safe_insert_keys(args.buf)
        end,
      })
    end,
    cmd = {
      "CodeCompanion",
      "CodeCompanionChat",
      "CodeCompanionCmd",
      "CodeCompanionActions",
    },
    keys = {
      { "<leader>ao", group = "codecompanion" },
      -- NOTE: the adapter MUST be passed as `adapter=<name>`. CodeCompanionChat only
      -- parses `key=value` args (commands/init.lua:146); a bare word falls through to
      -- the prompt bucket, so `CodeCompanionChat claude_code_personal` silently opens a
      -- *default-adapter* chat whose first message is the literal text "claude_code_personal".
      { "<leader>aow", "<cmd>CodeCompanionChat adapter=claude_code<cr>", desc = "Chat (Claude work)" },
      { "<leader>aop", "<cmd>CodeCompanionChat adapter=claude_code_personal<cr>", desc = "Chat (Claude personal)" },
      { "<leader>aoc", "<cmd>CodeCompanionChat Toggle<cr>", desc = "Toggle chat", mode = { "n", "v" } },
      { "<leader>aoa", "<cmd>CodeCompanionActions<cr>", desc = "Actions palette", mode = { "n", "v" } },
      { "<leader>aod", "<cmd>CodeCompanionChat Add<cr>", desc = "Add selection to chat", mode = "v" },
      { "<leader>aoi", ":CodeCompanion ", desc = "Inline prompt (Kilo)", mode = { "n", "v" } },
    },
    opts = {
      adapters = {
        acp = {
          claude_code = function()
            return claude_code_adapter(nil)
          end,
          claude_code_personal = function()
            return claude_code_adapter(vim.fn.expand("~/.claude-personal"))
          end,
        },
        http = {
          -- Kilo's OpenAI-compatible gateway; the same KILO_API_KEY the `goose-kilo`
          -- function in ~/.zshrc uses. /v1/models works there, so `ga` in the chat
          -- buffer lists Kilo's whole catalogue.
          kilo = function()
            return require("codecompanion.adapters").extend("openai_compatible", {
              name = "kilo",
              formatted_name = "Kilo",
              env = {
                url = "https://api.kilo.ai/api/gateway",
                api_key = "KILO_API_KEY",
                chat_url = "/v1/chat/completions",
                models_endpoint = "/v1/models",
              },
              schema = {
                model = { default = "anthropic/claude-sonnet-5" },
              },
            })
          end,
        },
      },
      prompt_library = {
        -- Prompts live as markdown files in ~/personal/codecompanion-prompts and show
        -- up as slash commands (`/mentor`) plus entries in the actions palette.
        --
        -- Format, per prompt_library/markdown.lua + queries/markdown/chat.scm:
        --   * YAML frontmatter needs `name` and `interaction` (`strategy` is the old
        --     alias). Requires the `yaml` treesitter parser.
        --   * `opts.alias` is what becomes the slash command -- NOT `short_name`,
        --     which was renamed in PR #2471 and is now silently ignored.
        --   * `## h2` headings ARE the role markers -- only `## system` and `## user`
        --     are kept. A prompt's own structure must therefore start at `### h3`,
        --     or the prompt silently splits in half.
        -- Points at the `prompts/` subdir, not the repo root: every *.md in a scanned
        -- dir is parsed as a prompt, so a README.md there warns on every chat open.
        markdown = { dirs = { vim.fn.expand("~/personal/codecompanion-prompts/prompts") } },
      },
      interactions = {
        chat = {
          adapter = "claude_code",
          tools = {
            -- Start every chat in Auto approval mode (upstream default "ask").
            -- Auto: everything runs without asking except run_command (unless
            -- on the safe list) and protected tools such as delete_file.
            -- `gty` in the chat buffer switches mode per chat.
            opts = { approval_mode = "auto" },
            run_command = {
              -- Widens what Auto mode lets through. Read by BOTH paths: the builtin
              -- run_command tool and -- since upstream wired approval modes into ACP
              -- -- the `session/request_permission` handler, which judges an agent
              -- tool_call of kind `execute` on the command string itself
              -- (acp/request_permission.lua:286). Without this, Auto only ever
              -- auto-approved the upstream default `git status`, `ls`, `pwd`, so the
              -- Claude Code agent prompted on essentially every command.
              --
              -- Matching is exact or prefix-with-a-space (approvals.lua:153), so
              -- `git diff` covers `git diff --staged`. Note that is_safe_command
              -- rejects any command containing `; & | < > ` backtick, newline or
              -- `$(` BEFORE consulting this list (approvals.lua:146) -- so `ls | head`
              -- still prompts. These entries only exempt a command run on its own.
              --
              -- Omitted on purpose, mirroring the settings.json allow-list in
              -- fyi.md 2026-10-14: `find` (has -delete and -exec) and `git branch`
              -- (-D deletes). Keep this list read-only-or-idempotent; anything that
              -- can mutate the tree should still cost a keypress.
              opts = {
                safe_commands = {
                  "ls",
                  "pwd",
                  "cat",
                  "head",
                  "tail",
                  "wc",
                  "file",
                  "stat",
                  "tree",
                  "which",
                  "rg",
                  "fd",
                  "diff",
                  "git status",
                  "git log",
                  "git diff",
                  "git show",
                  "git blame",
                  "npm test",
                  "npm run lint",
                  "npm run build",
                  "go test",
                  "go build",
                  "go vet",
                },
              },
            },
          },
          opts = {
            -- Upstream default is "". When the last `## Me` section parses to
            -- nothing -- you typed above the header line, or the section holds only
            -- stripped `> Context:` lines -- chat/init.lua:1366 falls back to this
            -- and appends a user message with EMPTY content. The pre-check at :1330
            -- only rejects that when the chat has no prior user turn, so it sails
            -- through mid-conversation, lands in self.messages permanently, and
            -- every later request 400s: "messages.N: user messages must have
            -- non-empty content". The chat is then unrecoverable -- the poisoned
            -- entry is internal state, not buffer text, so editing it away does
            -- nothing. A non-empty value makes the accident harmless.
            blank_prompt = "(Empty message sent by accident. Please ignore this turn and wait for my next instruction.)",
          },
          keymaps = {
            -- CodeCompanion sends on <C-s>, which never reaches nvim here:
            -- tmux.conf sets `prefix2 C-s` and zellij binds `Ctrl s` too.
            -- <C-j> instead -- home row, no pinky stretch, and free in insert
            -- mode both globally and in the chat buffer.
            --
            -- Insert mode ONLY. In normal mode <C-j> is vim-tmux-navigator's
            -- TmuxNavigateDown; claiming it here would break pane navigation
            -- out of the chat buffer.
            --
            -- Normal mode is g<CR>, not a bare <CR>. A stray <CR> while scrolling
            -- submits an EMPTY user turn, and chat/init.lua:1330 only rejects that
            -- when the chat has no prior user message -- so mid-conversation it
            -- reaches the API and 400s the whole thread ("messages.N: user messages
            -- must have non-empty content"), which nothing can repair in place.
            -- (`> Context:` lines are stripped before sending too, so a turn that
            -- looks non-empty on screen can still submit as empty.)
            -- gs is taken (toggle system prompt) and gj shadows the display-line
            -- motion, which is worth keeping in a soft-wrapped transcript.
            send = {
              modes = { n = { "g<CR>" }, i = "<C-j>" },
              callback = "keymaps.send",
              description = "Send the message to the LLM",
            },
          },
        },
        inline = { adapter = "kilo" },
        cmd = { adapter = "kilo" },
      },
      display = {
        -- Same swap for the small floating prompt used by the inline interaction.
        input = {
          keymaps = {
            send = {
              modes = { n = { "<CR>" }, i = "<C-j>" },
              description = "Send",
            },
          },
        },
      },
    },
  },
}
