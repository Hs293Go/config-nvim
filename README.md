# H S Helson's Neovim config

This is my personal Neovim configuration, which I maintain for my own use and
reference.

## Philosophy

- `lazy` heritage: This config is a handrolled port of parts of the LazyVim
  starter template.
- Maximal compatibility: This config should work on both desktops, Nvidia Jetson
  devices, WSL, and android (via Termux) with minimal changes.

## Plugin management

Neovim 0.12's built-in `vim.pack` manages the plugins. All plugins load at
startup. Each `lua/plugins/*.lua` module adds its plugins, sets them up and sets
its keymaps. A module that needs another module requires that module.
`nvim-pack-lock.json` records the plugin versions. Commit it after an update.

- `:PackUpdate [names…]` — show the available updates. Use `:w` to apply them or
  `:q` to cancel.
- `:PackClean` — delete installed plugins that the config does not add.
- `:checkhealth vim.pack` — show the plugin state.

## Language servers, formatters and linters

The config installs none of them. It expects each on `PATH` and skips the ones
that are missing. `:checkhealth vim.lsp` and `:ConformInfo` show what is
missing.

- Desktops and WSL: home-manager provides them.
- Termux:

  ```sh
  pkg install lua-language-server stylua taplo nodejs
  npm install -g vscode-langservers-extracted yaml-language-server \
    bash-language-server prettier markdownlint-cli
  ```

- Jetson: optional. The Jetson lite profile works without them.

## Hotkeys

`<leader>` is `<Space>`. `<localleader>` is `\`. Mode column omitted for normal
mode.

### Editor essentials

| Key                 | Mode | Action                                                       |
| ------------------- | ---- | ------------------------------------------------------------ |
| `;`                 | n, v | `:` (faster command-line)                                    |
| `::`                | n, v | `;` (original repeat-find)                                   |
| `<leader>w`         |      | Write                                                        |
| `<leader>W`         |      | Write all                                                    |
| `<leader>Q`         |      | Quit all                                                     |
| `<leader>wq`        |      | Close window or tab (never quits Neovim)                     |
| `<leader>m`         |      | Show `:messages`                                             |
| `<Esc>`             |      | Clear search highlight                                       |
| `<C-/>`             | n, v | Toggle line / selection comment                              |
| `q`                 |      | Disabled (use `<leader>Mr`)                                  |
| `Q`                 |      | Disabled (use `<leader>Mp`)                                  |
| `<leader>Mr`        |      | Record macro (then register, then `q` to stop)               |
| `<leader>Mp`        |      | Play macro from register                                     |
| `[<tab>` / `]<tab>` |      | Previous / next tab                                          |
| `<leader>e`         |      | Open file's parent dir in OS file manager                    |
| `<leader>E`         |      | Open cwd in OS file manager                                  |
| `q`                 |      | In read-only panels (help, qf, lspinfo, notify, etc.): close |

### Window navigation

| Key                                   | Mode    | Action                                                                                                                        |
| ------------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` | n, x, t | Move to window left / down / up / right (terminal-mode included; passed through to lazygit when running in a snacks terminal) |

### LSP

| Key          | Mode | Action                                                |
| ------------ | ---- | ----------------------------------------------------- |
| `gd`         |      | Goto definition (fzf-lua → falls back to LSP)         |
| `gr`         |      | References (fzf-lua)                                  |
| `gI`         |      | Goto implementation (fzf-lua)                         |
| `gy`         |      | Goto type definition (fzf-lua)                        |
| `glt`        |      | Type definition (LSP buf)                             |
| `glr`        |      | References (LSP buf)                                  |
| `glD`        |      | Implementation (LSP buf)                              |
| `glo`        |      | Document symbols                                      |
| `glW`        |      | Workspace symbols                                     |
| `<leader>cr` |      | Rename symbol                                         |
| `<leader>ca` | n, v | Code actions                                          |
| `<leader>cd` |      | Line diagnostics (float)                              |
| `]d` / `[d`  |      | Next / prev diagnostic (any severity; Neovim default) |
| `]e` / `[e`  |      | Next / prev error                                     |
| `]w` / `[w`  |      | Next / prev warning                                   |
| `<leader>cf` | n, v | Format buffer / selection (conform)                   |
| `<leader>cl` |      | Run code lens (under cursor)                          |
| `<leader>il` |      | `:LspInfo`                                            |
| `<A-o>`      |      | Clangd: switch source/header (C/C++ buffers only)     |

