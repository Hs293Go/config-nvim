return {
	{
		"folke/snacks.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			explorer = {
				enabled = false,
				replace_netrw = false,
			},
			dashboard = {
				preset = {
					header = [[
       ██╗   ██╗██╗   ██╗ █████╗  █████╗  ██████╗ ██╗   ██╗██╗███╗   ███╗
 /\ /\ ███╗  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔═══██╗██║   ██║██║████╗ ████║
 =o o= █╔██╗ ██║ ╚████╔╝ ███████║███████║██║   ██║██║   ██║██║██╔████╔██║
 \_Y_/ █║╚██╗██║  ╚██╔╝  ██╔══██║██╔══██║██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
       █║ ╚████║   ██║   ██║  ██║██║  ██║╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
       ═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
]],
				},
			},
			terminal = {
				win = {
					wo = {
						winbar = "",
					},
				},
			},
		},
		keys = {
			{
				"<C-c>",
				function()
					if string.find(vim.bo.buftype, "terminal") == nil then
						Snacks.bufdelete()
					end
				end,
				desc = "Delete buffer",
			},
			{
				"<C-`>",
				function()
					local termlist = Snacks.terminal.list()
					local ok, claude_code = pcall(require, "claudecode.terminal")
					if ok then
						local claude_bufnr = claude_code.get_active_terminal_bufnr()
						for i = #termlist, 1, -1 do
							if termlist[i].buf == claude_bufnr then
								table.remove(termlist, i)
							end
						end
					end
					if #termlist == 0 then
						Snacks.terminal.get(nil, {
							env = { NVIM_TERM_UID = vim.fn.sha256(os.time() .. vim.loop.hrtime()) },
						})
						return
					end
					for _, term in pairs(termlist) do
						term:toggle()
					end
				end,
				mode = { "n", "t" },
				desc = "Terminal (cwd)",
			},
			{
				"<C-S-5>",
				function()
					Snacks.terminal.get(nil, {
						env = { NVIM_TERM_UID = vim.fn.sha256(os.time() .. vim.loop.hrtime()) },
					})
				end,
				mode = "t",
				desc = "Create new terminal",
			},
			{
				"<leader>gg",
				function()
					Snacks.lazygit()
				end,
				desc = "Lazygit",
			},
			{
				"<leader>gf",
				function()
					Snacks.lazygit.log_file()
				end,
				desc = "Lazygit current file history",
			},
			{
				"<leader>gl",
				function()
					Snacks.lazygit.log()
				end,
				desc = "Lazygit log (cwd)",
			},
			{
				"<leader>gB",
				function()
					Snacks.gitbrowse()
				end,
				desc = "Git browse (open in browser)",
				mode = { "n", "x" },
			},
		},
	},
}
