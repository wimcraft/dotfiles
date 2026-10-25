-- Oil directory bookmarks.
--
-- Oil has no bookmarks of its own. The list lives in a JSON file under
-- stdpath("data") (~/.local/share/nvim/oil-bookmarks.json), outside this repo, so
-- directory names never reach the public dotfiles.
--
-- Keys are local to Oil buffers, so "," keeps its normal f/t-repeat meaning
-- everywhere else:
--   ,j  pick a bookmark and open it in Oil
--   ,J  bookmark the directory of the current Oil buffer
--   ,X  remove a bookmark

local store = vim.fn.stdpath("data") .. "/oil-bookmarks.json"

local function load()
	local f = io.open(store, "r")
	if not f then
		return {}
	end
	local ok, data = pcall(vim.json.decode, f:read("*a"))
	f:close()
	return ok and type(data) == "table" and data or {}
end

local function save(list)
	local f = assert(io.open(store, "w"))
	f:write(vim.json.encode(list))
	f:close()
end

local function current_dir()
	local ok, oil = pcall(require, "oil")
	local dir = ok and oil.get_current_dir() or nil
	return dir or vim.fn.expand("%:p:h")
end

local function pick(prompt, on_choice)
	local list = load()
	if #list == 0 then
		vim.notify("No Oil bookmarks yet (,J to add)", vim.log.levels.INFO)
		return
	end
	vim.ui.select(list, {
		prompt = prompt,
		format_item = function(p)
			return vim.fn.fnamemodify(p, ":~")
		end,
	}, function(choice)
		if choice then
			on_choice(choice, list)
		end
	end)
end

local function add()
	local dir = current_dir():gsub("/$", "")
	local list = load()
	if vim.tbl_contains(list, dir) then
		return vim.notify("Already bookmarked: " .. dir)
	end
	table.insert(list, dir)
	save(list)
	vim.notify("Bookmarked " .. vim.fn.fnamemodify(dir, ":~"))
end

return {
	"stevearc/oil.nvim",
	opts = {
		keymaps = {
			[",j"] = {
				desc = "Oil bookmark",
				callback = function()
					pick("Oil bookmark", function(path)
						require("oil").open(path)
					end)
				end,
			},
			[",J"] = { desc = "Oil bookmark current dir", callback = add },
			[",X"] = {
				desc = "Oil remove bookmark",
				callback = function()
					pick("Remove bookmark", function(path, list)
						save(vim.tbl_filter(function(p)
							return p ~= path
						end, list))
					end)
				end,
			},
		},
	},
}
