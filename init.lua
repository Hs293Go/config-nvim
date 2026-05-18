-- LEADERS
-- =======
-- Must be set before any `<leader>` mapping is defined; otherwise `<leader>`
-- expands to the default backslash.

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- OPTIONS
-- =======

vim.opt.compatible = false -- disable compatibility to old-time vi
vim.opt.showmatch = true -- show matching
vim.opt.ignorecase = true -- case insensitive
vim.opt.hlsearch = true -- highlight search

vim.opt.wildmenu = true
vim.opt.wildmode = { "longest:full", "full" }
vim.opt.wildignorecase = true

vim.opt.signcolumn = "yes"
vim.opt.relativenumber = false
vim.opt.number = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.cursorline = true
vim.opt.swapfile = false
vim.opt.foldenable = true
vim.opt.foldcolumn = "1" -- '0' is not bad
vim.opt.foldlevel = 99 -- start with everything unfolded
vim.opt.foldlevelstart = 99
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldtext = ""
vim.opt.fillchars = "foldclose:▸,foldopen:▾"
vim.opt.termguicolors = true -- you want this for any modern colorscheme
vim.opt.scrolloff = 8 -- keep cursor away from the edge
vim.opt.undofile = true -- persistent undo across sessions
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Trim message noise that triggers the hit-enter prompt
vim.opt.shortmess:append("aoOtTIcCWF")

-- LazyVim-style behavioral defaults
vim.opt.autoread = true
vim.opt.autowrite = true
vim.opt.confirm = true
vim.opt.smartcase = true
vim.opt.inccommand = "nosplit"
vim.opt.grepprg = "rg --vimgrep"
vim.opt.grepformat = "%f:%l:%c:%m"
vim.opt.smartindent = true
vim.opt.shiftround = true
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.formatoptions = "jcroqlnt"
vim.opt.laststatus = 3
vim.opt.winminwidth = 5
vim.opt.sidescrolloff = 8
vim.opt.virtualedit = "block"
vim.opt.timeoutlen = 300
vim.opt.updatetime = 200
vim.opt.wrap = false
vim.opt.breakindent = true
vim.opt.linebreak = true
vim.opt.pumheight = 10
vim.opt.pumblend = 10

-- KEYMAPS
-- =======

vim.api.nvim_set_keymap("n", ";", ":", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", ";", ":", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "::", ";", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "::", ";", { noremap = true, silent = true })

vim.keymap.set("n", "[<tab>", ":tabprevious<CR>", { noremap = true, silent = true, desc = "Previous tab" })
vim.keymap.set("n", "]<tab>", ":tabnext<CR>", { noremap = true, silent = true, desc = "Next tab" })

vim.keymap.set("n", "<leader>m", ":messages<CR>", { noremap = true, silent = true, desc = "Show messages" })
vim.keymap.set("n", "<leader>w", ":w<CR>", { noremap = true, silent = true, desc = "Write" })
vim.keymap.set("n", "<leader>W", ":wa<CR>", { noremap = true, silent = true, desc = "Write all" })
vim.keymap.set("n", "<leader>Q", ":qa<CR>", { noremap = true, silent = true, desc = "Quit all" })

vim.keymap.set({ "n", "v" }, "<leader>ii", ":Inspect<CR>", { noremap = true, silent = true, desc = "inspect" })

vim.keymap.set("n", "]e", function()
	vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
end, {
	desc = "Next error",
})

vim.keymap.set("n", "[e", function()
	vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
end, {
	desc = "Prev error",
})

vim.keymap.set("n", "]w", function()
	vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.WARN })
end, {
	desc = "Next warning",
})

vim.keymap.set("n", "[w", function()
	vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.WARN })
end, {
	desc = "Prev warning",
})

-- Close the current window or tab without ever quitting Neovim, and refuse if
-- it would leave the session with only side-panels (terminals, oil, trouble,
-- task lists…). A "file window" is any window whose buffer has empty buftype.
local function is_file_window(win)
	local buf = vim.api.nvim_win_get_buf(win)
	return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == ""
