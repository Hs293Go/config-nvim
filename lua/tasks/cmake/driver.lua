-- Pure command + File API helpers. No state, no UI, no overseer awareness.
-- Returns task specs (cmd arrays) and parsed File API data; callers decide
-- how/where to execute and notify.

local M = {}

---@class CMakeTarget
---@field name string
---@field type string  EXECUTABLE | UTILITY | STATIC_LIBRARY | SHARED_LIBRARY | ...
---@field artifacts? { path: string }[]

---@param preset string
---@return string[]
function M.configure_cmd(preset)
	return { "cmake", "--preset", preset, "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" }
end

---@param preset string
---@return string[]
function M.build_cmd(preset)
	return { "cmake", "--build", "--preset", preset }
end

---@param preset string
---@return string[]
function M.test_cmd(preset)
	return { "ctest", "--preset", preset, "--output-on-failure" }
end

---Place an empty `codemodel-v2` query file so cmake emits the reply on next
---configure. Idempotent.
---@param binary_dir string
function M.write_query_file(binary_dir)
	local query_dir = vim.fs.joinpath(binary_dir, ".cmake/api/v1/query")
	if vim.fn.isdirectory(query_dir) == 0 then
		vim.fn.mkdir(query_dir, "p")
	end
	local query_file = vim.fs.joinpath(query_dir, "codemodel-v2")
	if vim.fn.filereadable(query_file) == 0 then
		local f = io.open(query_file, "w")
		if f then
			f:close()
		end
	end
end

---@param path string
---@return any?, string?
local function read_json(path)
	if vim.fn.filereadable(path) == 0 then
		return nil, "cannot read " .. path
	end
	local lines = vim.fn.readfile(path)
	local ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
	if not ok then
		return nil, "invalid JSON in " .. path
	end
	return decoded
end

---Read all entries under `dir` (basenames only). Returns empty list if `dir`
---doesn't exist. We scan once and filter in memory rather than calling
---`vim.fn.glob` per pattern: simpler, no wildignore interaction, and one
---scan beats N globs for typical CMake reply dirs.
---@param dir string
---@return string[]
local function list_entries(dir)
	if vim.fn.isdirectory(dir) == 0 then
		return {}
	end
	local entries = vim.fn.readdir(dir)
	return type(entries) == "table" and entries or {}
end

---@param entries string[]
---@param lua_pattern string
---@return string?
local function match_first(entries, lua_pattern)
	for _, name in ipairs(entries) do
		if name:match(lua_pattern) then
			return name
		end
	end
end

---List targets from the File API reply. Configure must have run with the
---codemodel-v2 query file present.
---@param binary_dir string
---@param configuration? string  filter to a specific config (Debug/Release)
---@return CMakeTarget[]?, string?
function M.list_targets(binary_dir, configuration)
	binary_dir = vim.fs.normalize(binary_dir)
	local reply_dir = vim.fs.joinpath(binary_dir, ".cmake/api/v1/reply")
	local entries = list_entries(reply_dir)
	if #entries == 0 then
		return nil, "No File API reply in " .. binary_dir .. ". Configure first."
	end

	local index_name = match_first(entries, "^index%-.*%.json$")
	if not index_name then
		return nil, "No File API reply index in " .. reply_dir
	end
	local index, err = read_json(vim.fs.joinpath(reply_dir, index_name))
	if not index then
		return nil, err
	end

	local codemodel_path
	for _, obj in ipairs(index.objects or {}) do
		if obj.kind == "codemodel" then
			codemodel_path = vim.fs.joinpath(reply_dir, obj.jsonFile)
			break
		end
	end
	if not codemodel_path then
		return nil, "No codemodel in File API index"
	end

	local codemodel, cerr = read_json(codemodel_path)
	if not codemodel then
		return nil, cerr
	end

	local out, seen = {}, {}
	for _, cfg in ipairs(codemodel.configurations or {}) do
		if not configuration or cfg.name == configuration then
			for _, tgt in ipairs(cfg.targets or {}) do
				if tgt.name and not seen[tgt.name] then
					seen[tgt.name] = true
					local detail_name = match_first(
						entries,
						"^target%-" .. vim.pesc(tgt.name) .. "%-" .. vim.pesc(cfg.name) .. "%-.*%.json$"
					)
					if detail_name then
						local detail = read_json(vim.fs.joinpath(reply_dir, detail_name))
						if detail then
							table.insert(out, {
								name = detail.name,
								type = detail.type,
								artifacts = detail.artifacts,
							})
						end
					end
				end
			end
		end
	end
	return out
end

---Symlink `<binary_dir>/compile_commands.json` to `<source_dir>/compile_commands.json`
---so clangd (which searches upward from the source) finds it. Refuses to clobber
---a pre-existing regular file at the destination.
---@param binary_dir string
---@param source_dir string
---@return boolean ok, string? err
function M.symlink_compile_commands(binary_dir, source_dir)
	local src = vim.fs.joinpath(binary_dir, "compile_commands.json")
	if vim.fn.filereadable(src) == 0 then
		return false, "compile_commands.json not found in " .. binary_dir
	end
	local dst = vim.fs.joinpath(source_dir, "compile_commands.json")
	-- Prefer a relative target so the link survives directory moves when the
	-- build tree lives under the source tree (the common case).
	local target = src
	local prefix = source_dir:gsub("/$", "") .. "/"
	if src:sub(1, #prefix) == prefix then
		target = src:sub(#prefix + 1)
	end
	local stat = vim.uv.fs_lstat(dst)
	if stat then
		if stat.type ~= "link" then
			return false, dst .. " exists and is not a symlink; leaving it alone"
		end
		local existing = vim.uv.fs_readlink(dst)
		if existing == target then
			return true
		end
		local ok_unlink, unlink_err = vim.uv.fs_unlink(dst)
		if not ok_unlink then
			return false, "could not replace existing symlink: " .. (unlink_err or "?")
		end
	end
	local ok, sym_err = vim.uv.fs_symlink(target, dst)
	if not ok then
		return false, "symlink failed: " .. (sym_err or "?")
	end
	return true
end

---Resolve an executable artifact path for a target. Returns absolute path.
---@param target CMakeTarget
---@param binary_dir string
---@return string?, string?
function M.target_artifact(target, binary_dir)
	if not target.artifacts or not target.artifacts[1] then
		return nil, "no artifacts for target " .. target.name
	end
	local path = vim.fs.joinpath(binary_dir, target.artifacts[1].path)
	if vim.fn.filereadable(path) == 0 and vim.fn.executable(path) == 0 then
		return nil, "binary not found: " .. path
	end
	return vim.fs.abspath(path)
end

return M
