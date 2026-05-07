return {
	{
		"mrjones2014/codesettings.nvim",
		-- these are the default settings just set `opts = {}` to use defaults
		opts = {},
		-- I recommend loading on these filetype so that the
		-- jsonls integration, lua_ls integration, and jsonc filetype setup works
		ft = { "json", "jsonc", "lua" },
	},
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
	{
		"mrcjkb/rustaceanvim",
		version = "v8.0.4",
		lazy = false,
		keys = {},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "mrjones2014/codesettings.nvim" },
		},
		lazy = false, -- Load immediately to ensure LSP servers are ready when opening files
		config = function()
			-- 1. Define shared capabilities
			local capabilities = vim.lsp.protocol.make_client_capabilities()

			-- 2. Define our global LSP behavior (the new 'on_attach')
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local bufnr = args.buf
					local client = vim.lsp.get_client_by_id(args.data.client_id)

					if not client then
						return
					end

					-- Server-specific logic inside LspAttach
					if client.name == "clangd" then
						vim.keymap.set(
							"n",
							"<A-o>",
							"<cmd>LspClangdSwitchSourceHeader<cr>",
							{ buffer = bufnr, desc = "Switch source/header" }
						)
					end

					if client.name == "ruff" then
						client.server_capabilities.hoverProvider = false
					end
				end,
			})
			vim.lsp.config("*", {
				before_init = function(_, config)
					local codesettings = require("codesettings")
					codesettings.with_local_settings(config.name, config)
				end,
			})
			-- 3. Configure Servers via vim.lsp.enable
			-- This automatically starts the servers when a matching filetype is opened

			-- Clangd
			vim.lsp.config("clangd", {
				cmd = {
					"clangd",
					"--background-index",
					"--clang-tidy",
					"--header-insertion=never",
					"--fallback-style=google",
				},
				capabilities = capabilities,
			})
			vim.lsp.enable("clangd")

			-- Python
			vim.lsp.config("ruff", {
				capabilities = capabilities,
			})
			vim.lsp.enable("ruff")

			vim.lsp.config("ty", { capabilities = capabilities })
			vim.lsp.enable("ty")

			-- LaTeX
			vim.lsp.config("texlab", {
				capabilities = capabilities,
				settings = {
					texlab = {
						build = { executable = "", onSave = false },
						chktex = { onOpenAndSave = true, onEdit = true },
					},
				},
			})
			vim.lsp.enable("texlab")

			-- Lua / TS / CMake
			local lua_ls_config = {
				capabilities = capabilities,
				settings = { Lua = { diagnostics = { globals = { "vim" } }, telemetry = { enable = false } } },
			}
			-- Prefer the repo-local lua-language-server installed via `make lua-ls`.
			-- Falls back to whatever's on PATH (or the lspconfig default) if absent.
			local local_lua_ls =
				vim.fs.joinpath(vim.fn.stdpath("config"), ".tools/lua_ls/bin/lua-language-server")
			if vim.fn.executable(local_lua_ls) == 1 then
				lua_ls_config.cmd = { local_lua_ls }
			end
			vim.lsp.config("lua_ls", lua_ls_config)
			vim.lsp.enable("lua_ls")
			vim.lsp.config("ts_ls", { capabilities = capabilities })
			vim.lsp.enable("ts_ls")
			vim.lsp.config("cmake", { capabilities = capabilities })
			vim.lsp.enable("cmake")

			-- Diagnostics UI
			vim.diagnostic.config({ virtual_text = true, signs = true, underline = true })
		end,
		keys = {
			{ "<leader>il", "<cmd>LspInfo<cr>", desc = "Show LSP info" },
			{ "<leader>cr", vim.lsp.buf.rename, desc = "LSP: Rename symbol" },
			{ "<leader>ca", vim.lsp.buf.code_action, desc = "LSP: Code actions", mode = { "n", "v" } },
			{ "<leader>cd", vim.diagnostic.open_float, desc = "Line diagnostics (float)" },
			{ "glt", vim.lsp.buf.type_definition, desc = "Type Definition" },
			{ "glr", vim.lsp.buf.references, desc = "References" },
			{ "glD", vim.lsp.buf.implementation, desc = "Implementation" },
			{ "glo", vim.lsp.buf.document_symbol, desc = "Document Symbols" },
			{ "glW", vim.lsp.buf.workspace_symbol, desc = "Workspace Symbols" },
			{ "gd", vim.lsp.buf.definition, desc = "LSP go to definition" },
		},
	},
}
