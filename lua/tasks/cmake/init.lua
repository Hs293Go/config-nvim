-- Public API for CMake task orchestration. Call sites: keymaps in
-- `lua/plugins/tasks.lua` and overseer template builders.
--
-- The four primary entry points (`configure` / `build` / `test` / `launch`)
-- are interactive: they fill in any missing session state (preset / target)
-- via `vim.ui.select` and then dispatch the actual work to overseer.
--
-- Sequencing inside a single entry point is callback-based — `vim.ui.select`
-- and overseer's `on_complete` are both async, so each "ensure X then Y"
-- chain is written as a CPS pipeline. Kept flat by extracting `ensure_*`
-- helpers; no nested anonymous closures more than two deep.

local presets_mod = require("tasks.cmake.presets")
local session_mod = require("tasks.cmake.session")
local driver = require("tasks.cmake.driver")
local ui = require("tasks.cmake.ui")

local M = {}

---@class CMakeTasksOpts

---@type CMakeContext  -- module-singleton; reset on DirChanged
local ctx = {}

local function source_dir()
	return vim.fs.normalize(vim.uv.cwd())
end

local function project_has_presets(dir)
	dir = dir or source_dir()
	return vim.fn.filereadable(vim.fs.joinpath(dir, "CMakePresets.json")) == 1
		or vim.fn.filereadable(vim.fs.joinpath(dir, "CMakeUserPresets.json")) == 1
end

---@return CMakePresets?
local function load_presets()
	local p, err = presets_mod.load(source_dir())
	if not p then
		if err then
			vim.notify(err, vim.log.levels.ERROR)
		end
		return nil
	end
	return p
end

local function persist()
	session_mod.save(source_dir(), ctx)
end

local function hydrate()
	ctx = session_mod.load(source_dir())
end

---Run a command via overseer with the standard component set. Optionally
---fires `on_complete(success)` after the task finishes.
---@param spec { name: string, cmd: string[], cwd?: string, env?: table<string,string> }
---@param on_complete? fun(ok: boolean)
local function run(spec, on_complete)
	local overseer = require("overseer")
	local task = overseer.new_task({
		name = spec.name,
		cmd = spec.cmd,
		cwd = spec.cwd,
		env = spec.env,
		components = { "default", { "open_output", focus = false } },
	})
	if on_complete then
		task:subscribe("on_complete", function(t)
			on_complete(t.status == "SUCCESS")
		end)
	end
	task:start()
end

---Yield the configure preset (cached or freshly picked).
---@param force boolean re-pick even if session already has one
---@param cb fun(preset: CMakeConfigurePreset?)
local function ensure_configure_preset(force, cb)
	local presets = load_presets()
	if not presets then
		return cb(nil)
	end
	if not force and ctx.configure_preset then
		local p = presets_mod.find_configure(presets, ctx.configure_preset)
		if p then
			return cb(p)
		end
	end
	ui.pick_configure_preset(presets.configure, function(picked)
		if not picked then
			return cb(nil)
		end
		ctx.configure_preset = picked.name
		persist()
		cb(picked)
	end)
end

---Yield (build_preset, configure_preset). Picks both if needed.
---@param force boolean re-pick the build preset even if session has one
---@param cb fun(build: CMakeBuildPreset?, configure: CMakeConfigurePreset?)
local function ensure_build_preset(force, cb)
	ensure_configure_preset(false, function(cfg)
		if not cfg then
			return cb(nil, nil)
		end
		local presets = load_presets()
		if not presets then
			return cb(nil, nil)
		end
		if not force and ctx.build_preset then
			local b = presets_mod.find_build(presets, ctx.build_preset)
			if b and b.configurePreset == cfg.name then
				return cb(b, cfg)
			end
		end
		ui.pick_build_preset(presets.build, cfg.name, function(picked)
			if not picked then
				return cb(nil, nil)
			end
			ctx.build_preset = picked.name
			persist()
			cb(picked, cfg)
		end)
	end)
end

