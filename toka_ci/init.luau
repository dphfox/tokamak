--!strict
--Licensed from @dphfox/tokamak under MIT

local stdio = require("@lune/stdio")

local prove = require("prove")
local parseError = require("parseError")
local getLineSource = require("getLineSource")

type TestGroup = {
	name: string,
	tests: {Test}
}
type Test = {
	name: string,
	err: parseError.Error?
}

local testGroups: {TestGroup} = {}

local function sortByName(
	a: {name: string},
	b: {name: string}
)
	return a.name < b.name
end

local TokaCI = {}

function TokaCI.group(
	groupName: string
)
	for _, group in testGroups do
		if group.name == groupName then
			--selene: allow(unused_variable)
			return function(...) end
		end
	end

	local testGroup: TestGroup = {
		name = groupName,
		tests = {}
	}
	table.insert(testGroups, testGroup)
	return function(
		testName: string,
		attemptor: (prove: typeof(prove)) -> ()
	)
		local testInfo: Test = {
			name = testName,
			err = nil
		}
		table.insert(testGroup.tests, testInfo)
		xpcall(attemptor, function(raw)
			testInfo.err = parseError(raw)
		end, prove)
	end
end

function TokaCI.present()
	print(`{stdio.color("yellow")}===== TEST RESULTS ====={stdio.color("reset")}`)
	local pass, fail = 0, 0
	table.sort(testGroups, sortByName)
	print()
	for _, testGroup in testGroups do
		print(testGroup.name)
		for _, test in testGroup.tests do
			local colour = if test.err == nil then stdio.color("green") else stdio.color("red")
			local symbol = if test.err == nil then "✓" else "✕"
			print(`    {colour}{symbol} {test.name}{stdio.color("reset")}`)
			if test.err == nil then
				pass += 1
			else
				fail += 1
				local lineSource = getLineSource(test.err)
				print(`        {test.err.message}`)
				if lineSource ~= nil then
					print(`        {stdio.color("black")}{test.err.lineNum} | {stdio.color("cyan")}{string.gsub(string.gsub(lineSource, "^%s+",""), "%s+$","")}{stdio.color("reset")}`)
				end
				print(`        {stdio.color("blue")}{string.gsub(test.err.trace, "\n\r?","\n        ")}{stdio.color("reset")}`)
			end
		end
		print()
	end
	print(`{stdio.color("green")}{pass} passed, {stdio.color("red")}{fail} failed{stdio.color("reset")}`)
end

return TokaCI