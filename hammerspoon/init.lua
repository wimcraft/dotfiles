-- Remap CapsLock to F18 at the system level (survives Hammerspoon reloads)
hs.execute(
	[[hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}']]
)

-- Export env vars from shell to GUI apps via launchctl
local envVars = { "OBSIDIAN_VAULT_PATH" }
for _, name in ipairs(envVars) do
	local value, status = hs.execute("zsh -ilc 'echo $" .. name .. "'")
	value = value:gsub("%s+$", "")
	if status and value ~= "" then
		hs.execute("launchctl setenv " .. name .. " " .. hs.http.encodeForQuery(value))
		print("launchctl setenv: " .. name .. "=" .. value)
	else
		print("launchctl setenv: skipped " .. name .. " (empty or error)")
	end
end

local hyper = require("hyper")
hyper.install("F18")

hs.hotkey.bind({ "ctrl", "alt" }, "r", hs.reload)
hs.alert.show("Hammerspoon reloaded")

-- Arrow keys
hyper.bindKey("h", function()
	hs.eventtap.keyStroke({}, "left")
end)
hyper.bindKey("j", function()
	hs.eventtap.keyStroke({}, "down")
end)
hyper.bindKey("k", function()
	hs.eventtap.keyStroke({}, "up")
end)
hyper.bindKey("l", function()
	hs.eventtap.keyStroke({}, "right")
end)

-- Beginning/End of line
hyper.bindKey("i", function()
	hs.eventtap.keyStroke({ "cmd" }, "left")
end)
hyper.bindKey("o", function()
	hs.eventtap.keyStroke({ "cmd" }, "right")
end)

-- Backspace
hyper.bindKey("f", function()
	hs.eventtap.keyStroke({}, "delete")
end)

-- Tab switching
hyper.bindKey("r", function()
	hs.eventtap.keyStroke({ "ctrl" }, "tab")
end)
hyper.bindKey("e", function()
	hs.eventtap.keyStroke({ "ctrl", "shift" }, "tab")
end)

-- Languages
local function setLayout(layout)
	return function()
		hs.keycodes.setLayout(layout)
		hs.alert.show(layout)
	end
end
hyper.bindKey("g", setLayout("U.S."))
hyper.bindKey("u", setLayout("Ukrainian"))
hyper.bindKey("p", setLayout("Polish"))

-- Reload Hammerspoon
hyper.bindShiftKey("r", hs.reload)
