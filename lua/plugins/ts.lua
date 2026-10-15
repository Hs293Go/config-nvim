-- nvim-treesitter and nvim-treesitter-textobjects use their `main` branches.
-- nvim-pack-lock.json records the commits. The PackChanged hook in
-- config/pack.lua runs :TSUpdate after an update. The `main` branch needs the
-- `tree-sitter` CLI (0.26.1 or later) and a C compiler to install parsers.
local pack = require("config.pack")
local gh = pack.gh

pack.add({
	{ src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
	{ src = gh("nvim-treesitter/nvim-treesitter-textobjects"), version = "main" },
	-- Pins the enclosing scope's header line(s) — the function/class/loop
	-- you're currently inside — to the top of the window while you scroll
	-- through its body. Reuses the same parsers configured below.
	gh("nvim-treesitter/nvim-treesitter-context"),
})

-- NVIM-TREESITTER
-- ===============

local ts = require("nvim-treesitter")

-- Install the missing parsers from this list. The install is asynchronous.
local ensure_installed = {
	-- systems languages
	"c",
	"cpp",
	"cuda",
	"rust",

	-- scripting languages
	"python",
	"lua",
	"vim",
	"vimdoc",

	-- OS/system/build scripting
	"bash",
	"nix",
	"make",
	"cmake",
	"dockerfile",

	-- markup languages
	"latex",
	"markdown",
	"markdown_inline",

	-- config languages
	"toml",
	"xml",
	"json",
	"yaml",

	-- version control
	"gitignore",
	"diff",

	-- treesitter queries themselves
	"query",
	"regex",
}
local missing = vim.tbl_filter(function(lang)
	return not vim.list_contains(ts.get_installed(), lang)
end, ensure_installed)
if #missing > 0 then
	ts.install(missing)
end

-- NVIM-TREESITTER-TEXTOBJECTS
-- ===========================

require("nvim-treesitter-textobjects").setup({
	select = { lookahead = true },
	move = { set_jumps = true },
})

local select = require("nvim-treesitter-textobjects.select")
local move = require("nvim-treesitter-textobjects.move")

local select_keys = {
	af = "@function.outer",
	["if"] = "@function.inner",
	ac = "@class.outer",
	ic = "@class.inner",
	aa = "@parameter.outer",
	ia = "@parameter.inner",
}

local move_keys = {
	["]f"] = { "goto_next_start", "@function.outer" },
	["]c"] = { "goto_next_start", "@class.outer" },
	["]F"] = { "goto_next_end", "@function.outer" },
	["]C"] = { "goto_next_end", "@class.outer" },
	["[f"] = { "goto_previous_start", "@function.outer" },
	["[c"] = { "goto_previous_start", "@class.outer" },
	["[F"] = { "goto_previous_end", "@function.outer" },
	["[C"] = { "goto_previous_end", "@class.outer" },
}

-- Set the textobject keys in one buffer. nvim-treesitter `master` also set
-- these keys only in buffers with a textobjects query.
local function map_textobjects(buf)
	for lhs, capture in pairs(select_keys) do
		vim.keymap.set({ "x", "o" }, lhs, function()
			select.select_textobject(capture, "textobjects")
		end, { buffer = buf, desc = "Select " .. capture })
	end
	for lhs, spec in pairs(move_keys) do
		local fn, capture = spec[1], spec[2]
		vim.keymap.set({ "n", "x", "o" }, lhs, function()
			move[fn](capture, "textobjects")
		end, { buffer = buf, desc = fn:gsub("_", " ") .. " " .. capture })
	end
end

-- ATTACH
-- ======

-- Parser compilation needs a working C toolchain. Stock L4T images ship
-- without one, so auto-install only produces errors on Jetson. There, install
-- parsers manually with `:TSInstall <lang>` after you set up a compiler.
local auto_install = not require("config.platform").is_jetson()

-- Start treesitter highlighting in a buffer. If the language has the queries,
-- also set the nvim-treesitter indentexpr and the textobject keys.
local function attach(buf, lang)
	if not vim.api.nvim_buf_is_valid(buf) or not pcall(vim.treesitter.start, buf, lang) then
		return false
	end
	if vim.treesitter.query.get(lang, "indents") then
		vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end
	if vim.treesitter.query.get(lang, "textobjects") then
		map_textobjects(buf)
	end
	return true
end

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
	callback = function(ev)
		local lang = vim.treesitter.language.get_lang(ev.match)
		if not lang or attach(ev.buf, lang) then
			return
		end
		-- No parser is installed for this language. Install it if
		-- nvim-treesitter has it, then attach.
		if auto_install and vim.list_contains(ts.get_available(), lang) then
			ts.install(lang):await(vim.schedule_wrap(function()
				attach(ev.buf, lang)
			end))
		end
	end,
})

-- Incremental selection. Neovim 0.12 has it built in (`an` / `in` in visual
-- mode). These keys keep the bindings from nvim-treesitter `master`. In a
-- buffer without a parser, Neovim uses LSP selection ranges.
pack.map({
	{
		"<C-space>",
		function()
			vim.treesitter.select("parent", vim.v.count1)
		end,
		mode = { "n", "x" },
		desc = "Init / expand selection",
	},
	{
		"<bs>",
		function()
			vim.treesitter.select("child", vim.v.count1)
		end,
		mode = "x",
		desc = "Shrink selection",
	},
})

-- NVIM-TREESITTER-CONTEXT
-- =======================

require("treesitter-context").setup({
	-- Cap the sticky header so deeply-nested code can't eat the
	-- viewport; 3 lines fits a signature plus one enclosing scope.
	max_lines = 3,
	-- When over max_lines, trim the innermost context first and keep
	-- the outermost (most orienting) scope visible.
	trim_scope = "outer",
	-- Track the scope under the cursor, not the topmost visible line.
	mode = "cursor",
	-- Underline the context so it reads as a pinned header.
	separator = "─",
	-- Don't repeat each pinned line's real buffer line number in the
	-- gutter; keep the header uncluttered.
	line_numbers = false,
})

pack.map({
	{
		"[x",
		function()
			require("treesitter-context").go_to_context(vim.v.count1)
		end,
		mode = "n",
		desc = "Jump up to enclosing context",
	},
})
