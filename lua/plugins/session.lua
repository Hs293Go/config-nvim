local pack = require("config.pack")

pack.add({ pack.gh("folke/persistence.nvim") })

-- persistence saves a session only if one or more file buffers are open
-- (default `need = 1`). If you open the dashboard and quit, it saves nothing.
require("persistence").setup({})

-- Claude Code's external-editor prompt (Ctrl+G in the CLI) opens a temp file
-- named like `claude-prompt-<uuid>.md`. It's a real file buffer, so
-- `sessionoptions` alone can't exclude it; wipe such buffers right before
-- persistence runs mksession so they aren't restored next launch.
vim.api.nvim_create_autocmd("User", {
	pattern = "PersistenceSavePre",
	callback = function()
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_valid(buf) then
				local name = vim.fs.basename(vim.api.nvim_buf_get_name(buf))
				if name:match("^claude%-prompt%-[%w%-]+%.md$") then
					pcall(vim.api.nvim_buf_delete, buf, { force = true })
				end
			end
		end
	end,
})

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
