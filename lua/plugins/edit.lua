local pack = require("config.pack")
local gh = pack.gh

pack.add({
	-- Use release tags because they are stable. To get the newest features
	-- from `main`, remove `version`.
	{ src = gh("kylechui/nvim-surround"), version = vim.version.range("*") },
	gh("windwp/nvim-autopairs"),
	gh("MagicDuck/grug-far.nvim"),
})

require("nvim-surround").setup()

require("nvim-autopairs").setup({})

require("grug-far").setup({
	keymaps = {
		close = { n = "q" },
	},
})

pack.map({
	{
		"<leader>sr",
		function()
			require("grug-far").open()
		end,
		desc = "Search & replace (grug-far)",
	},
	{
		"<leader>sr",
		function()
			require("grug-far").with_visual_selection()
		end,
		mode = "v",
		desc = "Search & replace selection (grug-far)",
	},
})
