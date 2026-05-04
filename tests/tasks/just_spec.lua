local just = require("tasks.just")

describe("tasks.just.parse_recipes", function()
	it("parses simple recipe list", function()
		local output = "Available recipes:\n    build\n    test\n    clean\n"
		assert.same({ "build", "test", "clean" }, just.parse_recipes(output))
	end)

	it("strips parameters with default values", function()
		local output = [[Available recipes:
    build args=""
    deploy host="localhost"
    test
]]
		assert.same({ "build", "deploy", "test" }, just.parse_recipes(output))
	end)

	it("strips trailing comments", function()
		local output = [[Available recipes:
    build    # build the project
    test     # run tests
]]
		assert.same({ "build", "test" }, just.parse_recipes(output))
	end)

	it("returns empty list for empty output", function()
		assert.same({}, just.parse_recipes(""))
	end)

	it("returns empty list when only the header is present", function()
		assert.same({}, just.parse_recipes("Available recipes:\n"))
	end)

	it("ignores fully-commented indented lines", function()
		local output = [[Available recipes:
    build
    # this is a comment
    test
]]
		-- Comments aren't typical in `just --list` output, but be defensive.
		assert.same({ "build", "test" }, just.parse_recipes(output))
	end)

	it("handles recipes with hyphens and underscores", function()
		local output = "Available recipes:\n    build-all\n    run_tests\n"
		assert.same({ "build-all", "run_tests" }, just.parse_recipes(output))
	end)
end)
