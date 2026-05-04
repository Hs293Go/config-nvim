-- uv subcommand templates. `sync` is parameterless; `run` and `add` prompt
-- for arguments via overseer's params mechanism (which routes through
-- vim.ui.select / vim.ui.input — fzf-lua picks those up).

local M = {}

local function has_pyproject()
	return vim.fn.filereadable("pyproject.toml") == 1
end

local function default_components()
	return { "default", { "open_output", focus = false } }
end

function M.setup()
	local overseer = require("overseer")

	overseer.register_template({
		name = "uv: sync",
		condition = { callback = has_pyproject },
		builder = function()
			return {
				cmd = { "uv", "sync" },
				cwd = vim.uv.cwd(),
				components = default_components(),
			}
		end,
	})

	overseer.register_template({
		name = "uv: run",
		condition = { callback = has_pyproject },
		params = {
			command = {
				type = "string",
				desc = "Command to run with uv (e.g. 'pytest tests/')",
			},
		},
		builder = function(params)
			local args = vim.split(params.command or "", "%s+", { trimempty = true })
			local cmd = { "uv", "run" }
			for _, a in ipairs(args) do
				table.insert(cmd, a)
			end
			return {
				cmd = cmd,
				cwd = vim.uv.cwd(),
				components = default_components(),
			}
		end,
	})

	overseer.register_template({
		name = "uv: add",
		condition = { callback = has_pyproject },
		params = {
			package = {
				type = "string",
				desc = "Package spec (e.g. 'numpy>=1.20')",
			},
		},
		builder = function(params)
			return {
				cmd = { "uv", "add", params.package },
				cwd = vim.uv.cwd(),
				components = default_components(),
			}
		end,
	})
end

return M
