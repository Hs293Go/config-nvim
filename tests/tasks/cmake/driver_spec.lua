local driver = require("tasks.cmake.driver")

local spec_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local function fixture_dir()
	-- Bind to a local first; otherwise `:gsub`'s second return value (the
	-- substitution count) leaks into callers that splat positional args.
	local p = vim.fn.fnamemodify(spec_dir .. "/../../fixtures/file-api", ":p")
	p = p:gsub("/$", "")
	return p
end

describe("tasks.cmake.driver command builders", function()
	it("configure_cmd produces cmake --preset X with compile_commands export", function()
		local cmd = driver.configure_cmd("my-preset")
		assert.equals("cmake", cmd[1])
		assert.equals("--preset", cmd[2])
		assert.equals("my-preset", cmd[3])
		assert.equals("-DCMAKE_EXPORT_COMPILE_COMMANDS=ON", cmd[4])
	end)

	it("build_cmd produces cmake --build --preset X", function()
		local cmd = driver.build_cmd("build-debug")
		assert.same({ "cmake", "--build", "--preset", "build-debug" }, cmd)
	end)

	it("test_cmd produces ctest --preset X --output-on-failure", function()
		local cmd = driver.test_cmd("test-debug")
		assert.same({ "ctest", "--preset", "test-debug", "--output-on-failure" }, cmd)
	end)
end)

describe("tasks.cmake.driver.write_query_file", function()
	it("creates the codemodel-v2 query file under .cmake/api/v1/query", function()
		local d = vim.fn.tempname()
		vim.fn.mkdir(d, "p")
		driver.write_query_file(d)
		assert.equals(1, vim.fn.isdirectory(d .. "/.cmake/api/v1/query"))
		assert.equals(1, vim.fn.filereadable(d .. "/.cmake/api/v1/query/codemodel-v2"))
	end)

	it("is idempotent — re-running doesn't error", function()
		local d = vim.fn.tempname()
		vim.fn.mkdir(d, "p")
		driver.write_query_file(d)
		driver.write_query_file(d) -- should not raise
		assert.equals(1, vim.fn.filereadable(d .. "/.cmake/api/v1/query/codemodel-v2"))
	end)
end)

describe("tasks.cmake.driver.list_targets", function()
	it("returns nil + err when no reply directory exists", function()
		local d = vim.fn.tempname()
		vim.fn.mkdir(d, "p")
		local targets, err = driver.list_targets(d)
		assert.is_nil(targets)
		assert.is_string(err)
	end)

	it("parses targets across all configurations by default", function()
		local targets, err = driver.list_targets(fixture_dir())
		assert.is_nil(err)
		assert.is_not_nil(targets)
		-- Debug has myapp + mylib; Release has myapp; deduped by name → 2
		assert.equals(2, #targets)
		local names = vim.tbl_map(function(t)
			return t.name
		end, targets)
		table.sort(names)
		assert.same({ "myapp", "mylib" }, names)
	end)

	it("filters to a specific configuration when given", function()
		local targets, err = driver.list_targets(fixture_dir(), "Debug")
		assert.is_nil(err)
		assert.equals(2, #targets)
	end)

	it("returns no targets when configuration filter excludes all", function()
		local targets, err = driver.list_targets(fixture_dir(), "DoesNotExist")
		assert.is_nil(err)
		assert.equals(0, #targets)
	end)

	it("populates target type and artifacts", function()
		local targets = driver.list_targets(fixture_dir(), "Debug")
		local by_name = {}
		for _, t in ipairs(targets) do
			by_name[t.name] = t
		end
		assert.equals("EXECUTABLE", by_name.myapp.type)
		assert.equals("STATIC_LIBRARY", by_name.mylib.type)
		assert.equals("myapp", by_name.myapp.artifacts[1].path)
	end)
end)

describe("tasks.cmake.driver.target_artifact", function()
	it("returns nil + err when target has no artifacts", function()
		local path, err = driver.target_artifact({ name = "noart", type = "UTILITY" }, fixture_dir())
		assert.is_nil(path)
		assert.is_string(err)
	end)

	it("returns absolute path when artifact exists on disk", function()
		local target = { name = "myapp", type = "EXECUTABLE", artifacts = { { path = "myapp" } } }
		local path, err = driver.target_artifact(target, fixture_dir())
		assert.is_nil(err)
		assert.is_string(path)
		assert.equals(fixture_dir() .. "/myapp", path)
	end)

	it("returns nil + err when artifact file is missing", function()
		local target = { name = "ghost", type = "EXECUTABLE", artifacts = { { path = "no-such-binary" } } }
		local path, err = driver.target_artifact(target, fixture_dir())
		assert.is_nil(path)
		assert.is_string(err)
	end)
end)
