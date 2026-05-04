-- CMakePresets.json (and CMakeUserPresets.json) parser.
-- Resolves enough inheritance to populate fields we display/use locally
-- (binaryDir, generator, cacheVariables). Fields cmake reads natively
-- (toolchainFile, condition, environment, etc.) we don't touch — when we
-- run `cmake --preset X` cmake handles its own resolution.

local M = {}

---@class CMakeConfigurePreset
---@field name string
---@field displayName? string
---@field description? string
---@field hidden boolean
---@field inherits? string[]
---@field binaryDir? string
---@field generator? string
---@field cacheVariables table<string, any>

---@class CMakeBuildPreset
---@field name string
---@field hidden boolean
---@field configurePreset? string
---@field configuration? string
---@field targets? string[]

---@class CMakeTestPreset
---@field name string
---@field hidden boolean
---@field configurePreset? string

---@class CMakePresets
---@field sourceDir string
---@field configure CMakeConfigurePreset[]
---@field build CMakeBuildPreset[]
---@field test CMakeTestPreset[]

---@param path string
---@return any?, string?
local function read_json(path)
	if vim.fn.filereadable(path) == 0 then
		return nil
	end
	local lines = vim.fn.readfile(path)
	local ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
	if not ok then
		return nil, "invalid JSON in " .. path
	end
	return decoded
end

---@param presets CMakeConfigurePreset[]
---@param name string
---@return CMakeConfigurePreset?
local function find_by_name(presets, name)
	for _, p in ipairs(presets) do
		if p.name == name then
			return p
		end
	end
end

---@param str string
---@param vars table<string, string>
---@return string
local function expand(str, vars)
	if type(str) ~= "string" then
		return str
	end
	return (str:gsub("%${(%w+)}", function(key)
		return vars[key] or ("${" .. key .. "}")
	end))
end

---Walk `inherits` chain and merge fields where the child doesn't already set them.
---Cycle-safe via `seen` set.
---@param preset CMakeConfigurePreset
---@param all CMakeConfigurePreset[]
---@param seen table<string, boolean>
local function resolve_inheritance(preset, all, seen)
	if seen[preset.name] then
		return
	end
	seen[preset.name] = true
	-- The CMakePresets schema allows `inherits` to be a single string OR an
	-- array of strings. Normalize to array.
	local inherits = preset.inherits
	if type(inherits) == "string" then
		inherits = { inherits }
	end
	for _, parent_name in ipairs(inherits or {}) do
		local parent = find_by_name(all, parent_name)
		if parent then
			resolve_inheritance(parent, all, seen)
			preset.binaryDir = preset.binaryDir or parent.binaryDir
			preset.generator = preset.generator or parent.generator
			preset.cacheVariables =
				vim.tbl_extend("keep", preset.cacheVariables or {}, parent.cacheVariables or {})
		end
	end
end

---Load presets from `source_dir` (defaults to cwd).
---@param source_dir? string
---@return CMakePresets?, string?
function M.load(source_dir)
	source_dir = vim.fs.normalize(source_dir or vim.uv.cwd())

	local main, err = read_json(vim.fs.joinpath(source_dir, "CMakePresets.json"))
	if not main then
		return nil, err or ("no CMakePresets.json in " .. source_dir)
	end
	local user = read_json(vim.fs.joinpath(source_dir, "CMakeUserPresets.json")) or {}

	local function gather(key)
		local out = {}
		for _, p in ipairs(main[key] or {}) do
			table.insert(out, p)
		end
		for _, p in ipairs(user[key] or {}) do
			table.insert(out, p)
		end
		return out
	end

	local raw_configure = gather("configurePresets")
	local configure = {}
	for _, p in ipairs(raw_configure) do
		local resolved = vim.deepcopy(p)
		resolved.hidden = resolved.hidden or false
		resolved.cacheVariables = resolved.cacheVariables or {}
		resolve_inheritance(resolved, raw_configure, {})
		if resolved.binaryDir then
			resolved.binaryDir = expand(resolved.binaryDir, {
				sourceDir = source_dir,
				presetName = resolved.name,
			})
		end
		table.insert(configure, resolved)
	end

	local build = {}
	for _, p in ipairs(gather("buildPresets")) do
		table.insert(build, {
			name = p.name,
			hidden = p.hidden or false,
			configurePreset = p.configurePreset,
			configuration = p.configuration,
			targets = p.targets,
		})
	end

	local test = {}
	for _, p in ipairs(gather("testPresets")) do
		table.insert(test, {
			name = p.name,
			hidden = p.hidden or false,
			configurePreset = p.configurePreset,
		})
	end

	return {
		sourceDir = source_dir,
		configure = configure,
		build = build,
		test = test,
	}
end

---@param presets CMakePresets
---@param name string
---@return CMakeConfigurePreset?
function M.find_configure(presets, name)
	return find_by_name(presets.configure, name)
end

---@param presets CMakePresets
---@param name string
---@return CMakeBuildPreset?
function M.find_build(presets, name)
	for _, p in ipairs(presets.build) do
		if p.name == name then
			return p
		end
	end
end

return M
