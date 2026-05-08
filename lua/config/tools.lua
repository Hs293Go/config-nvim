-- Mini-mason: a tiny installer + detector for repo-local tools.
--
-- Two providers:
--   * npm    — packages installed under .tools/npm/node_modules/ via
--              `npm install --prefix .tools/npm <pkg>`.
--   * github — release-asset binaries downloaded from GitHub releases via
--              curl + tar/unzip into .tools/<name>/. Version-pinned in the
--              registry; re-runs are idempotent (skip when already at target
--              version).
--
-- User commands (registered on require):
--   :ToolInstall [name]   -- install one tool, or all missing if no arg
--   :ToolList             -- show install status (local / PATH / MISSING)
--
-- From Lua: require("config.tools").bin("jsonls")
--   -> absolute path to local install if present, else PATH binary, else nil.
--   -> callers should skip vim.lsp.enable / set their formatter command when nil.
--
-- Side effect on require: prepends .tools/npm/node_modules/.bin to vim.env.PATH
-- so conform / nvim-lint resolve locally-installed CLI tools (markdownlint,
-- taplo, prettier, ...) by name without per-tool command overrides. The
-- github-provider binaries are not on PATH; their callers use absolute paths
-- via tools.bin().

local M = {}

local config_dir = vim.fn.stdpath("config")
local install_root = vim.fs.joinpath(config_dir, ".tools/npm")
local local_bin_dir = vim.fs.joinpath(install_root, "node_modules", ".bin")

-- Prepend local_bin_dir to PATH if not already present. Idempotent across
-- reloads so :Lazy reload won't keep pushing duplicate entries.
do
	local sep = vim.fn.has("win32") == 1 and ";" or ":"
	local current = vim.env.PATH or ""
	if not (sep .. current .. sep):find(sep .. local_bin_dir .. sep, 1, true) then
		vim.env.PATH = local_bin_dir .. sep .. current
	end
end

M.registry = {
	-- npm provider (default when entry has `npm = ...`)
	jsonls = {
		npm = "vscode-langservers-extracted",
		bin = "vscode-json-language-server",
	},
	yamlls = {
		npm = "yaml-language-server",
		bin = "yaml-language-server",
	},
	taplo = {
		npm = "@taplo/cli",
		bin = "taplo",
	},
	markdownlint = {
		npm = "markdownlint-cli",
		bin = "markdownlint",
	},
	prettier = {
		npm = "prettier",
		bin = "prettier",
	},
	-- github provider: GitHub-release downloads, version-pinned.
	lua_ls = {
		provider = "github",
		repo = "LuaLS/lua-language-server",
		version = "3.13.5",
		platforms = {
			Linux_x86_64 = "linux-x64",
			Linux_aarch64 = "linux-arm64",
			Darwin_x86_64 = "darwin-x64",
			Darwin_arm64 = "darwin-arm64",
		},
		asset = function(ver, plat)
			return ("lua-language-server-%s-%s.tar.gz"):format(ver, plat)
		end,
		extract = "tar",
		-- Tarball ships a top-level `bin/` so extract one level above.
		dest = vim.fs.joinpath(config_dir, ".tools/lua_ls"),
		bin_path = vim.fs.joinpath(config_dir, ".tools/lua_ls/bin/lua-language-server"),
		bin = "lua-language-server",
	},
	stylua = {
		provider = "github",
		repo = "JohnnyMorganz/StyLua",
		version = "2.0.2",
		tag_prefix = "v", -- stylua tags are v2.0.2; lua-ls uses bare 3.13.5
		platforms = {
			Linux_x86_64 = "linux-x86_64",
			Linux_aarch64 = "linux-aarch64",
			Darwin_x86_64 = "macos-x86_64",
			Darwin_arm64 = "macos-aarch64",
		},
		asset = function(_, plat)
			return ("stylua-%s.zip"):format(plat)
		end,
		extract = "zip",
		bin_path = vim.fs.joinpath(config_dir, ".tools/stylua/bin/stylua"),
		bin = "stylua",
	},
}

local function provider_of(entry)
	return entry.provider or "npm"
end

local function local_bin(entry)
	-- github-provider entries have an explicit absolute bin_path; npm-provider
	-- entries resolve under the shared node_modules/.bin/.
	return entry.bin_path or vim.fs.joinpath(local_bin_dir, entry.bin)
end

function M.bin(name)
	local entry = M.registry[name]
	if not entry then
		return nil
	end
	local lb = local_bin(entry)
	if vim.fn.executable(lb) == 1 then
		return lb
	end
	if vim.fn.executable(entry.bin) == 1 then
		return entry.bin
	end
	return nil
end

function M.installed_locally(name)
	local entry = M.registry[name]
	if not entry then
		return false
	end
	return vim.fn.executable(local_bin(entry)) == 1
end

function M.missing()
	local out = {}
	for name in pairs(M.registry) do
		if M.bin(name) == nil then
			table.insert(out, name)
		end
	end
	table.sort(out)
	return out
end

local function notify_install_result(name, out, on_done)
	vim.schedule(function()
		if out.code == 0 then
			vim.notify(name .. " installed", vim.log.levels.INFO)
			if on_done then
				on_done()
			end
		else
			vim.notify(
				("%s install failed (exit %d)\n%s"):format(name, out.code, out.stderr or ""),
				vim.log.levels.ERROR
			)
		end
	end)
end

local function install_npm(name, entry, on_done)
	if vim.fn.executable("npm") ~= 1 then
		vim.notify("npm not found on PATH; cannot install " .. name, vim.log.levels.ERROR)
		return
	end
	vim.fn.mkdir(install_root, "p")
	vim.notify("Installing " .. name .. " (" .. entry.npm .. ") ...", vim.log.levels.INFO)
	vim.system({ "npm", "install", "--prefix", install_root, entry.npm }, { text = true }, function(out)
		notify_install_result(name, out, on_done)
	end)
