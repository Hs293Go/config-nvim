-- Protection against the master/main branch chaos:
--   * `branch = "master"` pins the legacy-but-stable API. The `main` branch is
--     a rewrite with an entirely different setup shape, missing the module
--     ecosystem we use (textobjects, incremental_selection, indent).
--   * `commit = ...` is required because upstream master is frozen but
--     `origin/HEAD -> main`, so `:Lazy update` will otherwise drift the lock to
--     a `main`-branch commit while keeping `branch = "master"` — leaving a
--     checkout that lacks `nvim-treesitter.configs`.
--   * `main = "nvim-treesitter.configs"` tells lazy.nvim's default opts handler
--     to call `require("nvim-treesitter.configs").setup(opts)` — without it,
--     lazy.nvim would call `require("nvim-treesitter").setup(opts)` and the
--     opts table would be silently ignored.
-- If you ever flip to the main branch, you must also rewrite this whole spec
-- and replace the module-style configs with `vim.treesitter.start()` autocmds.
return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		commit = "cf12346a3414fa1b06af75c79faebe7f76df080a",
		main = "nvim-treesitter.configs",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		opts = {
			-- Parser compilation needs a working C toolchain. Stock L4T images
			-- ship without one, so auto_install just produces error popups on
			-- every BufRead of an un-compiled filetype. The user installs
			-- parsers manually there via `:TSInstall <lang>` after wiring up a
			-- compiler.
			auto_install = not require("config.platform").is_jetson(),
			ensure_installed = {
				-- systems languages
				"c",
				"cpp",
				"cuda",
				"rust",

				-- scripting languages
				"python",
				"lua",
				"vim",
				"vimdoc",

				-- OS/system/build scripting
				"bash",
				"nix",
				"make",
				"cmake",
				"dockerfile",

				-- markup languages
				"latex",
				"markdown",
				"markdown_inline",

				-- config languages
				"toml",
				"xml",
				"json",
				"yaml",

				-- version control
				"gitignore",
				"diff",

				-- treesitter queries themselves
				"query",
				"regex",
			},
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = false,
			},
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<C-space>",
					node_incremental = "<C-space>",
					scope_incremental = false,
					node_decremental = "<bs>",
				},
			},
			indent = { enable = true },
			textobjects = {
				select = {
					enable = true,
					lookahead = true,
					keymaps = {
						["af"] = "@function.outer",
						["if"] = "@function.inner",
						["ac"] = "@class.outer",
						["ic"] = "@class.inner",
						["aa"] = "@parameter.outer",
						["ia"] = "@parameter.inner",
					},
				},
				move = {
					enable = true,
					set_jumps = true,
					goto_next_start = {
						["]f"] = "@function.outer",
						["]c"] = "@class.outer",
					},
					goto_next_end = {
						["]F"] = "@function.outer",
						["]C"] = "@class.outer",
					},
					goto_previous_start = {
						["[f"] = "@function.outer",
						["[c"] = "@class.outer",
					},
					goto_previous_end = {
						["[F"] = "@function.outer",
						["[C"] = "@class.outer",
					},
				},
			},
		},
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "master",
		commit = "5ca4aaa6efdcc59be46b95a3e876300cfead05ef",
		lazy = true,
	},
	{
		-- Pins the enclosing scope's header line(s) — the function/class/loop
		-- you're currently inside — to the top of the window while you scroll
		-- through its body. Reuses the same parsers configured above, so it
		-- needs nvim-treesitter loaded first.
		"nvim-treesitter/nvim-treesitter-context",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		event = { "BufReadPost", "BufNewFile" },
		keys = {
			{
				"[x",
				function()
					require("treesitter-context").go_to_context(vim.v.count1)
				end,
				mode = "n",
				desc = "Jump up to enclosing context",
			},
		},
		-- The module lives at `lua/treesitter-context.lua`, not a path lazy.nvim
		-- can derive from the repo name, so name it explicitly (same reason the
		-- nvim-treesitter spec above sets `main`).
		main = "treesitter-context",
		opts = {
			-- Cap the sticky header so deeply-nested code can't eat the
			-- viewport; 3 lines fits a signature plus one enclosing scope.
			max_lines = 3,
			-- When over max_lines, trim the innermost context first and keep
			-- the outermost (most orienting) scope visible.
			trim_scope = "outer",
			-- Track the scope under the cursor, not the topmost visible line.
			mode = "cursor",
			-- Underline the context so it reads as a pinned header.
			separator = "─",
			-- Don't repeat each pinned line's real buffer line number in the
			-- gutter; keep the header uncluttered.
			line_numbers = false,
		},
	},
}
