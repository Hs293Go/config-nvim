-- Test explorer DX. Neotest provides the tree-view panel, gutter signs for
-- pass/fail, jump-to-failure, watch mode, and run-nearest — the IDE-classic
-- test UX. Adapter is pytest for now (Python is the daily robotics test
-- driver); add neotest-rust / neotest-gtest later if cargo test / ctest
-- through overseer feels too coarse.
return {
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"nvim-neotest/neotest-python",
		},
		ft = { "python" },
		cmd = { "Neotest" },
		keys = {
			-- Daily actions (3 keys)
			{
				"<leader>nr",
				function()
					require("neotest").run.run()
				end,
				desc = "Run nearest test",
			},
			{
				"<leader>nf",
				function()
					require("neotest").run.run(vim.fn.expand("%"))
				end,
				desc = "Run file tests",
			},
			{
				"<leader>nl",
				function()
					require("neotest").run.run_last()
				end,
				desc = "Re-run last test",
			},
			{
				"<leader>nx",
				function()
					require("neotest").run.stop()
				end,
				desc = "Stop running tests",
			},

			-- UI (4 keys but rarer than the daily ones)
			{
				"<leader>ns",
				function()
					require("neotest").summary.toggle()
				end,
				desc = "Toggle test summary tree",
			},
			{
				"<leader>no",
				function()
					require("neotest").output.open({ enter = true, auto_close = true })
				end,
				desc = "Show test output (float)",
			},
			{
				"<leader>np",
				function()
					require("neotest").output_panel.toggle()
				end,
				desc = "Toggle output panel",
			},
			{
				"<leader>nw",
				function()
					require("neotest").watch.toggle(vim.fn.expand("%"))
				end,
				desc = "Watch file tests",
			},

			-- Navigation between tests
			{
				"]n",
				function()
					require("neotest").jump.next({ status = "failed" })
				end,
				desc = "Next failed test",
			},
			{
				"[n",
				function()
					require("neotest").jump.prev({ status = "failed" })
				end,
				desc = "Previous failed test",
			},
		},
		config = function()
			require("neotest").setup({
				adapters = {
					require("neotest-python")({
						runner = "pytest",
						args = { "--log-level", "DEBUG" },
						-- Prefer a uv-managed `.venv` if it exists; fall back to
						-- whatever python is on PATH (which the user's shell may
						-- already have venv-activated).
						python = function()
							local venv = vim.fs.joinpath(vim.uv.cwd() or ".", ".venv/bin/python")
							if vim.fn.executable(venv) == 1 then
								return venv
							end
							return "python"
						end,
					}),
				},
				summary = {
					animated = false,
					open = "botright vsplit | vertical resize 50",
				},
				output = {
					enabled = true,
					open_on_run = "short",
				},
				output_panel = {
					enabled = true,
					open = "botright split | resize 15",
				},
				quickfix = {
					enabled = true,
					open = false, -- don't auto-open qf — `]n` / `[n` is enough
				},
				status = {
					virtual_text = true,
					signs = true,
				},
				icons = {
					running = "",
					passed = "",
					failed = "",
					skipped = "",
					unknown = "",
				},
			})
		end,
	},
}
