.PHONY: test lua-ls

test:
	nvim --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/tasks/ {minimal_init = 'tests/minimal_init.lua'}"

# Repo-local lua-language-server. Installs into .tools/lua_ls/ — no system
# install. lua_ls LSP config picks up the binary automatically when present.
lua-ls:
	./scripts/install-lua-ls.sh
