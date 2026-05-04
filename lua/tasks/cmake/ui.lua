-- Thin UI layer. Uses `vim.ui.select` so any registered handler (e.g.
-- `fzf-lua.register_ui_select()`) controls the look. Each function takes the
-- raw data + an `on_pick` callback; no business logic, no state.

local M = {}

---@param presets CMakeConfigurePreset[]
---@param on_pick fun(preset: CMakeConfigurePreset?)
function M.pick_configure_preset(presets, on_pick)
	local visible = vim.tbl_filter(function(p)
		return not p.hidden and p.binaryDir and p.binaryDir ~= ""
	end, presets)
	if #visible == 0 then
		vim.notify("No visible configure presets", vim.log.levels.ERROR)
		return on_pick(nil)
	end
	vim.ui.select(visible, {
		prompt = "Configure preset:",
		format_item = function(p)
			return p.displayName or p.name
		end,
	}, on_pick)
end

---@param presets CMakeBuildPreset[]
---@param configure_preset_name string
---@param on_pick fun(preset: CMakeBuildPreset?)
function M.pick_build_preset(presets, configure_preset_name, on_pick)
	local visible = vim.tbl_filter(function(p)
		return not p.hidden and p.configurePreset == configure_preset_name
	end, presets)
	if #visible == 0 then
		vim.notify("No build presets for configure preset " .. configure_preset_name, vim.log.levels.ERROR)
		return on_pick(nil)
	end
	vim.ui.select(visible, {
		prompt = "Build preset:",
		format_item = function(p)
			return p.name
		end,
	}, on_pick)
end

---@param targets CMakeTarget[]
---@param on_pick fun(target: CMakeTarget?)
function M.pick_launch_target(targets, on_pick)
	local executables = vim.tbl_filter(function(t)
		return t.type == "EXECUTABLE"
	end, targets)
	if #executables == 0 then
		vim.notify("No executable targets in build", vim.log.levels.ERROR)
		return on_pick(nil)
	end
	vim.ui.select(executables, {
		prompt = "Launch target:",
		format_item = function(t)
			return t.name
		end,
	}, on_pick)
end

return M
