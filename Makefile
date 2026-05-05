.PHONY: test lua-ls

test:
	nvim --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/tasks/ {minimal_init = 'tests/minimal_init.lua'}"

# Repo-local Lua dev tools (lua-language-server + stylua). Installs into
# .tools/ — no system install. The lua_ls LSP config and conform.nvim pick up
# the binaries automatically when present.
lua-ls:
	./scripts/install-lua-ls.sh
