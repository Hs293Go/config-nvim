return {
	{
		"ibhagwan/fzf-lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		cmd = "FzfLua",
		keys = {
			-- Files & buffers
			{
				"<leader>ff",
				function()
					require("fzf-lua").files()
				end,
				desc = "Find Files",
			},
			{
				"<leader>fg",
				function()
					require("fzf-lua").git_files()
				end,
				desc = "Find Files (Git)",
			},
			{
				"<leader>fr",
				function()
					require("fzf-lua").oldfiles()
				end,
				desc = "Recent",
			},
			{
				"<leader>fb",
				function()
					require("fzf-lua").buffers()
				end,
				desc = "Buffers",
			},

			-- Grep
			{
				"<leader>sg",
				function()
					require("fzf-lua").live_grep()
				end,
				desc = "Grep",
			},
			{
				"<leader>fw",
				function()
					require("fzf-lua").grep_cword()
				end,
				desc = "Word under cursor",
			},
			{
				"<leader>fw",
				function()
					require("fzf-lua").grep_visual()
				end,
				desc = "Grep selection",
				mode = "v",
			},

			-- Vim internals
			{
				"<leader>fh",
				function()
					require("fzf-lua").help_tags()
				end,
				desc = "Help",
			},
			{
				"<leader>fk",
				function()
					require("fzf-lua").keymaps()
				end,
				desc = "Keymaps",
			},
			{
				"<leader>fc",
				function()
					require("fzf-lua").commands()
				end,
				desc = "Commands",
			},
			{
				"<leader>f:",
				function()
					require("fzf-lua").command_history()
				end,
				desc = "Command History",
			},
			{
				"<leader>f/",
				function()
					require("fzf-lua").search_history()
				end,
				desc = "Search History",
			},
			{
				"<leader>fR",
				function()
					require("fzf-lua").resume()
				end,
				desc = "Resume Picker",
			},
			{
				"<leader>fi",
				function()
					local fzf = require("fzf-lua")
					fzf.files({
						prompt = "Insert Path> ",
						actions = {
							["default"] = function(selected)
								local lines = {}
								for _, path in ipairs(selected) do
									local entry = fzf.path.entry_to_file(path)
									local rel = vim.fn.fnamemodify(entry.path, ":.")
									table.insert(lines, " " .. rel)
								end
								vim.api.nvim_put(lines, "c", true, true)
							end,
						},
					})
				end,
				desc = "Insert file path(s) at cursor",
			},

			-- Diagnostics & LSP
			{
				"<leader>fd",
				function()
					require("fzf-lua").diagnostics_document()
				end,
				desc = "Diagnostics (buffer)",
			},
			{
				"<leader>fD",
				function()
					require("fzf-lua").diagnostics_workspace()
				end,
				desc = "Diagnostics (workspace)",
			},
			{
				"<leader>fs",
				function()
					require("fzf-lua").lsp_document_symbols()
				end,
				desc = "Symbols (buffer)",
			},
			{
				"<leader>fS",
				function()
					require("fzf-lua").lsp_live_workspace_symbols()
				end,
				desc = "Symbols (workspace)",
			},

			-- Goto-style LSP
			{
				"gd",
				function()
					require("fzf-lua").lsp_definitions({ jump1 = true })
				end,
				desc = "Goto Definition",
			},
			{
				"gr",
				function()
					require("fzf-lua").lsp_references({ jump1 = false })
				end,
				desc = "References",
			},
			{
				"gI",
				function()
					require("fzf-lua").lsp_implementations({ jump1 = true })
				end,
				desc = "Goto Implementation",
			},
			{
				"gy",
				function()
					require("fzf-lua").lsp_typedefs({ jump1 = true })
				end,
				desc = "Goto Type Definition",
			},

			-- Git
			{
				"<leader>gc",
				function()
					require("fzf-lua").git_commits()
				end,
				desc = "Git Commits",
			},
			{
				"<leader>gs",
				function()
					require("fzf-lua").git_status()
				end,
				desc = "Git Status",
			},
			{
				"<leader>gb",
				function()
					require("fzf-lua").git_branches()
				end,
				desc = "Git Branches",
			},
		},
		opts = {
			"default-title",
			winopts = {
				height = 0.85,
				width = 0.80,
				row = 0.35,
				col = 0.50,
				border = "rounded",
				backdrop = 60,
				preview = {
					border = "rounded",
					wrap = false,
					hidden = false,
					vertical = "down:45%",
					horizontal = "right:50%",
					layout = "flex",
					flip_columns = 120,
					scrollbar = "float",
				},
			},
			fzf_colors = true,
			fzf_opts = { ["--no-scrollbar"] = true },
			defaults = { formatter = "path.filename_first" },
		},
		config = function(_, opts)
			local fzf = require("fzf-lua")
			fzf.setup(opts)
			-- Route vim.ui.select through fzf-lua so all `vim.ui.select`
			-- callers (overseer params, our cmake pickers, etc.) get the
			-- same look. Safe to call repeatedly.
			fzf.register_ui_select()
		end,
	},
	{
		"stevearc/oil.nvim",
		dependencies = { "ibhagwan/fzf-lua" },
		lazy = false,
		keys = {
			{
				"<leader>oo",
				function()
					require("oil").open_float()
				end,
				desc = "Open Oil (floating window)",
			},
			{
				"<leader>oO",
				function()
					require("oil").open()
				end,
				desc = "Open Oil (full window)",
			},
			{
				"<leader>ov",
				function()
					local oil = require("oil")

					-- Ensure we have a right-hand vertical split
					if #vim.api.nvim_tabpage_list_wins(0) == 1 then
						vim.cmd("vsplit")
					end

					-- Move to the rightmost window
					vim.cmd("wincmd l")

					-- Open Oil in this window
					oil.open(vim.fn.getcwd())
				end,
				desc = "Open Oil (vsplit)",
			},
			{
				"<leader>of",
				function()
					require("fzf-lua").files({
						cmd = "fd --type d --hidden --follow --exclude .git",
						prompt = "Open Oil in: ",
						actions = {
							["default"] = function(selected)
								if not selected or not selected[1] then
									return
								end
								local entry = require("fzf-lua").path.entry_to_file(selected[1])
								require("oil").open_float(vim.fn.fnamemodify(entry.path, ":p"))
							end,
						},
					})
				end,
				desc = "Open Oil (pretty picker)",
			},
		},
		opts = {
			-- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
			-- Set to false if you want some other plugin (e.g. netrw) to open when you edit directories.
			default_file_explorer = true,
			-- Id is automatically added at the beginning, and name at the end
			-- See :help oil-columns
			columns = {
				"icon",
				-- "permissions",
				-- "size",
				-- "mtime",
			},
			-- Buffer-local options to use for oil buffers
			buf_options = {
				buflisted = false,
				bufhidden = "hide",
			},
			-- Window-local options to use for oil buffers
			win_options = {
				wrap = false,
				signcolumn = "no",
				cursorcolumn = false,
				foldcolumn = "0",
				spell = false,
				list = false,
				conceallevel = 3,
				concealcursor = "nvic",
			},
			-- Send deleted files to the trash instead of permanently deleting them (:help oil-trash)
			delete_to_trash = false,
			-- Skip the confirmation popup for simple operations (:help oil.skip_confirm_for_simple_edits)
			skip_confirm_for_simple_edits = false,
			-- Selecting a new/moved/renamed file or directory will prompt you to save changes first
			-- (:help prompt_save_on_select_new_entry)
			prompt_save_on_select_new_entry = true,
			-- Oil will automatically delete hidden buffers after this delay
			-- You can set the delay to false to disable cleanup entirely
			-- Note that the cleanup process only starts when none of the oil buffers are currently displayed
			cleanup_delay_ms = 2000,
			lsp_file_methods = {
				-- Enable or disable LSP file operations
				enabled = true,
				-- Time to wait for LSP file operations to complete before skipping
				timeout_ms = 1000,
				-- Set to true to autosave buffers that are updated with LSP willRenameFiles
				-- Set to "unmodified" to only save unmodified buffers
				autosave_changes = false,
			},
			-- Constrain the cursor to the editable parts of the oil buffer
			-- Set to `false` to disable, or "name" to keep it on the file names
			constrain_cursor = "editable",
			-- Set to true to watch the filesystem for changes and reload oil
			watch_for_changes = false,
			-- Keymaps in oil buffer. Can be any value that `vim.keymap.set` accepts OR a table of keymap
			-- options with a `callback` (e.g. { callback = function() ... end, desc = "", mode = "n" })
			-- Additionally, if it is a string that matches "actions.<name>",
			-- it will use the mapping at require("oil.actions").<name>
			-- Set to `false` to remove a keymap
			-- See :help oil-actions for a list of all available actions
			keymaps = {
				["g?"] = { "actions.show_help", mode = "n" },
				["<CR>"] = "actions.select",
				["<C-h>"] = false,
				["<leader>s"] = { "actions.select", opts = { vertical = true } },
				["<leader>v"] = { "actions.select", opts = { horizontal = true } },
				["<C-t>"] = { "actions.select", opts = { tab = true } },
				["<C-p>"] = "actions.preview",
				["q"] = { "actions.close", mode = "n" },
				["<C-l>"] = "actions.refresh",
				["<backspace>"] = { "actions.parent", mode = "n" },
				["_"] = { "actions.open_cwd", mode = "n" },
				["`"] = { "actions.cd", mode = "n" },
				["g~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
				["gs"] = { "actions.change_sort", mode = "n" },
				["gx"] = "actions.open_external",
				["g."] = { "actions.toggle_hidden", mode = "n" },
				["g\\"] = { "actions.toggle_trash", mode = "n" },
			},
			-- Set to false to disable all of the above keymaps
			use_default_keymaps = true,
			view_options = {
				-- Show files and directories that start with "."
				show_hidden = true,
				-- This function defines what is considered a "hidden" file
				is_hidden_file = function(name, bufnr)
					local m = name:match("^%.")
					return m ~= nil
				end,
				-- This function defines what will never be shown, even when `show_hidden` is set
				is_always_hidden = function(name, bufnr)
					return false
				end,
				-- Sort file names with numbers in a more intuitive order for humans.
				-- Can be "fast", true, or false. "fast" will turn it off for large directories.
				natural_order = "fast",
				-- Sort file and directory names case insensitive
				case_insensitive = false,
				sort = {
					-- sort order can be "asc" or "desc"
					-- see :help oil-columns to see which columns are sortable
					{ "type", "asc" },
					{ "name", "asc" },
				},
				-- Customize the highlight group for the file name
				highlight_filename = function(entry, is_hidden, is_link_target, is_link_orphan)
					return nil
				end,
			},
			-- Extra arguments to pass to SCP when moving/copying files over SSH
			extra_scp_args = {},
			-- Extra arguments to pass to aws s3 when creating/deleting/moving/copying files using aws s3
			extra_s3_args = {},
			-- EXPERIMENTAL support for performing file operations with git
			git = {
				-- Return true to automatically git add/mv/rm files
				add = function(path)
					return false
				end,
				mv = function(src_path, dest_path)
					return false
				end,
				rm = function(path)
					return false
				end,
			},
			-- Configuration for the floating window in oil.open_float
			float = {
				-- Padding around the floating window
				padding = 5,
				border = "rounded",
			},
			-- Configuration for the file preview window
			preview_win = {
				-- Whether the preview window is automatically updated when the cursor is moved
				update_on_cursor_moved = true,
				-- How to open the preview window "load"|"scratch"|"fast_scratch"
				preview_method = "fast_scratch",
				-- A function that returns true to disable preview on a file e.g. to avoid lag
				disable_preview = function(filename)
					return false
				end,
				-- Window-local options to use for preview window buffers
				win_options = {},
				border = "rounded",
			},
			-- Configuration for the floating action confirmation window
			confirmation = {
				-- Width dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
				-- min_width and max_width can be a single value or a list of mixed integer/float types.
				-- max_width = {100, 0.8} means "the lesser of 100 columns or 80% of total"
				max_width = 0.9,
				-- min_width = {40, 0.4} means "the greater of 40 columns or 40% of total"
				min_width = { 40, 0.4 },
				-- optionally define an integer/float for the exact width of the preview window
				width = nil,
				-- Height dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
				-- min_height and max_height can be a single value or a list of mixed integer/float types.
				-- max_height = {80, 0.9} means "the lesser of 80 columns or 90% of total"
				max_height = 0.9,
				-- min_height = {5, 0.1} means "the greater of 5 columns or 10% of total"
				min_height = { 5, 0.1 },
				-- optionally define an integer/float for the exact height of the preview window
				height = nil,
				border = "rounded",
			},
			-- Configuration for the floating progress window
			progress = {
				max_width = 0.9,
				min_width = { 40, 0.4 },
				width = nil,
				max_height = { 10, 0.9 },
				min_height = { 5, 0.1 },
				height = nil,
				border = nil,
				minimized_border = "none",
				win_options = {
					winblend = 0,
				},
			},
			-- Configuration for the floating SSH window
			ssh = {
				border = nil,
			},
			-- Configuration for the floating keymaps help window
			keymaps_help = {
				border = nil,
			},
		},
	},
	{ -- Counts as navigation since it provides quick jumping to important comments in the code
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		event = { "BufReadPost", "BufNewFile" },
		opts = {},
		cmd = { "TodoTrouble", "TodoFzfLua" },
		keys = {
			{
				"]t",
				function()
					require("todo-comments").jump_next()
				end,
				desc = "Next todo comment",
			},
			{
				"[t",
				function()
					require("todo-comments").jump_prev()
				end,
				desc = "Previous todo comment",
			},
			{ "<leader>ft", "<cmd>TodoFzfLua<cr>", desc = "Find todo comments" },
		},
	},
}
