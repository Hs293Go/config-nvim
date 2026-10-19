local pack = require("config.pack")

pack.add({ pack.gh("lewis6991/gitsigns.nvim") })

require("gitsigns").setup({
	signs = {
		add = { text = "▎" },
		change = { text = "▎" },
		delete = { text = "" },
		topdelete = { text = "" },
		changedelete = { text = "▎" },
		untracked = { text = "▎" },
	},
	signs_staged = {
		add = { text = "▎" },
		change = { text = "▎" },
		delete = { text = "" },
		topdelete = { text = "" },
		changedelete = { text = "▎" },
	},
	on_attach = function(buffer)
		local gs = package.loaded.gitsigns

		local function map(mode, l, r, desc)
			vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc, silent = true })
		end

		map("n", "]h", function()
			if vim.wo.diff then
				vim.cmd.normal({ "]c", bang = true })
			else
				gs.nav_hunk("next")
			end
		end, "Next Hunk")
		map("n", "[h", function()
			if vim.wo.diff then
				vim.cmd.normal({ "[c", bang = true })
			else
				gs.nav_hunk("prev")
			end
		end, "Prev Hunk")
		map("n", "]H", function()
			gs.nav_hunk("last")
		end, "Last Hunk")
		map("n", "[H", function()
			gs.nav_hunk("first")
		end, "First Hunk")
		map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
		map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
		map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
		map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
		map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
		map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
		map("n", "<leader>ghb", function()
			gs.blame_line({ full = true })
		end, "Blame Line")
		map("n", "<leader>ghB", function()
			gs.blame()
		end, "Blame Buffer")
		map("n", "<leader>ghd", gs.diffthis, "Diff This")
		map("n", "<leader>ghD", function()
			gs.diffthis("~")
		end, "Diff This ~")
		map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
	end,
})

pack.add({
	pack.gh("nvim-lua/plenary.nvim"), -- octo dependency
	-- octo picker. octo.setup() loads the picker provider at once, and
	-- plugins.nav (which also adds fzf-lua) loads after this module.
	pack.gh("ibhagwan/fzf-lua"),
	pack.gh("sindrets/diffview.nvim"),
	pack.gh("pwntester/octo.nvim"),
})

local function close_diffview()
	vim.cmd("DiffviewClose")
end

require("diffview").setup({
	enhanced_diff_hl = true,
	keymaps = {
		view = { { "n", "q", close_diffview, { desc = "Close Diffview" } } },
		file_panel = { { "n", "q", close_diffview, { desc = "Close Diffview" } } },
		file_history_panel = { { "n", "q", close_diffview, { desc = "Close Diffview" } } },
	},
})

-- Octo uses the `gh` CLI for auth. Run `gh auth login` once.
require("octo").setup({ picker = "fzf-lua" })

pack.map({
	{ "<leader>gdd", "<cmd>DiffviewOpen<cr>", desc = "Diff uncommitted changes" },
	{ "<leader>gdm", "<cmd>DiffviewOpen origin/HEAD...HEAD --imply-local<cr>", desc = "Diff branch vs origin default" },
	{ "<leader>gdh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
	{ "<leader>gdh", ":DiffviewFileHistory<cr>", mode = "x", desc = "Line-range history" },
	{ "<leader>gdH", "<cmd>DiffviewFileHistory<cr>", desc = "Repo history" },
	{ "<leader>gdq", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
	{ "<leader>gpl", "<cmd>Octo pr list<cr>", desc = "List PRs" },
	{ "<leader>gps", "<cmd>Octo pr search<cr>", desc = "Search PRs" },
	{ "<leader>gpc", "<cmd>Octo pr create<cr>", desc = "Create PR" },
	{ "<leader>gpr", "<cmd>Octo review<cr>", desc = "Start / resume review" },
	{ "<leader>gpS", "<cmd>Octo review submit<cr>", desc = "Submit review" },
	{ "<leader>gpi", "<cmd>Octo issue list<cr>", desc = "List issues" },
})
