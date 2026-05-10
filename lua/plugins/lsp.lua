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
			{ "b0o/SchemaStore.nvim" },
			-- Declared so blink.cmp loads first and its enhanced LSP
			-- capabilities (snippet support, resolve, additional kinds) are
			-- already injected into vim.lsp.config("*") by the time the
			-- per-server config calls below run.
			{ "saghen/blink.cmp" },
		},
		lazy = false, -- Load immediately to ensure LSP servers are ready when opening files
		config = function()
			-- 1. Define shared capabilities. Use blink.cmp's enhanced set
			-- (Neovim defaults + completion-item resolve / snippet support /
			-- additional item kinds). Without this, every per-server
			-- vim.lsp.config(name, { capabilities = capabilities }) below
			-- deep-merge-overrides blink.cmp's wildcard injection — servers
			-- silently drop back to bare protocol defaults.
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			-- Mini-mason: source for repo-local tool binaries. Already required
			-- in init.lua (which prepends PATH and registers :ToolInstall /
			-- :ToolList); the require here just grabs the cached module so
			-- per-server cmd overrides can use tools.bin(name).
			local tools = require("config.tools")

			-- 2. Define our global LSP behavior (the new 'on_attach')
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local bufnr = args.buf
					local client = vim.lsp.get_client_by_id(args.data.client_id)

					if not client then
						return
					end
					if client:supports_method("textDocument/foldingRange") then
						vim.wo.foldmethod = "expr"
						vim.wo.foldexpr = "v:lua.vim.lsp.foldexpr()"
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
			local lua_ls_bin = tools.bin("lua_ls")
			if lua_ls_bin then
				lua_ls_config.cmd = { lua_ls_bin }
			end
			vim.lsp.config("lua_ls", lua_ls_config)
			vim.lsp.enable("lua_ls")
			vim.lsp.config("ts_ls", { capabilities = capabilities })
			vim.lsp.enable("ts_ls")
			vim.lsp.config("cmake", { capabilities = capabilities })
			vim.lsp.enable("cmake")

			-- Schema-aware servers via the mini-mason in config.tools.
			-- Servers are only enabled when their binary is resolvable
			-- (locally installed under .tools/npm/ or available on PATH).
			-- Run :ToolInstall to bootstrap on a fresh checkout.
			local jsonls_bin = tools.bin("jsonls")
			if jsonls_bin then
				vim.lsp.config("jsonls", {
					cmd = { jsonls_bin, "--stdio" },
					capabilities = capabilities,
					settings = {
						json = {
							schemas = require("schemastore").json.schemas(),
							validate = { enable = true },
						},
					},
				})
				vim.lsp.enable("jsonls")
			end

			local yamlls_bin = tools.bin("yamlls")
			if yamlls_bin then
				vim.lsp.config("yamlls", {
					cmd = { yamlls_bin, "--stdio" },
					capabilities = capabilities,
					settings = {
						yaml = {
							-- Defer schema list to SchemaStore.nvim so the bundled
							-- yamlls schemaStore (slow, partial) stays disabled.
							schemaStore = { enable = false, url = "" },
							schemas = require("schemastore").yaml.schemas(),
						},
					},
				})
				vim.lsp.enable("yamlls")
			end

			-- taplo doubles as a TOML formatter (already wired in conform.nvim).
			-- Running it as an LSP adds Cargo.toml / pyproject.toml schema
			-- validation and completion on top of the formatting role.
			local taplo_bin = tools.bin("taplo")
			if taplo_bin then
				vim.lsp.config("taplo", {
					cmd = { taplo_bin, "lsp", "stdio" },
					capabilities = capabilities,
				})
				vim.lsp.enable("taplo")
			end

			tools.notify_missing_once()

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
