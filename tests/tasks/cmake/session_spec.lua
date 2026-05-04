local session_mod = require("tasks.cmake.session")

local function tmpdir()
	local d = vim.fn.tempname()
	vim.fn.mkdir(d, "p")
	return d
end

describe("tasks.cmake.session", function()
	it("load returns empty table when session file is absent", function()
		local d = tmpdir()
		local ctx = session_mod.load(d)
		assert.is_table(ctx)
		assert.is_nil(ctx.configure_preset)
	end)

	it("save then load roundtrips all fields", function()
		local d = tmpdir()
		session_mod.save(d, {
			configure_preset = "my-cfg",
			build_preset = "my-build",
			test_preset = "my-test",
			launch_target = "my-target",
		})
		local loaded = session_mod.load(d)
		assert.equals("my-cfg", loaded.configure_preset)
		assert.equals("my-build", loaded.build_preset)
		assert.equals("my-test", loaded.test_preset)
		assert.equals("my-target", loaded.launch_target)
	end)

	it("save creates the .cache directory if missing", function()
		local d = tmpdir()
		session_mod.save(d, { configure_preset = "x" })
		assert.equals(1, vim.fn.isdirectory(d .. "/.cache"))
		assert.equals(1, vim.fn.filereadable(d .. "/.cache/cmake_tasks.json"))
	end)

	it("load returns empty table on malformed JSON (resilient)", function()
		local d = tmpdir()
		vim.fn.mkdir(d .. "/.cache", "p")
		local f = io.open(d .. "/.cache/cmake_tasks.json", "w")
		f:write("not valid json {{{")
		f:close()
		local ctx = session_mod.load(d)
		assert.is_table(ctx)
		assert.is_nil(ctx.configure_preset)
	end)

	it("save persists nil fields as missing (not 'null' strings)", function()
		local d = tmpdir()
		session_mod.save(d, { configure_preset = "only-this" })
		local loaded = session_mod.load(d)
		assert.equals("only-this", loaded.configure_preset)
		assert.is_nil(loaded.build_preset)
		assert.is_nil(loaded.launch_target)
	end)
end)
