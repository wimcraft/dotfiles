-- unwrap: turn hard-wrapped prose back into one line per paragraph.
--
-- Tools that emit markdown (Claude, most LLMs, `fmt`) wrap at ~80 columns. Any
-- renderer downstream — GitHub, a browser, a mail client — reflows the paragraph
-- to the reader's own width, so those wrap points survive only as ragged breaks
-- mid-sentence, and every later edit rewraps the paragraph so the diff covers
-- all of it instead of the line that changed.
--
-- Only the breaks *inside* a block are removed. Everything that is genuinely
-- line-based is left exactly as it was: blank lines, headings, list items,
-- tables, horizontal rules, fenced and indented code, YAML front matter, link
-- definitions, HTML, and explicit `  ` / `\` line breaks.

local M = {}

-- Peel any number of blockquote markers off the front. Continuation lines only
-- join a line at the same quote depth, so `> a` never swallows a `>> b`.
local function split_quote(line)
  local prefix, rest = "", line
  while true do
    local p, r = rest:match("^(%s*>%s?)(.*)$")
    if not p then
      break
    end
    prefix, rest = prefix .. p, r
  end
  return prefix, rest
end

local function is_fence(text)
  return text:match("^%s*```") ~= nil or text:match("^%s*~~~") ~= nil
end

-- Blocks that own their line: joining them into a neighbour changes the render.
local function is_structural(text)
  return text:match("^%s*#+%s") -- heading
    or text:match("^%s*|") -- table row
    or text:match("^%s*[-*_]%s*[-*_]%s*[-*_][-*_%s]*$") -- horizontal rule / --- delimiter
    or text:match("^%s*<") -- html block
    or text:match("^%s*%[[^%]]*%]:") -- link or footnote definition
    or text:match("^%s*=+%s*$") -- setext underline
end

local function is_list_item(text)
  return text:match("^%s*[-*+]%s+") ~= nil or text:match("^%s*%d+[.)]%s+") ~= nil
end

-- Trailing `  ` or `\` is an explicit <br>; strip the padding but keep the break.
local function strip(text)
  local hard = text:match("  +$") ~= nil or text:match("\\$") ~= nil
  local body = vim.trim(text)
  if hard and not body:match("\\$") then
    body = body .. "  "
  end
  return body, hard
end

--- Join wrapped lines in [first, last] (1-indexed, inclusive) of the current buffer.
function M.unwrap(first, last)
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, first - 1, last, false)

  local out = {}
  local pending, pending_prefix -- the block being accumulated, and its quote depth
  local in_fence = false
  -- Front matter only counts as such at the very top of the file.
  local in_front_matter = first == 1 and lines[1] ~= nil and lines[1]:match("^%-%-%-%s*$") ~= nil

  local function flush()
    if pending then
      table.insert(out, pending)
      pending, pending_prefix = nil, nil
    end
  end

  for i, line in ipairs(lines) do
    local prefix, text = split_quote(line)

    if in_front_matter then
      table.insert(out, line)
      if i > 1 and line:match("^%s*%-%-%-%s*$") then
        in_front_matter = false
      end
    elseif in_fence then
      table.insert(out, line)
      if is_fence(text) then
        in_fence = false
      end
    elseif is_fence(text) then
      flush()
      in_fence = true
      table.insert(out, line)
    elseif text:match("^%s*$") or is_structural(text) then
      flush()
      table.insert(out, line)
    elseif pending == nil and text:match("^    ") then
      table.insert(out, line) -- indented code block (only outside a list item)
    else
      local body, hard = strip(text)
      if is_list_item(text) then
        -- A new item ends the previous one; keep its own indent and marker.
        flush()
        pending, pending_prefix = prefix .. text:gsub("%s+$", ""), prefix
      elseif pending and prefix == pending_prefix then
        pending = pending .. " " .. body
      else
        flush()
        pending, pending_prefix = prefix .. body, prefix
      end
      if hard then
        flush()
      end
    end
  end
  flush()

  vim.api.nvim_buf_set_lines(buf, first - 1, last, false, out)

  local removed = #lines - #out
  vim.notify(
    removed > 0 and ("Unwrap: joined " .. removed .. " line break" .. (removed == 1 and "" or "s"))
      or "Unwrap: nothing to join",
    vim.log.levels.INFO
  )
end

-- range = "%" means: no range given -> whole buffer, visual selection -> selection.
vim.api.nvim_create_user_command("Unwrap", function(opts)
  M.unwrap(opts.line1, opts.line2)
end, { range = "%", desc = "Join hard-wrapped prose into one line per paragraph" })

return M
