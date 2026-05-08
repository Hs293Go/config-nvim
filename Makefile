.PHONY: test

test:
	nvim --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/tasks/ {minimal_init = 'tests/minimal_init.lua'}"
