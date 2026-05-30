return {
	{
		"zbirenbaum/copilot.lua",
		-- Skipped on Jetson — auto-triggered LSP-over-HTTPS round trips on
		-- every keystroke make the editor feel sticky on weak CPUs, and the
		-- panel server start-up itself adds startup time. ai/claudecode.nvim
		-- (terminal-driven) remains available.
		cond = function()
			return not require("config.platform").is_jetson()
		end,
		config = function()
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
		end,
	},
	{
		"coder/claudecode.nvim",
		dependencies = { "folke/snacks.nvim" },
		config = true,
		keys = {
			{ "<leader>a", nil, desc = "AI/Claude Code" },
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
		},
	},
}
