return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>cf",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			mode = { "n", "v" },
			desc = "Format",
		},
	},
	opts = function()
		local opts = {
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
				json = { "prettierd", "prettier", stop_after_first = true },
				jsonc = { "prettierd", "prettier", stop_after_first = true },
				xml = { "xmllint" },
				yaml = { "prettierd", "prettier", stop_after_first = true },
				rust = { "rustfmt" },
				nix = { "nixfmt" },
				javascript = { "prettierd", "prettier", stop_after_first = true },
				typescript = { "prettierd", "prettier", stop_after_first = true },
				javascriptreact = { "prettierd", "prettier", stop_after_first = true },
				typescriptreact = { "prettierd", "prettier", stop_after_first = true },
				html = { "prettierd", "prettier", stop_after_first = true },
				sql = { "pg_format" },
				["_"] = { "trim_whitespace" },
			},
			format_on_save = function(bufnr)
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end
				return { timeout_ms = 1000, lsp_format = "fallback" }
			end,
		}

		-- Prefer the repo-local stylua installed via `make lua-ls`. Falls back
		-- to whatever's on PATH if absent.
		local local_stylua = vim.fs.joinpath(vim.fn.stdpath("config"), ".tools/stylua/bin/stylua")
		if vim.fn.executable(local_stylua) == 1 then
			opts.formatters = { stylua = { command = local_stylua } }
		end

		return opts
	end,
}
