return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000, -- load before other plugins subscribe to ColorScheme
		opts = {
			flavour = "mocha", -- catppuccin uses British spelling
			transparent_background = true,
			integrations = {
				blink_cmp = true,
			},
		},
		config = function(_, opts)
			-- A custom `config` opts out of lazy.nvim's default
			-- `require(<plugin>).setup(opts)` — must call setup ourselves.
			require("catppuccin").setup(opts)
			vim.cmd.colorscheme("catppuccin-mocha")
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		opts = {
			icons_enabled = true,
			component_separators = { left = "", right = "" },
			section_separators = { left = "", right = "" },
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
				{ "<leader>a", group = "AI" },
				{ "<leader>c", group = "code" },
				{ "<leader>f", group = "find/file" },
				{ "<leader>g", group = "git" },
				{ "<leader>i", group = "info" },
				{ "<leader>l", group = "list" },
				{ "<leader>o", group = "oil" },
				{ "<leader>q", group = "quit session" },
				{ "<leader>n", group = "test (neotest)" },
				{ "<leader>t", group = "tasks" },
				{ "<leader>tc", group = "cmake" },
				{ "<leader>tcs", group = "reselect" },
				{ "<leader>M", group = "macros" },
				{ "<leader>fw", group = "grep word", mode = { "n", "v" } },
			},
			icons = {
				mappings = false, -- set true if you want nerdfont icons next to entries
			},
		},
	},
}
