-- Persistent diagnostics/symbol panels (trouble.nvim) + non-LSP linters
-- (nvim-lint). Together they cover the diagnostic surface that LSP servers
-- don't reach: shellcheck for shell, markdownlint, yamllint, hadolint.
--
-- Keybinds live under <leader>l* ("list X") to mirror <leader>f* pickers:
--   <leader>fd / <leader>ld — diagnostics: picker vs. panel
--   <leader>fs / <leader>ls — symbols: picker vs. panel
--   <leader>ft / <leader>lt — todos: picker vs. panel
-- <leader>i* stays for tool-info dumps (LspInfo, ConformInfo).
local pack = require("config.pack")
local gh = pack.gh

pack.add({
	gh("nvim-tree/nvim-web-devicons"),
	gh("folke/trouble.nvim"),
	gh("mfussenegger/nvim-lint"),
})

-- TROUBLE
-- =======
-- The `todo` mode uses todo-comments.nvim (plugins.nav).

require("trouble").setup({
	focus = true,
})

pack.map({
	{ "<leader>ld", "<cmd>Trouble diagnostics toggle<cr>", desc = "List diagnostics (workspace)" },
	{
		"<leader>lD",
		"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
		desc = "List diagnostics (buffer)",
	},
	{
		"<leader>ls",
		"<cmd>Trouble symbols toggle focus=false<cr>",
		desc = "List symbols",
	},
	{
		"<leader>lr",
		"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
		desc = "List LSP refs/defs",
	},
	{ "<leader>lt", "<cmd>Trouble todo toggle<cr>", desc = "List todos" },
	{ "<leader>lq", "<cmd>Trouble qflist toggle<cr>", desc = "List quickfix" },
	{ "<leader>lQ", "<cmd>Trouble loclist toggle<cr>", desc = "List loclist" },
})

-- NVIM-LINT
-- =========

local lint = require("lint")
-- Only fill gaps that LSP doesn't already cover. LSP-side linting
-- is already on for: ruff (python), clangd --clang-tidy (c/cpp),
-- rust-analyzer (rust), texlab+chktex (tex), lua_ls (lua).
lint.linters_by_ft = {
	sh = { "shellcheck" },
	bash = { "shellcheck" },
	markdown = { "markdownlint" },
	yaml = { "yamllint" },
	dockerfile = { "hadolint" },
}

vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
	group = vim.api.nvim_create_augroup("user_nvim_lint", { clear = true }),
	callback = function()
		-- Linters are not installed by this config. nvim-lint spawns the
		-- binary blindly and raises an error notification on every trigger
		-- when it is missing, so only run the linters that are on PATH.
		local names = vim.tbl_filter(function(name)
			local linter = lint.linters[name]
			if type(linter) == "function" then
				linter = linter()
			end
			local cmd = linter and linter.cmd
			if type(cmd) == "function" then
				cmd = cmd()
			end
			return type(cmd) == "string" and vim.fn.executable(cmd) == 1
		end, lint.linters_by_ft[vim.bo.filetype] or {})
		if #names > 0 then
			lint.try_lint(names)
		end
	end,
})
