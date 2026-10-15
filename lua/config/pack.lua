-- Helpers for the built-in `vim.pack` plugin manager (Neovim 0.12).

local M = {}

---@param repo string "owner/name"
---@return string
function M.gh(repo)
	return "https://github.com/" .. repo
end

--- Add plugins. Do not ask for confirmation before the first install.
---@param specs (string|vim.pack.Spec)[]
function M.add(specs)
	vim.pack.add(specs, { confirm = false })
end

--- Set keymaps from a list of entries:
---   { lhs, rhs, mode = "n"|{...}, desc = "...", ft = "x"|{...} }
--- An entry with `ft` is buffer-local to buffers of that filetype.
---@param keys table[]
function M.map(keys)
	for _, k in ipairs(keys) do
		if k.ft then
			-- Snacks.keymap.set also sets the map in buffers that are already open.
			Snacks.keymap.set(k.mode or "n", k[1], k[2], { desc = k.desc, ft = k.ft })
		else
			vim.keymap.set(k.mode or "n", k[1], k[2], { desc = k.desc })
		end
	end
end

-- Build steps. Register this autocmd before the first `vim.pack.add` call.
-- The first call installs all plugins in nvim-pack-lock.json.
local build = {
	["nvim-treesitter"] = function(kind)
		-- On install, `ensure_installed` (plugins/ts.lua) compiles the parsers.
		-- Do not run :TSUpdate at the same time.
		if kind == "update" then
			vim.cmd("TSUpdate")
		end
	end,
	["markdown-preview.nvim"] = function()
		-- Download the prebuilt server binary. This step does not need node.
		vim.fn["mkdp#util#install"]()
	end,
}

vim.api.nvim_create_autocmd("PackChanged", {
	group = vim.api.nvim_create_augroup("user_pack_build", { clear = true }),
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		local hook = build[name]
		if not hook or (kind ~= "install" and kind ~= "update") then
			return
		end
		-- The "install" event occurs before the plugin loads. Load it now.
		vim.cmd.packadd(name)
		-- Run the hook after the current `vim.pack.add` call completes.
		vim.schedule(function()
			local ok, err = pcall(hook, kind)
			if not ok then
				vim.notify(("Build hook for %s failed: %s"):format(name, err), vim.log.levels.ERROR)
			end
		end)
	end,
})

vim.api.nvim_create_user_command("PackUpdate", function(cmd)
	vim.pack.update(#cmd.fargs > 0 and cmd.fargs or nil)
end, {
	nargs = "*",
	desc = "Update all plugins, or the named plugins",
	complete = function()
		return vim.tbl_map(function(p)
			return p.spec.name
		end, vim.pack.get(nil, { info = false }))
	end,
})

vim.api.nvim_create_user_command("PackClean", function()
	local stale = vim.iter(vim.pack.get(nil, { info = false }))
		:filter(function(p)
			return not p.active
		end)
		:map(function(p)
			return p.spec.name
		end)
		:totable()
	if #stale == 0 then
		vim.notify("No unused plugins")
		return
	end
	vim.pack.del(stale)
end, { desc = "Delete installed plugins that this config does not add" })

return M
