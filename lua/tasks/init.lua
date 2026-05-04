-- Public entry point for the bespoke task orchestration. Each domain
-- (cmake, just, cargo, uv) is a sibling module under `tasks.*` and registers
-- itself via `setup()`. Call `require("tasks").setup({})` once from the
-- overseer plugin spec.

local M = {}

---@class TasksOpts
---@field cmake? CMakeTasksOpts

---@param opts? TasksOpts
function M.setup(opts)
	opts = opts or {}
	require("tasks.cmake").setup(opts.cmake)
	require("tasks.just").setup()
	require("tasks.cargo").setup()
	require("tasks.uv").setup()
end

return M