end

vim.keymap.set("n", "<leader>wq", function()
	local cur = vim.api.nvim_get_current_win()
	local file_wins_after = 0
	for _, w in ipairs(vim.api.nvim_list_wins()) do
		if w ~= cur and is_file_window(w) then
			file_wins_after = file_wins_after + 1
		end
	end
	if file_wins_after < 1 then
		vim.notify("Refusing — no other file-editing window would remain", vim.log.levels.WARN)
		return
	end
	if #vim.api.nvim_tabpage_list_wins(0) > 1 then
		vim.cmd("close")
	elseif #vim.api.nvim_list_tabpages() > 1 then
		vim.cmd("tabclose")
	else
		vim.notify("Last window — refusing to quit Neovim", vim.log.levels.WARN)
	end
end, { silent = true, desc = "Close window/tab (never Neovim)" })

-- Disable bare q (start-macro) and Q (rerun-last-macro): they conflict with our
-- quit/close conventions
vim.keymap.set("n", "q", "<nop>", { desc = "Disabled — use <leader>Mr to record" })
vim.keymap.set("n", "Q", "<nop>", { desc = "Disabled — use <leader>Mp to play" })
-- Recording is still available via <leader>M*; pressing q while recording still
-- stops the recording (Neovim handles that before mapping lookup).
vim.keymap.set("n", "<leader>Mr", "q", { desc = "Record macro (then register, then q to stop)" })
vim.keymap.set("n", "<leader>Mp", "@", { desc = "Play macro from register" })

for _, m in ipairs({ "h", "j", "k", "l" }) do
	-- Pressing Ctrl+motion navigates windows, including from terminal panes
	vim.keymap.set({ "n", "x", "t" }, "<C-" .. m .. ">", "<cmd>wincmd " .. m .. "<cr>", { silent = true })
end

vim.keymap.set("n", "<Esc>", "<cmd>noh<cr>", { silent = true, desc = "Clear search highlight" })

-- VS Code-style comment toggle (Neovim 0.10+ has built-in `gcc`/`gc`).
vim.keymap.set("n", "<C-/>", "gcc", { remap = true, desc = "Toggle line comment" })
vim.keymap.set("v", "<C-/>", "gc", { remap = true, desc = "Toggle comment selection" })

-- Open a directory in the OS file manager (xdg-open / open / explorer).
local function open_directory(dir)
	local cmd
	if vim.fn.has("mac") == 1 then
		cmd = { "open", dir }
	elseif vim.fn.has("win32") == 1 then
		cmd = { "explorer", dir }
	else
		cmd = { "xdg-open", dir }
	end
	vim.fn.jobstart(cmd, { detach = true })
end
vim.keymap.set("n", "<leader>e", function()
	open_directory(vim.fn.expand("%:p:h"))
end, { desc = "Open in explorer (file parent)" })
vim.keymap.set("n", "<leader>E", function()
	open_directory(vim.fn.getcwd())
end, { desc = "Open in explorer (cwd)" })

-- AUTOCMDS
-- ========

vim.filetype.add({
	extension = {
		tsx = "typescriptreact",
	},
})

local lang_settings = {
	two_spaces = { "c", "cpp", "cuda", "json", "yaml", "xml", "nix", "toml", "cmake", "markdown" },
	four_spaces = { "python", "lua", "bash", "sh", "rust", "tex" },
}

local function set_tab_width(width)
	return function()
		vim.opt_local.tabstop = width
		vim.opt_local.shiftwidth = width
		vim.opt_local.softtabstop = width
		vim.opt_local.expandtab = true
	end
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = lang_settings.two_spaces,
	callback = set_tab_width(2),
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = lang_settings.four_spaces,
	callback = set_tab_width(4),
})

-- markdown: turn off conceal so raw syntax stays visible while editing
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt_local.conceallevel = 0
	end,
})