---Configure (cmake --preset). Drops a File API query file before running so
---list_targets works after.
---@param force_preset? boolean
function M.configure(force_preset)
	ensure_configure_preset(force_preset or false, function(cfg)
		if not cfg then
			return
		end
		if not cfg.binaryDir or cfg.binaryDir == "" then
			vim.notify("preset " .. cfg.name .. " has no binaryDir", vim.log.levels.ERROR)
			return
		end
		if vim.fn.isdirectory(cfg.binaryDir) == 0 then
			vim.fn.mkdir(cfg.binaryDir, "p")
		end
		driver.write_query_file(cfg.binaryDir)
		run({
			name = "cmake: configure (" .. cfg.name .. ")",
			cmd = driver.configure_cmd(cfg.name),
			cwd = source_dir(),
		}, function(ok)
			if not ok then
				return
			end
			local linked, err = driver.symlink_compile_commands(cfg.binaryDir, source_dir())
			if not linked and err then
				vim.notify("cmake: " .. err, vim.log.levels.WARN)
			end
		end)
	end)
end

---Build via cmake --build --preset. Triggers configure-preset pick if
---needed, build-preset pick if needed.
---@param force_build_preset? boolean
---@param on_built? fun()  fires only on successful build
function M.build(force_build_preset, on_built)
	ensure_build_preset(force_build_preset or false, function(b, _cfg)
		if not b then
			return
		end
		run({
			name = "cmake: build (" .. b.name .. ")",
			cmd = driver.build_cmd(b.name),
			cwd = source_dir(),
		}, function(ok)
			if ok and on_built then
				on_built()
			end
		end)
	end)
end

---Test via ctest --preset. Reuses the build preset's name as the test preset
---name when both exist; falls back to `cmake --build --preset && ctest` only
---if a dedicated test preset isn't defined. Kept simple: just runs the build
---preset's name through ctest, which works when test presets share names.
function M.test()
	ensure_build_preset(false, function(b, _cfg)
		if not b then
			return
		end
		run({
			name = "ctest (" .. b.name .. ")",
			cmd = driver.test_cmd(b.name),
			cwd = source_dir(),
		})
	end)
end

---Build, then run an executable target. Always builds first to ensure the
---binary is fresh. Uses cached `launch_target` unless `force_target` is set.
---@param force_target? boolean
function M.launch(force_target)
	M.build(false, function()
		local presets = load_presets()
		if not presets or not ctx.configure_preset then
			return
		end
		local cfg = presets_mod.find_configure(presets, ctx.configure_preset)
		if not cfg or not cfg.binaryDir then
			return
		end

		local targets, err = driver.list_targets(cfg.binaryDir)
		if not targets then
			vim.notify(err or "no targets", vim.log.levels.WARN)
			return
		end

		local function execute(target)
			local artifact, aerr = driver.target_artifact(target, cfg.binaryDir)
			if not artifact then
				vim.notify(aerr or "missing artifact", vim.log.levels.ERROR)
				return
			end
			ctx.launch_target = target.name
			persist()
			-- sleep 0.5 lets prior task output flush before launch output
			run({
				name = "run: " .. target.name,
				cmd = { "sh", "-c", "sleep 0.5; exec " .. vim.fn.shellescape(artifact) },
				cwd = vim.fs.dirname(artifact),
			})
		end

		if not force_target and ctx.launch_target then
			for _, t in ipairs(targets) do
				if t.name == ctx.launch_target then
					return execute(t)
				end
			end
		end
		ui.pick_launch_target(targets, function(picked)
			if picked then
				execute(picked)
			end
		end)
	end)
end

function M.reselect_configure()
	ensure_configure_preset(true, function(cfg)
		if cfg then
			vim.notify("Configure preset: " .. cfg.name)
		end
	end)
end

function M.reselect_build()
	ensure_build_preset(true, function(b)
		if b then
			vim.notify("Build preset: " .. b.name)
		end
	end)
end

function M.reselect_launch()
	ctx.launch_target = nil
	persist()
	M.launch(true)
end

---@param opts? CMakeTasksOpts
function M.setup(opts) -- luacheck: ignore opts
	if project_has_presets() then
		hydrate()
	end
	vim.api.nvim_create_autocmd("DirChanged", {
		callback = function()
			ctx = {}
			if project_has_presets() then
				hydrate()
			end
		end,
	})
end

return M
