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
			-- Platform gate: Jetson devices skip heavy LSP behaviors that
			-- otherwise pin one CPU core or stream redundant traffic on every
			-- buffer event. See lua/config/platform.lua for detection details.
			local is_jetson = require("config.platform").is_jetson()

			-- 2. Define our global LSP behavior (the new 'on_attach')
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local bufnr = args.buf
					local client = vim.lsp.get_client_by_id(args.data.client_id)

					if not client then
						return
					end
					-- LSP folding requests on every fold operation are too slow
					-- on Jetson; stick with the global treesitter foldexpr
					-- there.
					if not is_jetson and client:supports_method("textDocument/foldingRange") then
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

					-- texlab: vimtex owns LaTeX editing (compile, view, errors,
					-- completion). Keep texlab around purely for cross-reference
					-- navigation (definitions, references, symbols, hover) and
					-- mute everything else so the two don't fight.
					if client.name == "texlab" then
						client.server_capabilities.completionProvider = nil
						client.server_capabilities.documentFormattingProvider = nil
						client.server_capabilities.documentRangeFormattingProvider = nil
						client.handlers["textDocument/publishDiagnostics"] = function() end
					end

					-- Code lens: refresh on attach + on buffer activity.
					-- rust-analyzer (Run | Debug above tests), ts_ls
					-- (reference counts), gopls (test runners) all use it.
					-- Skipped on Jetson — repeated codeLens queries on every
					-- BufEnter / InsertLeave / BufWritePost are too costly.
					-- <leader>cl still runs the lens on demand.
					if not is_jetson and client:supports_method("textDocument/codeLens") then
						vim.lsp.codelens.refresh({ bufnr = bufnr })
						local g = vim.api.nvim_create_augroup("user_codelens_" .. bufnr, { clear = true })
						vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "BufWritePost" }, {
							group = g,
							buffer = bufnr,
							callback = function()
								vim.lsp.codelens.refresh({ bufnr = bufnr })
							end,
						})
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

			-- Clangd. On Jetson, drop --background-index (full project index
			-- pegs the CPU and bloats disk) and --clang-tidy (per-diagnostic
			-- tidy checks compound the slowdown). The trade-off is no
			-- cross-TU navigation cache and only compiler-level diagnostics;
			-- acceptable on the platform where the user mostly reads code.
			local clangd_cmd = { "clangd", "--header-insertion=never", "--fallback-style=google" }
			if not is_jetson then
				table.insert(clangd_cmd, 2, "--clang-tidy")
				table.insert(clangd_cmd, 2, "--background-index")
			end
			vim.lsp.config("clangd", {
				cmd = clangd_cmd,
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

			-- LaTeX — texlab is kept purely as a navigation backend (go-to-label,
			-- references, symbols, hover). Build/view/diagnostics/completion are
			-- vimtex's job; the LspAttach branch above mutes the rest.
			vim.lsp.config("texlab", { capabilities = capabilities })
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

			-- bashls supplements shellcheck (already running via nvim-lint).
			-- bashls adds hover, jump-to-definition for variables/functions,
			-- and completion that shellcheck-as-a-linter can't provide.
			local bashls_bin = tools.bin("bashls")
			if bashls_bin then
				vim.lsp.config("bashls", {
					cmd = { bashls_bin, "start" },
					capabilities = capabilities,
				})
				vim.lsp.enable("bashls")
			end

			tools.notify_missing_once()

			-- Diagnostics UI
			vim.diagnostic.config({
				virtual_text = { source = "if_many", spacing = 2 },
				signs = true,
				underline = true,
				-- Errors paint over warnings on the same line; quieter signs.
				severity_sort = true,
				-- Don't churn diagnostics while typing — perf win on Jetson,
				-- and matches VSCode's "save to validate" feel for most LSPs.
				update_in_insert = false,
				float = { border = "rounded", source = "if_many" },
			})
		end,
		keys = {
			{ "<leader>il", "<cmd>LspInfo<cr>", desc = "Show LSP info" },
			{ "<leader>cr", vim.lsp.buf.rename, desc = "LSP: Rename symbol" },
			{ "<leader>ca", vim.lsp.buf.code_action, desc = "LSP: Code actions", mode = { "n", "v" } },
			{ "<leader>cd", vim.diagnostic.open_float, desc = "Line diagnostics (float)" },
			{ "<leader>cl", vim.lsp.codelens.run, desc = "Run code lens" },
			{ "glt", vim.lsp.buf.type_definition, desc = "Type Definition" },
			{ "glr", vim.lsp.buf.references, desc = "References" },
			{ "glD", vim.lsp.buf.implementation, desc = "Implementation" },
			{ "glo", vim.lsp.buf.document_symbol, desc = "Document Symbols" },
			{ "glW", vim.lsp.buf.workspace_symbol, desc = "Workspace Symbols" },
			-- gd is intentionally bound by fzf-lua (nav.lua) to lsp_definitions
			-- with jump1=true. The bare g* family lives in fzf-lua; gl* is the
			-- direct-LSP counterpart kept here for keymap symmetry.
		},
	},
}
