return {
	-- Solarized Light (solarized-osaka by craftzdog, the author of tokyonight)
	-- A faithful port of Ethan Schoonover's Solarized with support for all
	-- LazyVim plugins (lualine, snacks, telescope, which-key, ...).
	{
		"craftzdog/solarized-osaka.nvim",
		lazy = true,
		priority = 1000,
		opts = {
			-- Force the Solarized Light palette (bg #fdf6e3). Without this the
			-- theme follows vim.o.background, which LazyVim leaves dark.
			style = "light",
			-- solarized-osaka defaults to transparent=true; that would show the
			-- terminal's dark background under the light palette. Set the theme bg.
			transparent = false,
			terminal_colors = true,
			-- In the light style "dark" surfaces (sidebar, popups, statusline) map to
			-- base04 = pure white, clashing with the cream bg. Use base02 (#eee8d5,
			-- inverted in light) instead.
			on_colors = function(c)
				c.bg_sidebar = c.base02
				c.bg_float = c.base02
				c.bg_popup = c.base02
				c.bg_statusline = c.base02
				-- Dislike magenta/violet: fold magenta shades into blue.
				for k in pairs(vim.deepcopy(c)) do
					if k:match("^magenta") then
						c[k] = c[k:gsub("^magenta", "blue")]
					end
				end
			end,
			on_highlights = function(hl, c)
				-- Headings: orange-red -> blue (H2 cyan).
				for _, g in ipairs({ "Title", "@markup.heading", "markdownH1", "RenderMarkdownH1", "RenderMarkdownH3", "RenderMarkdownH4", "RenderMarkdownH5", "RenderMarkdownH6" }) do
					hl[g] = { fg = c.blue, bold = true }
				end
				hl.RenderMarkdownH2 = { fg = c.cyan, bold = true }
				for i = 1, 6 do
					hl["@markup.heading." .. i .. ".markdown"] = { fg = i == 2 and c.cyan or c.blue, bold = true }
				end
				-- Inline code: neon green bg -> quiet cream with blue text.
				hl["@markup.raw.markdown_inline"] = { fg = c.blue, bg = c.base02 }
				hl.RenderMarkdownCodeInline = { fg = c.blue, bg = c.base02 }
				hl.RenderMarkdownCode = { bg = c.base02 }
				-- Orange-red "special" tokens (cmdline command names, popup match text,
				-- builtins, constructors, parameters) -> cyan/blue. CursorLineNr and
				-- WarningMsg intentionally stay as they are.
				for _, g in ipairs({ "Special", "Debug", "@punctuation.special", "@constructor", "@variable.parameter", "@module.builtin", "@variable.builtin", "NoicePopupmenuMatch", "CmpItemKindClass", "CmpItemKindEnum", "CmpItemKindEvent", "CmpItemKindInterface", "CmpItemKindStruct", "CmpItemKindUnit" }) do
					hl[g] = { fg = c.cyan }
				end
				hl["@function.builtin"] = { fg = c.blue }
				-- Line numbers: bright yellow was too faint on cream; use a darker amber.
				for _, g in ipairs({ "LineNr", "LineNrAbove", "LineNrBelow" }) do
					hl[g] = { fg = "#8a6700", bg = hl[g] and hl[g].bg or c.bg }
				end
			end,
		},
	},
	-- Inactive tabs inherit a very pale fg in the light style; make them readable.
	{
		"akinsho/bufferline.nvim",
		opts = function(_, opts)
			-- Evaluated on every ColorScheme event, so these overrides apply only
			-- while a solarized theme is active.
			opts.highlights = function(defaults)
				if not (vim.g.colors_name or ""):match("solarized") then
					return defaults.highlights
				end
				local fg = "#586e75" -- solarized base01
				local inactive = { fg = fg }
				-- Active tab: a touch darker than the editor bg (base02) for contrast.
				local active_bg = "#eee8d5"
				return vim.tbl_deep_extend("force", defaults.highlights, {
					background = inactive,
					buffer_visible = inactive,
					close_button = inactive,
					close_button_visible = inactive,
					numbers = inactive,
					numbers_visible = inactive,
					modified = inactive,
					modified_visible = inactive,
					duplicate = inactive,
					duplicate_visible = inactive,
					buffer_selected = { bg = active_bg, bold = true, italic = true },
					close_button_selected = { bg = active_bg },
					numbers_selected = { bg = active_bg },
					modified_selected = { bg = active_bg },
					duplicate_selected = { bg = active_bg },
					indicator_selected = { bg = active_bg },
					separator_selected = { bg = active_bg },
					diagnostic_selected = { bg = active_bg },
					hint_selected = { bg = active_bg },
					info_selected = { bg = active_bg },
					warning_selected = { bg = active_bg },
					error_selected = { bg = active_bg },
				})
			end
		end,
	},
}
