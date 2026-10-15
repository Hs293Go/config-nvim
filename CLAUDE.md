# Notes for agents

## Keep the README hotkey list in sync

`README.md` has a `## Hotkeys` section that catalogs every user-defined keymap
in this config. It is maintained by hand — there is no generator script.

**Whenever you add, remove, or change a keymap, update the README in the same
change.** This includes:

- `vim.keymap.set(...)` calls anywhere under `init.lua` or `lua/**/*.lua`
- `pack.map({ ... })` key tables in `lua/plugins/*.lua` (see
  `lua/config/pack.lua` for the entry format)
- Plugin-internal keymaps you configure via `setup()` tables (e.g. `blink.cmp`'s `keymap`
  table, `nvim-treesitter`'s `keymaps` blocks, `oil.nvim`'s `keymaps` table,
  `copilot.lua`'s `suggestion.keymap`)
- Buffer-local keymaps installed by autocmds (e.g. the lazygit `<C-hjkl>`
  pass-throughs in `init.lua`)

Find the right section by leader prefix or category; keep the existing table
format. If a keymap is filetype- or buffer-scoped, say so in the row.

If you removed the last keymap in a section, drop the section heading too.
