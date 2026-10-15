-- Minimal init for headless test runs.
-- Usage:
--   nvim --headless --noplugin -u tests/minimal_init.lua \
--     -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
--
-- We DON'T load the full config: no vim.pack, no plugins, no autocmds.
-- This file is the entire runtime — only what's needed to make
-- `require("tasks.cmake.*")` resolve and to load plenary's busted runner.

local function abspath(p)
	return vim.fn.fnamemodify(p, ":p")
end

-- The test runner is invoked from the nvim config root, so cwd is the rtp.
local config_root = abspath(".")
vim.opt.rtp:append(config_root)

-- vim.pack installs plenary in its plugin directory.
local plenary_root = vim.fn.stdpath("data") .. "/site/pack/core/opt/plenary.nvim"
if vim.fn.isdirectory(plenary_root) == 0 then
	error("plenary.nvim not found at " .. plenary_root .. ". Start nvim one time to install it.")
end
vim.opt.rtp:append(plenary_root)

vim.cmd("runtime plugin/plenary.vim")
