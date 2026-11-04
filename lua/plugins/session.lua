local pack = require("config.pack")

pack.add({ pack.gh("folke/persistence.nvim") })

-- persistence saves a session only if one or more file buffers are open
-- (default `need = 1`). If you open the dashboard and quit, it saves nothing.
require("persistence").setup({})

pack.map({
	{
		"<leader>qs",
		function()
			require("persistence").load()
		end,
		desc = "Restore session for cwd",
	},
	{
		"<leader>ql",
		function()
			require("persistence").load({ last = true })
		end,
		desc = "Restore last session",
	},
	{
		"<leader>qd",
		function()
			require("persistence").stop()
		end,
		desc = "Don't save current session",
	},
})
