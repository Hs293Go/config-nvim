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
			notifier = { enabled = true },
			-- Buffer-backed `vim.ui.input` — i.e. LSP rename, overseer task
			-- param prompts, and anything else calling vim.ui.input gets a real
			-- floating buffer where <Esc> drops to normal mode for full vim
			-- editing (motions, registers, undo) before <CR> submits.
			-- Render the buffer before lazy-loaded plugins finish; faster
			-- perceived startup on slow CPUs.
			quickfile = { enabled = true },
			-- Unified signcolumn + foldcolumn + linenr. Replaces the default
			-- now that signcolumn="yes" + foldcolumn="1" both want gutter
			-- space.
			statuscolumn = { enabled = true },
			-- Indent guides + scope highlighting (subsumes snacks.scope).
			indent = { enabled = true },
			-- Floating UI for vim.ui.input (matches the fzf-lua handling of
			-- vim.ui.select in nav.lua).
			input = { enabled = true },
			-- Highlight other occurrences of the symbol under cursor via LSP
			-- document highlight (VSCode default behavior).
			words = { enabled = true },
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
		config = function(_, opts)
			require("snacks").setup(opts)

			-- UI toggles under <leader>u*. Each call returns a Snacks.toggle
			-- handle whose :map(...) wires the keybind, registers the
			-- description with which-key, and notifies on change via
			-- Snacks.notifier.
			local toggle = Snacks.toggle
			toggle.option("spell", { name = "Spelling" }):map("<leader>us")
			toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
			toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
			toggle.line_number():map("<leader>ul")
			toggle.diagnostics():map("<leader>ud")
			toggle.treesitter():map("<leader>uT")
			toggle.inlay_hints():map("<leader>uh")
			toggle
				.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
				:map("<leader>uc")
			toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")

			-- Conform autoformat: buffer-local takes precedence over global,
			-- matching the format_on_save guard in fmt.lua.
			toggle
				.new({
					name = "Auto Format (Global)",
					get = function()
						return not vim.g.disable_autoformat
					end,
					set = function(state)
						vim.g.disable_autoformat = not state
					end,
				})
				:map("<leader>uF")
			toggle
				.new({
					name = "Auto Format (Buffer)",
					get = function()
						return not (vim.b.disable_autoformat or vim.g.disable_autoformat)
					end,
					set = function(state)
						vim.b.disable_autoformat = not state
					end,
				})
				:map("<leader>uf")
		end,
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