### Find / search (fzf-lua)

| Key          | Action                                        |
| ------------ | --------------------------------------------- |
| `<leader>ff` | Find files                                    |
| `<leader>fg` | Find files (Git)                              |
| `<leader>fr` | Recent files                                  |
| `<leader>fb` | Buffers                                       |
| `<leader>sg` | Live grep                                     |
| `<leader>fw` | Grep word under cursor (in v: grep selection) |
| `<leader>fh` | Help tags                                     |
| `<leader>fk` | Keymaps                                       |
| `<leader>fc` | Commands                                      |
| `<leader>f:` | Command history                               |
| `<leader>f/` | Search history                                |
| `<leader>fR` | Resume last picker                            |
| `<leader>fi` | Insert file path(s) at cursor                 |
| `<leader>fd` | Diagnostics (buffer)                          |
| `<leader>fD` | Diagnostics (workspace)                       |
| `<leader>fs` | Symbols (buffer)                              |
| `<leader>fS` | Symbols (workspace)                           |
| `<leader>ft` | Find todo comments                            |

### Search & replace (grug-far.nvim)

| Key          | Mode | Action                                         |
| ------------ | ---- | ---------------------------------------------- |
| `<leader>sr` |      | Open grug-far search & replace                 |
| `<leader>sr` | v    | Open grug-far seeded with the visual selection |
| `q`          |      | (Inside grug-far) close the window             |

### List panels (trouble.nvim)

Persistent panels — counterpart to the transient `<leader>f*` fzf pickers. Read
as "list X". Same suffix letters where the noun matches.

| Key          | Action                       |
| ------------ | ---------------------------- |
| `<leader>ld` | List diagnostics (workspace) |
| `<leader>lD` | List diagnostics (buffer)    |
| `<leader>ls` | List symbols                 |
| `<leader>lr` | List LSP refs/defs           |
| `<leader>lt` | List todos                   |
| `<leader>lq` | List quickfix                |
| `<leader>lQ` | List loclist                 |

### File tree (oil.nvim)

| Key          | Action                                   |
| ------------ | ---------------------------------------- |
| `<leader>oo` | Open Oil (floating)                      |
| `<leader>oO` | Open Oil (full window)                   |
| `<leader>ov` | Open Oil (vsplit on right)               |
| `<leader>of` | Open Oil at chosen directory (fd picker) |

