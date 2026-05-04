-- just-runner: pick a recipe from `just --list`, run via overseer.
-- Recipes are dynamic, so this isn't a registered template — it's a direct
-- keymap callback. `:OverseerRun` won't show just recipes; press `<leader>Jr`.

local M = {}

local function has_justfile()
	return vim.fn.filereadable("justfile") == 1
		or vim.fn.filereadable("Justfile") == 1
		or vim.fn.filereadable(".justfile") == 1
end

---Parse `just --list` output into a list of recipe names.
---Output format (typical):
---
---     Available recipes:
---         build args=""    # Build the project
---         test
---         deploy host="localhost"
---
---@param output string
---@return string[]
function M.parse_recipes(output)
	local recipes = {}
	for line in output:gmatch("[^\n]+") do
		-- Recipe lines are indented; the header `Available recipes:` is not.
		local body = line:match("^%s+(.+)$")
		if body and not body:match("^#") then
			-- First identifier token is the recipe name; trailing args/comments ignored.
			local name = body:match("^([%w_-]+)")
			if name then
				table.insert(recipes, name)
			end
		end
	end
	return recipes
end

---@return string[]?
local function list_recipes()
	local result = vim.system({ "just", "--list", "--unsorted" }, { text = true }):wait()
	if result.code ~= 0 then
		vim.notify("just --list failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
		return nil
	end
	return M.parse_recipes(result.stdout or "")
end

---Pick a recipe via vim.ui.select and run via overseer.
function M.pick_and_run()
	if not has_justfile() then
		vim.notify("No justfile in cwd", vim.log.levels.WARN)
		return
	end
	local recipes = list_recipes()
	if not recipes or #recipes == 0 then
		vim.notify("No recipes found", vim.log.levels.WARN)
		return
	end
	vim.ui.select(recipes, { prompt = "just recipe:" }, function(picked)
		if not picked then
			return
		end
		local overseer = require("overseer")
		overseer
			.new_task({
				name = "just: " .. picked,
				cmd = { "just", picked },
				cwd = vim.uv.cwd(),
				components = { "default", { "open_output", focus = false } },
			})
			:start()
	end)
end

function M.setup() end

return M
