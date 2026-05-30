-- Platform detection for portability guards.
--
-- The config targets desktops, WSL, Termux, and Nvidia Jetson devices. Jetson
-- (Nano / Xavier / Orin) shares a constrained profile: weak CPU for parser
-- compilation, slow disk, no out-of-the-box C toolchain on stock L4T images,
-- and often no network for AI completion. Callers gate heavy features and
-- startup nag screens on `is_jetson()` to keep that profile usable.
--
-- Detection precedence:
--   1. NVIM_JETSON env var — escape hatch for testing on a desktop and for
--      forcing the lite profile when a host *isn't* Jetson but feels like it
--      (low-power VMs, slow remote shells).
--   2. /etc/nv_tegra_release — present on every L4T image since R28; the
--      authoritative marker.
--   3. /proc/device-tree/model — fallback when /etc/nv_tegra_release was
--      removed during image shrinking; matches "jetson" or "nvidia".
-- Result cached on first call so per-file gates don't re-stat every load.

local M = {}

local cached

function M.is_jetson()
	if cached ~= nil then
		return cached
	end

	local env = vim.env.NVIM_JETSON
	if env == "1" or env == "true" then
		cached = true
		return true
	end
	if env == "0" or env == "false" then
		cached = false
		return false
	end

	if vim.uv.fs_stat("/etc/nv_tegra_release") then
		cached = true
		return true
	end

	local f = io.open("/proc/device-tree/model", "r")
	if f then
		local model = (f:read("*a") or ""):lower()
		f:close()
		-- Trailing NUL byte is normal for device-tree strings; substring match
		-- is fine.
		if model:find("jetson") or model:find("nvidia") then
			cached = true
			return true
		end
	end

	cached = false
	return false
end

return M
