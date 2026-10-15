local pack = require("config.pack")

pack.add({ pack.gh("stevearc/conform.nvim") })

local stylua_bin = require("config.tools").bin("stylua")

require("conform").setup({
	notify_on_error = false,
	default_format_opts = { lsp_format = "fallback" },
	formatters_by_ft = {
		lua = { "stylua" },
		sh = { "shfmt" },
		cmake = { "cmake_format" },
		markdown = { "prettierd", "prettier", stop_after_first = true },
		tex = { "latexindent" },
		python = { "ruff_format", "ruff_organize_imports" },
		c = { "clang-format", lsp_format = "prefer" },
		cpp = { "clang-format", lsp_format = "prefer" },
		cuda = { "clang-format", lsp_format = "prefer" },
		toml = { "taplo" },
		json = { "jq", "prettier", stop_after_first = true },
		jsonc = { "prettierd", "prettier", stop_after_first = true },
		xml = { "xmllint" },
		yaml = { "yamlfmt", "prettier", stop_after_first = true },
		rust = { "rustfmt" },
		nix = { "nixfmt" },
		javascript = { "prettierd", "prettier", stop_after_first = true },
		typescript = { "prettierd", "prettier", stop_after_first = true },
		javascriptreact = { "prettierd", "prettier", stop_after_first = true },
		typescriptreact = { "prettierd", "prettier", stop_after_first = true },
		html = { "prettierd", "prettier", stop_after_first = true },
		sql = { "pg_format" },
		typst = { "typstyle" },
		["_"] = { "trim_whitespace" },
	},
	format_on_save = function(bufnr)
		if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
			return
		end
		return { timeout_ms = 1000, lsp_format = "fallback" }
	end,
	formatters = {
		latexindent = { append_args = { "--logfile=/dev/null", "--yaml", 'defaultIndent: "    "' } },
		stylua = stylua_bin and { command = stylua_bin } or nil,
	},
})

pack.map({
	{
		"<leader>cf",
		function()
			require("conform").format({ async = true, lsp_format = "fallback" })
		end,
		mode = { "n", "v" },
		desc = "Format",
	},
	{
		"<leader>if",
		":ConformInfo<CR>",
		desc = "Show formatter info",
	},
})
