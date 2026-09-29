-- Markdown: two complementary layers.
--
--   * render-markdown.nvim — renders headings, lists, tables, code blocks,
--     callouts and inline/display math *inside* the buffer. Off by default
--     (the raw/rendered flip on mode change is distracting); toggle it on with
--     <leader>um for reading. Math goes through a LaTeX->unicode converter
--     (`utftex` or `latex2text`); without one on PATH, math stays raw.
--     Day-to-day math feedback comes from snacks.image popups (snacks.lua).
--
--   * markdown-preview.nvim — live browser preview with KaTeX, for anything a
--     terminal can't draw (fractions, matrices, big display math). Renders the
--     GitHub math syntaxes: `$...$`, `$$...$$`.
return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown" },
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
		opts = {
			enabled = false,
			file_types = { "markdown" },
			completions = { lsp = { enabled = true } },
			code = {
				sign = false,
				width = "block",
				right_pad = 1,
			},
			heading = {
				sign = false,
			},
			latex = {
				enabled = true,
				-- first executable wins; pylatexenc's latex2text is the easy install
				-- (`uv tool install pylatexenc`), utftex (libtexprintf) looks nicer
				converter = { "utftex", "latex2text" },
				position = "center",
			},
		},
		config = function(_, opts)
			require("render-markdown").setup(opts)
			Snacks.toggle({
				name = "Render Markdown",
				get = function()
					return require("render-markdown.state").enabled
				end,
				set = function(state)
					require("render-markdown").set(state)
				end,
			}):map("<leader>um")
		end,
	},
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		ft = { "markdown" },
		-- downloads a prebuilt server binary; no node/yarn build step needed
		build = function()
			require("lazy").load({ plugins = { "markdown-preview.nvim" } })
			vim.fn["mkdp#util#install"]()
		end,
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
			vim.g.mkdp_auto_close = 0 -- keep the tab open when switching buffers
			vim.g.mkdp_theme = "dark"
			vim.g.mkdp_preview_options = {
				katex = {},
				disable_sync_scroll = 0,
				sync_scroll_type = "middle",
			}
		end,
		keys = {
			{ "<leader>cp", "<cmd>MarkdownPreviewToggle<cr>", ft = "markdown", desc = "Markdown preview (browser)" },
		},
		config = function()
			-- the plugin registers its commands on FileType; replay it for the
			-- buffer that triggered the lazy load
			vim.cmd([[do FileType]])
		end,
	},
}
