return {
	{
		"saghen/blink.cmp",
		version = "1.*",
		dependencies = {
			{ "L3MON4D3/LuaSnip", version = "v2.*" }, -- Snippet engine
			{
				"saghen/blink.compat",
				version = "*",
				lazy = true,
				opts = {},
			},
			"micangl/cmp-vimtex", -- Source for vimtex completions
			"onsails/lspkind.nvim", -- Icons for completions
		},
		opts = {
			keymap = {
				preset = "none",
				["<Tab>"] = { "select_next", "fallback" },
				["<S-Tab>"] = { "select_prev", "fallback" },
				["<CR>"] = { "select_and_accept", "fallback" },
				["<C-e>"] = { "hide", "fallback" },
				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },
				["<C-j>"] = { "snippet_forward", "fallback" },
				["<C-k>"] = { "snippet_backward", "fallback" },
			},
			completion = {
				ghost_text = {
					enabled = false, -- Reserve ghost test for AI autosuggestion only
				},
			},
			-- Show parameter hints while typing inside a function call.
			-- VSCode-default behavior; closes the last big completion-UI gap.
			signature = { enabled = true },
			snippets = { preset = "luasnip" },
			sources = {
				default = { "lsp", "path", "snippets" },
				per_filetype = {
					tex = { "vimtex", "lsp", "path", "snippets" },
				},
				providers = {
					vimtex = {
						name = "vimtex",
						module = "blink.compat.source",
						score_offset = 100,
					},
				},
				transform_items = function(_, items) -- REMOVE "buffer" even if plugins included it
					return vim.tbl_filter(function(item)
						return item.kind ~= vim.lsp.protocol.CompletionItemKind.Text
					end, items)
				end,
			},
		},
	},
	{
		"L3MON4D3/LuaSnip",
		dependencies = {
			"rafamadriz/friendly-snippets", -- Snippet collection
			"honza/vim-snippets", -- Snippet collection
		},
		version = "v2.4.0",
		config = function()
			-- Load snippets from friendly-snippets (vscode format)
			require("luasnip.loaders.from_vscode").lazy_load()
			require("luasnip.loaders.from_vscode").lazy_load({ paths = "~/.config/nvim/snippets" })
			-- Load snippets from vim-snippets (snipmate format)
			require("luasnip.loaders.from_snipmate").lazy_load()
		end,
	},
	{
		"abecodes/tabout.nvim",
		lazy = false,
		config = function()
			require("tabout").setup({
				tabkey = "<Tab>", -- key to trigger tabout, set to an empty string to disable
				backwards_tabkey = "<S-Tab>", -- key to trigger backwards tabout, set to an empty string to disable
				act_as_tab = true, -- shift content if tab out is not possible
				act_as_shift_tab = false, -- reverse shift content if tab out is not possible (if your keyboard/terminal supports <S-Tab>)
				default_tab = "<C-t>", -- shift default action (only at the beginning of a line, otherwise <TAB> is used)
				default_shift_tab = "<C-d>", -- reverse shift default action,
				enable_backwards = true, -- well ...
				completion = false, -- if the tabkey is used in a completion pum
				tabouts = {
					{ open = "'", close = "'" },
					{ open = '"', close = '"' },
					{ open = "`", close = "`" },
					{ open = "(", close = ")" },
					{ open = "[", close = "]" },
					{ open = "{", close = "}" },
				},
				ignore_beginning = true, --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]]
				exclude = {}, -- tabout will ignore these filetypes
			})
		end,
		opt = true, -- Set this to true if the plugin is optional
		event = "InsertCharPre", -- Set the event to 'InsertCharPre' for better compatibility
		priority = 1000,
	},
}