end

local function platform_for(entry)
	local uname = vim.uv.os_uname()
	local key = uname.sysname .. "_" .. uname.machine
	return entry.platforms and entry.platforms[key], key
end

local function install_gh(name, entry, on_done)
	local platform, plat_key = platform_for(entry)
	if not platform then
		vim.notify(("%s: unsupported platform %s"):format(name, plat_key), vim.log.levels.ERROR)
		return
	end

	local extractor = entry.extract == "zip" and "unzip" or "tar"
	for _, dep in ipairs({ "curl", extractor }) do
		if vim.fn.executable(dep) ~= 1 then
			vim.notify(("%s install needs %s on PATH"):format(name, dep), vim.log.levels.ERROR)
			return
		end
	end

	local version = entry.version

	-- Skip if already at target version. Probe is synchronous so we don't
	-- start a download just to throw it away.
	if vim.fn.executable(entry.bin_path) == 1 then
		local probe = vim.system({ entry.bin_path, "--version" }, { text = true }):wait()
		if probe.code == 0 and (probe.stdout or ""):find(version, 1, true) then
			vim.schedule(function()
				vim.notify(("%s %s already installed"):format(name, version), vim.log.levels.INFO)
				if on_done then
					on_done()
				end
			end)
			return
		end
	end

	local tag = (entry.tag_prefix or "") .. version
	local asset = entry.asset(version, platform)
	local url = ("https://github.com/%s/releases/download/%s/%s"):format(entry.repo, tag, asset)

	local tmpdir = vim.fn.tempname()
	vim.fn.mkdir(tmpdir, "p")
	local dest = entry.dest or vim.fs.dirname(entry.bin_path)
	vim.fn.mkdir(dest, "p")
	local archive = vim.fs.joinpath(tmpdir, asset)

	vim.notify(("Downloading %s %s ..."):format(name, version), vim.log.levels.INFO)

	vim.system({ "curl", "-fsSL", url, "-o", archive }, { text = true }, function(curl_out)
		if curl_out.code ~= 0 then
			vim.schedule(function()
				vim.fn.delete(tmpdir, "rf")
				vim.notify(
					("%s download failed (exit %d)\n%s"):format(name, curl_out.code, curl_out.stderr or ""),
					vim.log.levels.ERROR
				)
			end)
			return
		end

		local extract_cmd
		if entry.extract == "zip" then
			extract_cmd = { "unzip", "-q", "-o", archive, "-d", dest }
		else
			extract_cmd = { "tar", "-xzf", archive, "-C", dest }
		end

		vim.system(extract_cmd, { text = true }, function(ex_out)
			vim.schedule(function()
				vim.fn.delete(tmpdir, "rf")
				if ex_out.code ~= 0 then
					vim.notify(
						("%s extract failed (exit %d)\n%s"):format(name, ex_out.code, ex_out.stderr or ""),
						vim.log.levels.ERROR
					)
					return
				end
				-- zip extraction can drop the +x bit; restore it.
				if vim.uv.fs_stat(entry.bin_path) then
					vim.uv.fs_chmod(entry.bin_path, tonumber("755", 8))
				end
				if vim.fn.executable(entry.bin_path) ~= 1 then
					vim.notify(
						("%s install incomplete: %s missing or not executable"):format(name, entry.bin_path),
						vim.log.levels.ERROR
					)
					return
				end
				vim.notify(("%s %s installed"):format(name, version), vim.log.levels.INFO)
				if on_done then
					on_done()
				end
			end)
		end)
	end)
end

function M.install(name, on_done)
	local entry = M.registry[name]
	if not entry then
		vim.notify("Unknown tool: " .. name, vim.log.levels.ERROR)
		return
	end
	if provider_of(entry) == "github" then
		return install_gh(name, entry, on_done)
	end
	return install_npm(name, entry, on_done)
end

function M.install_missing()
	local missing = M.missing()
	if #missing == 0 then
		vim.notify("All tools available", vim.log.levels.INFO)
		return
	end
	for _, name in ipairs(missing) do
		M.install(name)
	end
end

-- Notify-once on tools nowhere available (neither local nor PATH).
function M.notify_missing_once()
	local missing = M.missing()
	if #missing > 0 then
		vim.schedule(function()
			vim.notify(
				"Missing tools: " .. table.concat(missing, ", ") .. "\nRun :ToolInstall to install.",
				vim.log.levels.WARN
			)
		end)
	end
end

vim.api.nvim_create_user_command("ToolInstall", function(args)
	if args.args == "" then
		M.install_missing()
	else
		M.install(args.args)
	end
end, {
	nargs = "?",
	complete = function()
		return vim.tbl_keys(M.registry)
	end,
	desc = "Install repo tools (mini-mason)",
})

vim.api.nvim_create_user_command("ToolList", function()
	local lines = {}
	for name, entry in pairs(M.registry) do
		local status
		if M.installed_locally(name) then
			status = "local"
		elseif vim.fn.executable(entry.bin) == 1 then
			status = "PATH"
		else
			status = "MISSING"
		end
		local source
		if provider_of(entry) == "github" then
			source = ("gh:%s@%s"):format(entry.repo, entry.version)
		else
			source = "npm:" .. entry.npm
		end
		table.insert(lines, ("  %-13s [%-7s]  %s"):format(name, status, source))
	end
	table.sort(lines)
	vim.notify("Tools:\n" .. table.concat(lines, "\n"), vim.log.levels.INFO)
end, { desc = "List repo tool status" })

return M
