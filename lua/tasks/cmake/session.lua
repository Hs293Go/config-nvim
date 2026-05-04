-- Per-project memory of the user's last picks (configure preset, build preset,
-- launch target). Persisted to `<sourceDir>/.cache/cmake_tasks.json`.

local M = {}

---@class CMakeContext
---@field configure_preset? string
---@field build_preset? string
---@field test_preset? string
---@field launch_target? string

---@param source_dir string
---@return string
local function session_path(source_dir)
	local cache = vim.fs.joinpath(source_dir, ".cache")
	if vim.fn.isdirectory(cache) == 0 then
		vim.fn.mkdir(cache, "p")
	end
	return vim.fs.joinpath(cache, "cmake_tasks.json")
end

---@param source_dir string
---@return CMakeContext
function M.load(source_dir)
	local path = session_path(source_dir)
	if vim.fn.filereadable(path) == 0 then
		return {}
	end
	local lines = vim.fn.readfile(path)
	local ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
	if not ok or type(decoded) ~= "table" then
		return {}
	end
	return decoded
end

---@param source_dir string
---@param ctx CMakeContext
function M.save(source_dir, ctx)
	local path = session_path(source_dir)
	local f = io.open(path, "w")
	if not f then
		return
	end
	f:write(vim.json.encode({
		configure_preset = ctx.configure_preset,
		build_preset = ctx.build_preset,
		test_preset = ctx.test_preset,
		launch_target = ctx.launch_target,
	}))
	f:close()
end

return M
