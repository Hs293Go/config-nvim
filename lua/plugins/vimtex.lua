local pack = require("config.pack")

-- vimtex reads these globals when its ftplugin loads. Set them before you add
-- the plugin.
vim.g.vimtex_view_general_viewer = "okular"
vim.g.vimtex_compiler_method = "latexmk"
vim.g.vimtex_compiler_latexmk = {
	build_dir = "build",
	out_dir = "build",
}
vim.g.vimtex_complete_enabled = 1
vim.g.vimtex_complete_close_braces = 1
vim.g.vimtex_complete_ignore_case = 1
vim.g.vimtex_complete_smart_case = 1

pack.add({ pack.gh("lervag/vimtex") })

pack.map({
	{ "<leader>Tcc", "<cmd>VimtexCompile<cr>", desc = "Compile LaTeX with Vimtex" },
	{ "<leader>Tcl", "<cmd>VimtexClean<cr>", desc = "Clean LaTeX with Vimtex" },
	{ "<leader>Tcv", "<cmd>VimtexView<cr>", desc = "View PDF with Vimtex" },
	{ "<leader>Twc", "<cmd>VimtexCountWords<cr>", desc = "Count words with Vimtex" },
	{ "<leader>Ti", "<cmd>VimtexInfo<cr>", desc = "Vimtex Information" },
	{ "<leader>Te", "<cmd>VimtexErrors<cr>", desc = "Vimtex errors" },
})
