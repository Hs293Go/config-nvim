local pack = require("config.pack")
local gh = pack.gh

-- COPILOT
-- =======
-- Skipped on Jetson — auto-triggered LSP-over-HTTPS round trips on
-- every keystroke make the editor feel sticky on weak CPUs, and the
-- panel server start-up itself adds startup time. ai/claudecode.nvim
-- (terminal-driven) remains available.
if not require("config.platform").is_jetson() then
	pack.add({ gh("zbirenbaum/copilot.lua") })
	require("copilot").setup({
		suggestion = {
			enabled = true,
			auto_trigger = true,
			hide_during_completion = false,
			keymap = {
				accept = "<Right>",
				accept_word = "<S-Right>",
				accept_line = "<C-S-Right>",
				next = "<C-Right>",
				prev = "<C-Left>",
			},
		},
		filetypes = {
			tex = true,
			markdown = true,
		},
	})
end

-- CLAUDECODE
-- ==========
-- The which-key spec in plugins.look sets the `<leader>a` group label.

pack.add({ gh("coder/claudecode.nvim") })

require("claudecode").setup({
	terminal = {
		snacks_win_opts = {
			keys = {
				-- <Esc> is passed through to Claude (interrupt), so use <C-q> instead
				claude_normal = {
					"<C-q>",
					function()
						vim.cmd("stopinsert")
					end,
					mode = "t",
					desc = "Claude: exit to normal mode",
				},
			},
		},
	},
})

pack.map({
	{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
	{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
	{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
	{ "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
	{ "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
	{ "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
	{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
	{
		"<leader>as",
		"<cmd>ClaudeCodeTreeAdd<cr>",
		desc = "Add file",
		ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
	},
	-- Diff management
	{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
	{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
})
