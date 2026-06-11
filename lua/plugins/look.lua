return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000, -- load before other plugins subscribe to ColorScheme
		config = function()
			-- catppuccin repainted as VSCode's built-in Monokai
			-- (monokai-color-theme.jsonc). catppuccin is used purely as a *chassis*
			-- for its breadth of plugin/float integrations; every visible color comes
			-- from Monokai. Two layers, sharing the one `mk` source of truth:
			--
			--   1. PALETTE (color_overrides) — recolors catppuccin's neutrals +
			--      accents. This is what drives the plugin/integration UI we never
			--      enumerate by hand: lualine, blink, noice, which-key, lazy,
			--      gitsigns, diagnostics.
			--
			--   2. SYNTAX (custom_highlights) — owns token coloring outright.
			--      catppuccin and Monokai assign hues to roles very differently
			--      (catppuccin strings=green, functions=blue, keywords=mauve; Monokai
			--      strings=yellow, functions=green, keywords=pink), so the palette
			--      swap alone cannot produce Monokai syntax. Measured: 82 of 85 token
			--      groups need an explicit override, so this table is near-irreducible
			--      rather than incidental verbosity.
			local mk = {
				-- Neutrals / chrome (editor.* surfaces)
				-- `bg` is kept even though transparent_background = true: catppuccin
				-- uses `base` as a value for blend/darken math, so it must stay
				-- Monokai's #272822 (transparency only suppresses painting it on
				-- Normal, not its use in derived colors).
				bg = "#272822", -- editor.background
				bg_dark = "#1e1f1c", -- sideBar / widgets / tab well
				bg_darker = "#161712", -- crust (darkest chrome)
				line = "#3e3d32", -- editor.lineHighlightBackground
				sel = "#414339", -- selection / input.background
				surface = "#545343",
				comment = "#88846f", -- comment scope
				muted = "#75715e", -- focus / borders / picker group
				linenr = "#90908a", -- editorLineNumber.foreground
				linenr_active = "#c2c2bf", -- editorLineNumber.activeForeground
				fg = "#f8f8f2", -- editor.foreground
				-- Syntax accents (tokenColors)
				pink = "#f92672", -- keyword / storage / tag / operator
				orange = "#fd971f", -- variable.parameter / this.self
				yellow = "#e6db74", -- string
				green = "#a6e22e", -- function / class / namespace / attribute
				cyan = "#66d9ef", -- support / type.builtin (italic)
				purple = "#ae81ff", -- constant / number / boolean
				error = "#f44747", -- invalid
				focus_border = "#99947c", -- focusBorder
			}

			-- Editor chrome: solid backgrounds so floats/menus stay readable even
			-- with transparent_background, plus the source's exact line-number,
			-- selection and separator colors. (Distinct from the palette layer, which
			-- only feeds catppuccin's own integration groups.)
			local editor_ui = {
				NormalFloat = { bg = mk.bg_dark },
				FloatBorder = { fg = mk.muted, bg = mk.bg_dark },
				Pmenu = { bg = mk.bg, fg = mk.fg },
				PmenuSel = { bg = mk.sel },
				Visual = { bg = mk.sel },
				CursorLine = { bg = mk.line },
				LineNr = { fg = mk.linenr },
				CursorLineNr = { fg = mk.linenr_active },
				WinSeparator = { fg = mk.sel },
			}

			-- Syntax: the token→color assignment from monokai-color-theme.jsonc.
			-- This layer owns syntax explicitly because catppuccin's role mapping
			-- structurally disagrees with Monokai's (see header).
			local syntax = {
				-- Comments
				Comment = { fg = mk.comment },
				["@comment"] = { fg = mk.comment },
				["@comment.documentation"] = { fg = mk.comment },

				-- Strings
				String = { fg = mk.yellow },
				Character = { fg = mk.purple }, -- constant.character is purple
				["@string"] = { fg = mk.yellow },
				["@string.regexp"] = { fg = mk.yellow },
				["@string.documentation"] = { fg = mk.yellow },
				["@string.escape"] = { fg = mk.purple },
				["@character"] = { fg = mk.purple },

				-- Numbers / constants / booleans
				Number = { fg = mk.purple },
				Float = { fg = mk.purple },
				Boolean = { fg = mk.purple },
				Constant = { fg = mk.purple },
				["@number"] = { fg = mk.purple },
				["@number.float"] = { fg = mk.purple },
				["@boolean"] = { fg = mk.purple },
				["@constant"] = { fg = mk.purple },
				["@constant.builtin"] = { fg = mk.purple },
				["@constant.macro"] = { fg = mk.purple },

				-- Keywords / operators / storage (keyword + storage scope = pink)
				Keyword = { fg = mk.pink },
				Statement = { fg = mk.pink },
				Conditional = { fg = mk.pink },
				Repeat = { fg = mk.pink },
				Exception = { fg = mk.pink },
				Operator = { fg = mk.pink },
				["@keyword"] = { fg = mk.pink },
				["@keyword.function"] = { fg = mk.pink },
				["@keyword.return"] = { fg = mk.pink },
				["@keyword.operator"] = { fg = mk.pink },
				["@keyword.conditional"] = { fg = mk.pink },
				["@keyword.repeat"] = { fg = mk.pink },
				["@keyword.exception"] = { fg = mk.pink },
				["@keyword.import"] = { fg = mk.pink },
				["@keyword.directive"] = { fg = mk.pink },
				["@operator"] = { fg = mk.pink },

				-- Types / classes: user-defined are green; library/builtin are
				-- cyan italic (entity.name.type vs support.type in the source).
				Type = { fg = mk.green },
				Structure = { fg = mk.cyan },
				StorageClass = { fg = mk.cyan, italic = true },
				["@type"] = { fg = mk.green },
				["@type.definition"] = { fg = mk.green },
				["@type.builtin"] = { fg = mk.cyan, italic = true },
				["@type.qualifier"] = { fg = mk.pink },
				["@constructor"] = { fg = mk.green },
				["@module"] = { fg = mk.green },
				["@namespace"] = { fg = mk.green },

				-- Functions: definitions/calls green; builtins cyan italic.
				Function = { fg = mk.green },
				["@function"] = { fg = mk.green },
				["@function.call"] = { fg = mk.green },
				["@function.method"] = { fg = mk.green },
				["@function.method.call"] = { fg = mk.green },
				["@function.macro"] = { fg = mk.green },
				-- support.function in the source is cyan but NOT italic.
				["@function.builtin"] = { fg = mk.cyan },

				-- Variables, parameters, this/self, members
				Identifier = { fg = mk.fg },
				["@variable"] = { fg = mk.fg },
				["@variable.parameter"] = { fg = mk.orange, italic = true },
				-- variable.language (this/self) is orange but NOT italic.
				["@variable.builtin"] = { fg = mk.orange },
				["@variable.member"] = { fg = mk.fg },
				["@property"] = { fg = mk.fg },
				["@field"] = { fg = mk.fg },

				-- Markup / JSX tags
				Tag = { fg = mk.pink },
				["@tag"] = { fg = mk.pink },
				["@tag.builtin"] = { fg = mk.pink },
				["@tag.attribute"] = { fg = mk.green },
				["@tag.delimiter"] = { fg = mk.fg },

				-- Punctuation (template-expression punctuation is pink)
				Delimiter = { fg = mk.fg },
				["@punctuation.bracket"] = { fg = mk.fg },
				["@punctuation.delimiter"] = { fg = mk.fg },
				["@punctuation.special"] = { fg = mk.pink },

				-- Preprocessor
				PreProc = { fg = mk.pink },

				-- Errors
				Error = { fg = mk.error },
				["@error"] = { fg = mk.error },

				-- Markdown. Only color/structure overrides here; @markup.strong,
				-- @markup.italic and @markup.strikethrough are omitted because
				-- catppuccin's defaults already match the source exactly.
				["@markup.heading"] = { fg = mk.green, bold = true },
				["@markup.raw"] = { fg = mk.orange },
				["@markup.raw.inline"] = { fg = mk.orange },
				["@markup.list"] = { fg = mk.yellow },
				["@markup.quote"] = { fg = mk.muted, italic = true },
				["@markup.link.label"] = { fg = mk.purple },
				["@markup.link.url"] = { fg = mk.yellow },

				-- Diff
				["@diff.plus"] = { fg = mk.green },
				["@diff.minus"] = { fg = mk.pink },
				["@diff.delta"] = { fg = mk.yellow },
			}

			require("catppuccin").setup({
				flavour = "mocha", -- catppuccin uses British spelling
				transparent_background = true, -- show the terminal background through
				-- Clear catppuccin's default font styling (it italicizes comments,
				-- keywords, etc.) so the syntax layer has sole control and we
				-- italicize only what monokai-color-theme.jsonc italicizes.
				styles = {
					comments = {},
					conditionals = {},
					loops = {},
					functions = {},
					keywords = {},
					strings = {},
					variables = {},
					numbers = {},
					booleans = {},
					properties = {},
					types = {},
					operators = {},
					miscs = {}, -- clears catppuccin's default italic on @tag.attribute, @module, etc.
				},
				integrations = {
					blink_cmp = true,
					native_lsp = { enabled = true },
					which_key = true,
					noice = true,
					treesitter = true,
					gitsigns = true,
				},
				-- Layer 1 (palette): neutrals + accents mapped onto catppuccin's role
				-- names so its integration groups land on Monokai colors. The syntax
				-- layer below corrects the roles where the two themes disagree.
				color_overrides = {
					mocha = {
						base = mk.bg,
						mantle = mk.bg_dark,
						crust = mk.bg_darker,
						surface0 = mk.line,
						surface1 = mk.sel,
						surface2 = mk.surface,
						overlay0 = mk.muted,
						overlay1 = mk.comment,
						overlay2 = mk.linenr_active,
						text = mk.fg,
						subtext1 = "#d8d8d2",
						subtext0 = mk.linenr_active,
						rosewater = mk.fg,
						flamingo = mk.pink,
						pink = mk.pink,
						red = mk.pink,
						maroon = mk.orange,
						mauve = mk.pink, -- catppuccin keyword color
						peach = mk.orange,
						yellow = mk.yellow,
						green = mk.green,
						teal = mk.cyan,
						sky = mk.cyan,
						sapphire = mk.cyan,
						blue = mk.cyan, -- catppuccin's primary accent
						lavender = mk.purple,
					},
				},
				-- Layer 2 (syntax) + editor chrome, merged.
				custom_highlights = vim.tbl_extend("error", editor_ui, syntax),
			})
			vim.cmd.colorscheme("catppuccin-mocha")
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		opts = {
			icons_enabled = true,
			component_separators = { left = "", right = "" },
			section_separators = { left = "", right = "" },
			tabline = {
				lualine_a = {
					{
						"tabs",
						max_length = 88, -- follow black's rationale on reasonable width
						mode = 2, -- mode=2 shows tab names if set
					},
				},
				lualine_z = {}, -- keep it clean (optional)
			},
		},
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
		},
		opts = {
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
				lsp_doc_border = true,
			},
		},
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "modern", -- or "classic" / "helix"
			delay = 200,
			win = {
				no_overlap = false,
				width = { min = 30, max = 50 },
				height = { min = 4, max = 0.5 },
				col = -1, -- -1 = right edge
				row = -1, -- -1 = bottom edge (above cmdline)
				border = "rounded",
				padding = { 1, 2 },
				title = true,
				title_pos = "center",
				zindex = 1000,
			},
			spec = {
				{ "gl", group = "goto (LSP)" },
				{ "<leader>a", group = "AI" },
				{ "<leader>c", group = "code" },
				{ "<leader>f", group = "find/file" },
				{ "<leader>g", group = "git" },
				{ "<leader>i", group = "info" },
				{ "<leader>l", group = "list" },
				{ "<leader>o", group = "oil" },
				{ "<leader>q", group = "quit session" },
				{ "<leader>n", group = "test (neotest)" },
				{ "<leader>s", group = "search" },
				{ "<leader>t", group = "tasks" },
				{ "<leader>tc", group = "cmake" },
				{ "<leader>tcs", group = "reselect" },
				{ "<leader>u", group = "ui toggle" },
				{ "<leader>M", group = "macros" },
				{ "<leader>fw", group = "grep word", mode = { "n", "v" } },
			},
			icons = {
				mappings = false, -- set true if you want nerdfont icons next to entries
			},
		},
	},
}
