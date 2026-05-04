-- cargo subcommand templates. Static set: build / run / test / clippy / check.
-- Templates appear in `:OverseerRun` only when `Cargo.toml` is in cwd.

local M = {}

local function has_cargo_toml()
	return vim.fn.filereadable("Cargo.toml") == 1
end

---@param subcommand string
---@param extra? string[] additional argv after the subcommand
local function template(subcommand, extra)
	return {
		name = "cargo: " .. subcommand,
		condition = { callback = has_cargo_toml },
		builder = function()
			local cmd = { "cargo", subcommand }
			for _, a in ipairs(extra or {}) do
				table.insert(cmd, a)
			end
			return {
				cmd = cmd,
				cwd = vim.uv.cwd(),
				components = { "default", { "open_output", focus = false } },
			}
		end,
	}
end

function M.setup()
	local overseer = require("overseer")
	overseer.register_template(template("build"))
	overseer.register_template(template("run"))
	overseer.register_template(template("test"))
	overseer.register_template(template("clippy"))
	overseer.register_template(template("check"))
end

return M