Inside an Oil buffer: `<CR>` select, `<leader>s`/`<leader>v` open in split,
`<C-t>` open in tab, `<C-p>` preview, `<C-l>` refresh, `<bs>` parent, `_` cwd,
`` ` `` cd, `g~` cd (tab), `gs` change sort, `gx` open external, `g.` toggle
hidden, `g\` toggle trash, `g?` help, `q` close.

Git integration: the signcolumn shows two-char index/worktree status
(`M`/`A`/`D`/`??` etc. — same alphabet as `git status --short`). Renaming a
tracked file in the buffer uses `git mv` (history follows); deleting one uses
`git rm` (stages the delete). New files are not auto-staged.

### Git

| Key           | Mode | Action                       |
| ------------- | ---- | ---------------------------- |
| `<leader>gg`  |      | Lazygit (cwd)                |
| `<leader>gf`  |      | Lazygit current file history |
| `<leader>gl`  |      | Lazygit log (cwd)            |
| `<leader>gB`  | n, x | Git browse in browser        |
| `<leader>gc`  |      | Git commits (fzf)            |
| `<leader>gs`  |      | Git status (fzf)             |
| `<leader>gb`  |      | Git branches (fzf)           |
| `]h` / `[h`   |      | Next / prev hunk             |
| `]H` / `[H`   |      | Last / first hunk            |
| `<leader>ghs` | n, x | Stage hunk                   |
| `<leader>ghr` | n, x | Reset hunk                   |
| `<leader>ghS` |      | Stage buffer                 |
| `<leader>ghu` |      | Undo stage hunk              |
| `<leader>ghR` |      | Reset buffer                 |
| `<leader>ghp` |      | Preview hunk inline          |
| `<leader>ghb` |      | Blame line (full)            |
| `<leader>ghB` |      | Blame buffer                 |
| `<leader>ghd` |      | Diff this                    |
| `<leader>ghD` |      | Diff this (against HEAD~)    |
| `ih`          | o, x | Text object: gitsigns hunk   |

#### Diffview (diffview.nvim)

| Key           | Mode | Action                                                    |
| ------------- | ---- | --------------------------------------------------------- |
| `<leader>gdd` |      | Diff uncommitted changes (staged + unstaged) vs HEAD      |
| `<leader>gdm` |      | Diff branch against `origin/HEAD` (merge-base, like PR)   |
| `<leader>gdh` |      | File history (current file)                               |
| `<leader>gdh` | x    | History of the selected line range                        |
| `<leader>gdH` |      | Repo history                                              |
| `<leader>gdq` |      | Close Diffview                                            |
| `q`           |      | (Inside Diffview view / file panel / history panel) close |

#### GitHub PRs and issues (octo.nvim)

Needs the `gh` CLI, authenticated with `gh auth login`.

| Key           | Action                |
| ------------- | --------------------- |
| `<leader>gpl` | List PRs (fzf)        |
| `<leader>gps` | Search PRs            |
| `<leader>gpc` | Create PR             |
| `<leader>gpr` | Start / resume review |
| `<leader>gpS` | Submit review         |
| `<leader>gpi` | List issues (fzf)     |

Octo buffers and review diffs keep octo's default buffer-local maps (mostly
under `<localleader>`, e.g. `<localleader>ca` add comment, `]q`/`[q` next/prev
file).

### Tasks (overseer + bespoke wrappers)

| Key                          | Action                           |
| ---------------------------- | -------------------------------- |
| `<leader>tr`                 | Run task (picker)                |
| `<leader>tt`                 | Toggle task list                 |
| `<leader>tl`                 | Rerun last task                  |
| `<leader>tj`                 | just: pick and run recipe        |
| `<leader>tcc`                | CMake: configure                 |
| `<leader>tcb` / `<leader>Cb` | CMake: build                     |
| `<leader>tct` / `<leader>Ct` | CMake: test                      |
| `<leader>tcr` / `<leader>Cr` | CMake: launch target             |
| `<leader>tcsc`               | CMake: reselect configure preset |
| `<leader>tcsb`               | CMake: reselect build preset     |
| `<leader>tcsl`               | CMake: reselect launch target    |

### Tests (neotest, Python)

| Key          | Action                   |
| ------------ | ------------------------ |
| `<leader>nr` | Run nearest test         |
| `<leader>nf` | Run file tests           |
| `<leader>nl` | Re-run last test         |
| `<leader>nx` | Stop running tests       |
| `<leader>ns` | Toggle summary tree      |
| `<leader>no` | Show test output (float) |
| `<leader>np` | Toggle output panel      |
| `<leader>nw` | Watch file tests         |
| `]n` / `[n`  | Next / prev failed test  |

### AI (Claude Code)

| Key          | Mode | Action                                                 |
| ------------ | ---- | ------------------------------------------------------ |
| `<leader>ac` |      | Toggle Claude                                          |
| `<leader>af` |      | Focus Claude                                           |
| `<leader>ar` |      | Resume Claude                                          |
| `<leader>aC` |      | Continue Claude                                        |
| `<leader>am` |      | Select Claude model                                    |
| `<leader>ab` |      | Add current buffer                                     |
| `<leader>as` | v    | Send to Claude                                         |
| `<leader>as` |      | Add file (in tree-style buffers)                       |
| `<leader>aa` |      | Accept diff                                            |
| `<leader>ad` |      | Deny diff                                              |
| `<C-q>`      | t    | Exit to normal mode (Claude Code terminal buffer only) |

### Copilot inline suggestions (insert mode)

| Key                      | Action                 |
| ------------------------ | ---------------------- |
| `<Right>`                | Accept suggestion      |
| `<S-Right>`              | Accept word            |
| `<C-S-Right>`            | Accept line            |
| `<C-Right>` / `<C-Left>` | Next / prev suggestion |

### Completion (blink.cmp, insert mode)

| Key                 | Action                          |
| ------------------- | ------------------------------- |
| `<Tab>` / `<S-Tab>` | Select next / prev              |
| `<CR>`              | Accept                          |
| `<C-e>`             | Hide menu                       |
| `<C-b>` / `<C-f>`   | Scroll docs up / down           |
| `<C-j>` / `<C-k>`   | Snippet jump forward / backward |

### UI toggles (snacks.toggle)

Each toggle notifies on/off state via the snacks notifier.

| Key          | Toggle                                                |
| ------------ | ----------------------------------------------------- |
| `<leader>uf` | Auto-format (buffer)                                  |
| `<leader>uF` | Auto-format (global)                                  |
| `<leader>us` | Spelling                                              |
| `<leader>uw` | Wrap                                                  |
| `<leader>ul` | Line numbers                                          |
| `<leader>uL` | Relative line numbers                                 |
| `<leader>ud` | Diagnostics                                           |
| `<leader>uc` | Conceal level                                         |
| `<leader>uh` | Inlay hints                                           |
| `<leader>uT` | Treesitter highlight                                  |
| `<leader>ub` | Background light/dark                                 |
| `<leader>um` | Render Markdown (in-buffer rendering; off by default) |

### Sessions (persistence.nvim)

| Key          | Action                     |
| ------------ | -------------------------- |
| `<leader>qs` | Restore session for cwd    |
| `<leader>ql` | Restore last session       |
| `<leader>qd` | Don't save current session |

### Treesitter

| Key         | Mode    | Action                                                                                     |
| ----------- | ------- | ------------------------------------------------------------------------------------------ |
| `<C-space>` | n, x    | Init / expand selection (built-in `vim.treesitter.select`, or LSP ranges without a parser) |
| `<bs>`      | x       | Shrink selection                                                                           |
| `af` / `if` | o, x    | Outer / inner function (buffer-local: buffers with a textobjects query)                    |
| `ac` / `ic` | o, x    | Outer / inner class (buffer-local)                                                         |
| `aa` / `ia` | o, x    | Outer / inner parameter (buffer-local)                                                     |
| `]f` / `[f` | n, x, o | Next / prev function start (buffer-local)                                                  |
| `]F` / `[F` | n, x, o | Next / prev function end (buffer-local)                                                    |
| `]c` / `[c` | n, x, o | Next / prev class start (buffer-local)                                                     |
| `]C` / `[C` | n, x, o | Next / prev class end (buffer-local)                                                       |
| `[x`        | n       | Jump up to enclosing context (nvim-treesitter-context; accepts a count)                    |

### Misc navigation

| Key         | Action                   |
| ----------- | ------------------------ |
| `]t` / `[t` | Next / prev todo comment |

### LaTeX (vimtex, `tex` filetype)

| Key           | Action        |
| ------------- | ------------- |
| `<leader>Tcc` | Compile       |
| `<leader>Tcl` | Clean         |
| `<leader>Tcv` | View PDF      |
| `<leader>Twc` | Count words   |
| `<leader>Ti`  | Vimtex info   |
| `<leader>Te`  | Vimtex errors |

### Markdown (`markdown` filetype)

| Key          | Action                                                              |
| ------------ | ------------------------------------------------------------------- |
| `<leader>cp` | Toggle live browser preview with KaTeX math (markdown-preview.nvim) |

### Terminal

| Key       | Mode | Action                                               |
| --------- | ---- | ---------------------------------------------------- |
| `<C-c>`   |      | Delete buffer (skipped in terminal buffers)          |
| ``<C-`>`` | n, t | Toggle terminal (cwd; ignores Claude Code terminals) |
| `<C-S-5>` | t    | Create new terminal                                  |
| `;` / `:` | n    | (in snacks terminals) noop with warning              |
