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
require("plugins.snacks")
require("plugins.ts")

local pack = require("config.pack")
local gh = pack.gh

-- markdown-preview reads these options when its plugin/ script runs. Set them
-- before you add the plugin. The PackChanged hook in config/pack.lua downloads
-- the server binary.
vim.g.mkdp_filetypes = { "markdown" }
vim.g.mkdp_auto_close = 0 -- keep the tab open when switching buffers
vim.g.mkdp_theme = "dark"
vim.g.mkdp_preview_options = {
	katex = {},
	disable_sync_scroll = 0,
	sync_scroll_type = "middle",
}

pack.add({
	gh("nvim-tree/nvim-web-devicons"),
	gh("MeanderingProgrammer/render-markdown.nvim"),
	gh("iamcco/markdown-preview.nvim"),
})

require("render-markdown").setup({
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
})
Snacks.toggle({
	name = "Render Markdown",
	get = function()
		return require("render-markdown.state").enabled
	end,
	set = function(state)
		require("render-markdown").set(state)
	end,
}):map("<leader>um")

pack.map({
	{ "<leader>cp", "<cmd>MarkdownPreviewToggle<cr>", ft = "markdown", desc = "Markdown preview (browser)" },
})
