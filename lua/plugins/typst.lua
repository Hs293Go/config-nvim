-- Typst: vimtex-style build / view on top of the tinymist LSP (lsp.lua). No
-- plugin. The keys mirror vimtex.lua's `<leader>T*` maps, buffer-local to
-- typst buffers, so LaTeX muscle memory carries over:
--
--   * Tcc  continuous compile, like :VimtexCompile. Exports once, then flips
--          tinymist's `exportPdf` setting to "onSave" so each :w refreshes the
--          PDF. Press again to stop.
--   * Tcv  export, then open `<name>.pdf` in okular (same viewer as vimtex).
--          okular reloads the file when it changes.
--   * Tcl  clear tinymist's compilation cache. Typst writes no aux files.
--   * Twc  word count, from tinymist's compile status notifications.
--   * Ti   tinymist server info (root, inputs, font paths).
--   * Te   errors of this buffer in the location list.
--
-- Export goes through tinymist, so a pinned main file is respected.
require("plugins.snacks")

local pack = require("config.pack")

local viewer = "okular"

-- Latest `tinymist/compileStatus` payload, for the word count.
local status

-- Merges into the tinymist config from lsp.lua. Clients start on FileType,
-- after this runs.
vim.lsp.config("tinymist", {
	init_options = { compileStatus = "enable" },
	handlers = {
		["tinymist/compileStatus"] = function(_, res)
			status = res
		end,
	},
})

---@return vim.lsp.Client?
local function client()
	local c = vim.lsp.get_clients({ bufnr = 0, name = "tinymist" })[1]
	if not c then
		vim.notify("tinymist is not attached to this buffer", vim.log.levels.WARN)
	end
	return c
end

--- Run a tinymist workspace command on the current file.
---@param command string
---@param on_done fun(res: any)
local function exec(command, on_done)
	local c = client()
	if not c then
		return
	end
	local file = vim.api.nvim_buf_get_name(0)
	c:exec_cmd({ title = command, command = command, arguments = { file } }, { bufnr = 0 }, function(err, res)
		if err then
			vim.notify(("%s failed: %s"):format(command, err.message), vim.log.levels.ERROR)
			return
		end
		on_done(res)
	end)
end

---@param on_done fun(pdf: string)
local function export_pdf(on_done)
	exec("tinymist.exportPdf", function(res)
		if not (res and res.path) then
			vim.notify("Typst export failed (see <leader>Te)", vim.log.levels.ERROR)
			return
		end
		on_done(res.path)
	end)
end

local function set_export_mode(mode)
	for _, c in ipairs(vim.lsp.get_clients({ name = "tinymist" })) do
		c.settings = vim.tbl_extend("force", c.settings or {}, { exportPdf = mode })
		c:notify("workspace/didChangeConfiguration", { settings = c.settings })
	end
end

Snacks.toggle({
	name = "Typst continuous compile",
	map = Snacks.keymap.set, -- supports `ft`
	get = function()
		local c = vim.lsp.get_clients({ name = "tinymist" })[1]
		return c ~= nil and (c.settings or {}).exportPdf == "onSave"
	end,
	set = function(state)
		if state then
			export_pdf(function(pdf)
				vim.notify("Exported " .. vim.fn.fnamemodify(pdf, ":~:."))
			end)
		end
		set_export_mode(state and "onSave" or "never")
	end,
}):map("<leader>Tcc", { ft = "typst" })

pack.map({
	{
		"<leader>Tcv",
		function()
			export_pdf(function(pdf)
				vim.system({ viewer, pdf }, { detach = true })
			end)
		end,
		ft = "typst",
		desc = "Typst: compile and view PDF",
	},
	{
		"<leader>Tcl",
		function()
			exec("tinymist.doClearCache", function()
				vim.notify("Cleared tinymist cache")
			end)
		end,
		ft = "typst",
		desc = "Typst: clear tinymist cache",
	},
	{
		"<leader>Twc",
		function()
			local wc = status and status.wordsCount
			if wc == nil or wc == vim.NIL then
				vim.notify("No word count yet (tinymist has not compiled)", vim.log.levels.WARN)
				return
			end
			vim.notify(("%d words, %d chars, %d pages"):format(wc.words, wc.chars, status.pageCount))
		end,
		ft = "typst",
		desc = "Typst: count words",
	},
	{
		"<leader>Ti",
		function()
			exec("tinymist.getServerInfo", function(res)
				local info = vim.deepcopy(res.primary or res)
				info.stats = nil -- HTML profiling tables
				vim.notify(vim.inspect(info), vim.log.levels.INFO, { title = "tinymist" })
			end)
		end,
		ft = "typst",
		desc = "Typst: tinymist information",
	},
	{
		"<leader>Te",
		function()
			vim.diagnostic.setloclist({ severity = vim.diagnostic.severity.ERROR })
		end,
		ft = "typst",
		desc = "Typst: errors",
	},
})
