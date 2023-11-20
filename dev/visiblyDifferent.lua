--!strict
--Licensed from @dphfox/tokamak under MIT

local function visiblyDifferent(x: any, y: any): boolean
	local type = typeof(x)
	if typeof(y) ~= type then
		return true
	elseif x ~= x and y ~= y then
		return false
	elseif type == "table" then
		return true
	else
		return x ~= y
	end
end

if not _G.BUNDLE then
	local test = _G.TokaCI.group("visiblyDifferent")
	
	test("equality for primitive types", function(
		prove: (any) -> any
	)
		prove(not visiblyDifferent(1, 1)).holds()
		prove(not visiblyDifferent("hello", "hello")).holds()
		prove(not visiblyDifferent(true, true)).holds()
		prove(not visiblyDifferent(nil, nil)).holds()
		
		prove(visiblyDifferent(1, 10)).holds()
		prove(visiblyDifferent("hello", "world")).holds()
		prove(visiblyDifferent(true, false)).holds()
		prove(visiblyDifferent(nil, 2)).holds()
	end)

	test("always true for table types", function(
		prove: (any) -> any
	)
		prove(visiblyDifferent({}, {})).holds()
		prove(visiblyDifferent({1, 2, 3}, {1, 2, 3})).holds()
		prove(visiblyDifferent({1}, {})).holds()
	end)

	test("never true for NaN", function(
		prove: (any) -> any
	)
		prove(not visiblyDifferent(0/0, 0/0)).holds()
	end)
end

return visiblyDifferent