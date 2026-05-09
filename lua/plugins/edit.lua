return {
	{
		"kylechui/nvim-surround",
		version = "*", -- Use for stability; omit to use `main` branch for the latest features
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({
				-- Configuration here, or leave empty to use defaults
			})
		end,
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},
	{
		"MagicDuck/grug-far.nvim",
		cmd = "GrugFar",
		opts = {
			keymaps = {
				close = { n = "q" },
			},
		},
		keys = {
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
		},
	},
}
