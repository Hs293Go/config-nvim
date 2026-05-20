-- Overseer + bespoke task orchestration. The Lua under `lua/tasks/*` is
-- pure logic; this file does the lazy-spec wiring and binds keymaps.
--
-- Keymap layout: `<leader>t` is the canonical "tasks" namespace. The daily
-- CMake build/test/launch keys also live under `<leader>C*` as direct
-- aliases for muscle memory (3 keys vs. 4). Reselects, configure, just,
-- and the picker only have canonical bindings — they're rarer.
return {
	{
		"stevearc/overseer.nvim",
		dependencies = { "ibhagwan/fzf-lua" },
		cmd = {
			"OverseerOpen",
			"OverseerClose",
			"OverseerToggle",
			"OverseerRun",
			"OverseerInfo",
			"OverseerBuild",
			"OverseerQuickAction",
			"OverseerTaskAction",
		},
		---@module 'overseer'
		---@type overseer.SetupOpts
		opts = {},
		keys = {
			-- Picker / panel (canonical)
			{ "<leader>tr", "<cmd>OverseerRun<cr>", desc = "Run task (picker)" },
			{ "<leader>tt", "<cmd>OverseerToggle<cr>", desc = "Toggle task list" },
			{
				"<leader>tl",
				function()
					local overseer = require("overseer")
					local tasks = overseer.list_tasks({ recent_first = true })
					if vim.tbl_isempty(tasks) then
						vim.notify("No overseer tasks to rerun", vim.log.levels.WARN)
						return
					end
					overseer.run_action(tasks[1], "restart")
				end,
				desc = "Rerun last task",
			},

			-- just: dynamic recipes; bypass overseer's template registry
			{
				"<leader>tj",
				function()
					require("tasks.just").pick_and_run()
				end,
				desc = "just: pick and run recipe",
			},

			-- CMake (canonical — under <leader>tc*)
			{
				"<leader>tcc",
				function()
					require("tasks.cmake").configure()
				end,
				desc = "CMake: Configure",
			},
			{
				"<leader>tcb",
				function()
					require("tasks.cmake").build()
				end,
				desc = "CMake: Build",
			},
			{
				"<leader>tct",
				function()
					require("tasks.cmake").test()
				end,
				desc = "CMake: Test",
			},
			{
				"<leader>tcr",
				function()
					require("tasks.cmake").launch()
				end,
				desc = "CMake: Launch target",
			},
			{
				"<leader>tcsc",
				function()
					require("tasks.cmake").reselect_configure()
				end,
				desc = "CMake: Reselect configure preset",
			},
			{
				"<leader>tcsb",
				function()
					require("tasks.cmake").reselect_build()
				end,
				desc = "CMake: Reselect build preset",
			},
			{
				"<leader>tcsl",
				function()
					require("tasks.cmake").reselect_launch()
				end,
				desc = "CMake: Reselect launch target",
			},

			-- Aliases for the daily CMake actions (muscle memory).
			-- `<leader>Cc` (Configure) is intentionally NOT aliased — it's rare;
			-- use `<leader>tcc`. Reselects are also canonical-only.
			{
				"<leader>Cb",
				function()
					require("tasks.cmake").build()
				end,
				desc = "CMake: Build",
			},
			{
				"<leader>Ct",
				function()
					require("tasks.cmake").test()
				end,
				desc = "CMake: Test",
			},
			{
				"<leader>Cr",
				function()
					require("tasks.cmake").launch()
				end,
				desc = "CMake: Launch target",
			},
		},
		config = function(_, opts)
			require("overseer").setup(opts)
			require("tasks").setup({})
		end,
	},
}
