local presets_mod = require("tasks.cmake.presets")

-- Resolve fixtures relative to this spec file's location, not cwd. Plenary's
-- runner chdir's during execution, so cwd-relative paths break.
local spec_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local function fixture(name)
	-- Bind first; `:gsub` returns (string, count) and the second value would
	-- otherwise spread into callers' argument lists.
	local p = vim.fn.fnamemodify(spec_dir .. "/../../fixtures/presets/" .. name, ":p")
	p = p:gsub("/$", "")
	return p
end

describe("tasks.cmake.presets.load", function()
	it("returns nil + err when CMakePresets.json is missing", function()
		local p, err = presets_mod.load("/nonexistent/path/that/does/not/exist")
		assert.is_nil(p)
		assert.is_string(err)
	end)

	it("loads basic configure/build/test presets", function()
		local p, err = presets_mod.load(fixture("basic"))
		assert.is_nil(err)
		assert.is_not_nil(p)
		assert.equals(2, #p.configure)
		assert.equals(2, #p.build)
		assert.equals(1, #p.test)

		local default = presets_mod.find_configure(p, "default")
		assert.is_not_nil(default)
		assert.equals("Default", default.displayName)
		assert.equals("Ninja", default.generator)
		assert.equals(false, default.hidden)
	end)

	it("expands ${sourceDir} and ${presetName} in binaryDir", function()
		local p = presets_mod.load(fixture("basic"))
		local default = presets_mod.find_configure(p, "default")
		assert.equals(fixture("basic") .. "/build", default.binaryDir)

		local hidden = presets_mod.find_configure(p, "hidden-base")
		assert.equals(fixture("basic") .. "/build/hidden-base", hidden.binaryDir)
	end)

	it("preserves hidden flag", function()
		local p = presets_mod.load(fixture("basic"))
		local hidden = presets_mod.find_configure(p, "hidden-base")
		assert.equals(true, hidden.hidden)
	end)

	it("inherits binaryDir from parent when child has none", function()
		local p = presets_mod.load(fixture("inherits"))
		local child = presets_mod.find_configure(p, "child")
		-- child has no own binaryDir; expansion happens at the resolved level
		assert.equals(fixture("inherits") .. "/build/child", child.binaryDir)
	end)

	it("respects child binaryDir override", function()
		local p = presets_mod.load(fixture("inherits"))
		local grandchild = presets_mod.find_configure(p, "grandchild")
		assert.equals(fixture("inherits") .. "/custom-build", grandchild.binaryDir)
	end)

	it("merges cacheVariables: child wins, parents fill in", function()
		local p = presets_mod.load(fixture("inherits"))
		local child = presets_mod.find_configure(p, "child")
		assert.equals("from-base", child.cacheVariables.BASE_VAR)
		assert.equals("from-child", child.cacheVariables.CHILD_VAR)
		assert.equals("child-value", child.cacheVariables.OVERRIDE_ME)

		local grandchild = presets_mod.find_configure(p, "grandchild")
		assert.equals("from-base", grandchild.cacheVariables.BASE_VAR)
		assert.equals("from-child", grandchild.cacheVariables.CHILD_VAR)
		assert.equals("from-grandchild", grandchild.cacheVariables.GRANDCHILD_VAR)
		-- grandchild doesn't override OVERRIDE_ME; inherits child's value
		assert.equals("child-value", grandchild.cacheVariables.OVERRIDE_ME)
	end)

	it("inherits generator from parent", function()
		local p = presets_mod.load(fixture("inherits"))
		local child = presets_mod.find_configure(p, "child")
		assert.equals("Ninja", child.generator)
	end)

	it("doesn't infinite-loop on cyclic inheritance", function()
		-- This test passing at all proves cycle safety; we just need load() to return.
		local p, err = presets_mod.load(fixture("cycle"))
		assert.is_nil(err)
		assert.is_not_nil(p)
		assert.equals(2, #p.configure)
		-- Each preset should still have its own binaryDir
		local a = presets_mod.find_configure(p, "a")
		local b = presets_mod.find_configure(p, "b")
		assert.is_not_nil(a)
		assert.is_not_nil(b)
		assert.is_not_nil(a.binaryDir)
		assert.is_not_nil(b.binaryDir)
	end)

	it("overlays CMakeUserPresets.json on CMakePresets.json", function()
		local p = presets_mod.load(fixture("with-user"))
		assert.equals(2, #p.configure, "expected main + user configure presets")
		assert.equals(2, #p.build)
		assert.is_not_nil(presets_mod.find_configure(p, "main-only"))
		assert.is_not_nil(presets_mod.find_configure(p, "user-only"))
		assert.is_not_nil(presets_mod.find_build(p, "build-main"))
		assert.is_not_nil(presets_mod.find_build(p, "build-user"))
	end)
end)

describe("tasks.cmake.presets.find_configure / find_build", function()
	it("returns nil for unknown name", function()
		local p = presets_mod.load(fixture("basic"))
		assert.is_nil(presets_mod.find_configure(p, "no-such-preset"))
		assert.is_nil(presets_mod.find_build(p, "no-such-build"))
	end)

	it("finds build presets with the right configurePreset linkage", function()
		local p = presets_mod.load(fixture("basic"))
		local b = presets_mod.find_build(p, "build-default")
		assert.equals("default", b.configurePreset)
	end)
end)
