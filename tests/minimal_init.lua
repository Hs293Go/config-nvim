-- Minimal init for headless test runs.
-- Usage:
--   nvim --headless --noplugin -u tests/minimal_init.lua \
--     -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
--
-- We DON'T load the full config: no lazy.nvim, no plugins, no autocmds.
-- This file is the entire runtime — only what's needed to make
-- `require("tasks.cmake.*")` resolve and to load plenary's busted runner.

local function abspath(p)
	return vim.fn.fnamemodify(p, ":p")
end

-- The test runner is invoked from the nvim config root, so cwd is the rtp.
local config_root = abspath(".")
vim.opt.rtp:append(config_root)

-- plenary lives under lazy.nvim's data dir (installed transitively via
-- todo-comments.nvim). Fall back to LSP search for portability.
local plenary_candidates = {
	vim.fn.stdpath("data") .. "/lazy/plenary.nvim",
	vim.fn.stdpath("data") .. "/site/pack/vendor/start/plenary.nvim",
}
local plenary_root
for _, p in ipairs(plenary_candidates) do
	if vim.fn.isdirectory(p) == 1 then
		plenary_root = p
		break
	end
end
if not plenary_root then
	error("plenary.nvim not found. Install it via lazy first:\n  " .. table.concat(plenary_candidates, "\n  "))
end
vim.opt.rtp:append(plenary_root)

vim.cmd("runtime plugin/plenary.vim")