-- python: black-style 88-col width; stop auto-wrapping text/comments
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	callback = function()
		vim.opt_local.textwidth = 88
		vim.opt_local.formatoptions:remove({ "t", "c" })
	end,
})

-- rust: rustfmt-style 100-col width; stop auto-wrapping text/comments
vim.api.nvim_create_autocmd("FileType", {
	pattern = "rust",
	callback = function()
		vim.opt_local.textwidth = 100
		vim.opt_local.formatoptions:remove({ "t", "c" })
	end,
})

-- Block the global `;` -> `:` remap inside snacks terminal buffers
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "snacks_terminal" },
	callback = function(ev)
		local warn = function()
			vim.notify("Do not attempt to use ':' in the terminal buffer.")
		end
		vim.keymap.set("n", ";", warn, { buffer = ev.buf })
		vim.keymap.set("n", ":", warn, { buffer = ev.buf })
	end,
})

-- Lazygit binds <C-j>/<C-k> to move commits in interactive rebase (and uses
-- <C-h>/<C-l> for panel navigation), so the global terminal-mode <C-hjkl>
-- window-nav mappings would steal those keys. Restore them as buffer-local
-- pass-throughs when the snacks terminal is running lazygit.
vim.api.nvim_create_autocmd("TermOpen", {
	callback = function(args)
		local term = vim.b[args.buf].snacks_terminal
		if not (term and term.cmd and term.cmd[1] == "lazygit") then
			return
		end
		for _, m in ipairs({ "h", "j", "k", "l" }) do
			vim.keymap.set("t", "<C-" .. m .. ">", "<C-" .. m .. ">", { buffer = args.buf })
		end
	end,
})

local function augroup(name)
	return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- Reload the buffer when the file changes externally
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	group = augroup("checktime"),
	callback = function()
		if vim.o.buftype ~= "nofile" then
			vim.cmd("checktime")
		end
	end,
})

-- Briefly highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup("highlight_yank"),
	callback = function()
		(vim.hl or vim.highlight).on_yank()
	end,
})

-- Equalize splits when the host window is resized
vim.api.nvim_create_autocmd("VimResized", {
	group = augroup("resize_splits"),
	callback = function()
		local current_tab = vim.fn.tabpagenr()
		vim.cmd("tabdo wincmd =")
		vim.cmd("tabnext " .. current_tab)
	end,
})

-- Restore cursor position when a file is reopened
vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup("last_loc"),
	callback = function(event)
		local buf = event.buf
		if vim.bo[buf].filetype == "gitcommit" or vim.b[buf].last_loc_set then
			return
		end
		vim.b[buf].last_loc_set = true
		local mark = vim.api.nvim_buf_get_mark(buf, '"')
		local lcount = vim.api.nvim_buf_line_count(buf)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Create missing parent directories on save
vim.api.nvim_create_autocmd("BufWritePre", {
	group = augroup("auto_create_dir"),
	callback = function(event)
		if event.match:match("^%w%w+:[\\/][\\/]") then
			return
		end
		local file = vim.uv.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})

-- Quit read-only / scratch panels with `q`
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("close_with_q"),
	pattern = {
		"checkhealth",
		"fugitive",
		"gitsigns-blame",
		"help",
		"lspinfo",
		"qf",
		"startuptime",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.schedule(function()
			vim.keymap.set("n", "q", function()
				vim.cmd("close")
				pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
			end, { buffer = event.buf, silent = true, desc = "Quit buffer" })
		end)
	end,
})

-- FRAMEWORKS
-- ==========

-- Mini-mason: registers :ToolInstall / :ToolList user commands and prepends
-- .tools/npm/node_modules/.bin to PATH so conform / nvim-lint find locally-
-- installed CLI tools (markdownlint, taplo, prettier) by name. Required
-- before lazy bootstrap so the PATH side effect is in place when plugins
-- with eager events (BufReadPost / BufWritePre) start resolving binaries.
require("config.tools")

require("config.lazy")
